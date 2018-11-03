package Net::OpenStack::Client::REST;
$Net::OpenStack::Client::REST::VERSION = '0.1.4';
use strict;
use warnings;

use Net::OpenStack::Client::Request qw(@METHODS_REQUIRE_OPTIONS $HDR_X_AUTH_TOKEN);
use Net::OpenStack::Client::Response;
use REST::Client;
use LWP::UserAgent;
use JSON::XS;

use Readonly;

# Map with HTTP return codes indicating success
#   if method is missing (only) 200 is conisdered success
#   if method is present, 200 is not considered success by default
Readonly my %SUCCESS => {
    POST => [201],
    PUT => [200, 201, 204],
    DELETE => [204, 201], # yes, 201 when deleting a token
    };


# JSON::XS instance
# sort the keys, to create reproducable results
my $json = JSON::XS->new()->canonical(1);

=head1 methods

=over

=cut

sub _new_client
{
    my ($self) = @_;

    my $browser = LWP::UserAgent->new();
    # Temporary cookie_jar
    $browser->cookie_jar( {} );

    my $rc = REST::Client->new(
        useragent => $browser,
        );

    $self->{rc} = $rc;
}

# Actual REST::Client call
# Returns tuple repsonse, repsonse headers and error message.
# Processes the repsonse code, including possible JSON decoding
# Reports error and returns err (with repsonse undef)
sub _call
{
    my ($self, $method, $url, @args) = @_;

    my $err;
    my $rc = $self->{rc};

    # make the call
    $rc->$method($url, @args);

    my $code = $rc->responseCode();
    my $content = $rc->responseContent();
    my $rheaders = {map {$_ => $rc->responseHeader($_)} $rc->responseHeaders};
    my $success = grep {$code == $_} @{$SUCCESS{$method} || [200]};

    my $response;
    my $type = $rheaders->{'Content-Type'} || 'RESPONSE_WO_CONTENT_TYPE_HEADER';
    if ($type =~ qr{^application/json}i) {
        local $@;
        eval {
            $response = $json->decode($content);
        };
        if ($@) {
            my $report = $success ? 'error' : 'verbose';
            $self->$report("REST $method with ".($success ? 'success' : 'error').
                           " failure to decode JSON content $content: $@");
        }
    } else {
        $response = $content;
    }

    if ($success) {
        $self->verbose("Successful REST $method url $url type $type");
        if ($self->{debugapi}) {
            # might contain sensitive data, eg security token
            my $headers_txt = join(',', map {"$_=$rheaders->{$_}"} sort keys %$rheaders);
            $self->debug("REST $method full response headers $headers_txt");
            $self->debug("REST $method full response content $content");
        }
    } else {
        my $errmsg = "$method failed (url $url code $code)";
        if (ref($response) eq 'HASH' &&
            $response->{error}) {
            $err = $response->{error};
            $err->{url} = $url;
            $err->{method} = $method;
            $err->{code} = $code if !exists($err->{code});
        } else {
            $err = $errmsg;
        }

        $content = '<undef>' if ! defined($content);
        $errmsg = "$errmsg: $content";
        $self->error("REST $errmsg");
    }

    return $response, $rheaders, $err;
}

 # Handle pagination: https://developer.openstack.org/api-guide/compute/paginated_collections.html
# For any decoded reply, walk the tree
#    look for <key>+<key>_links combos
#    <key> should be a list (a collection)
#    the <key>_links part should have a rel=next, href=newurl
#       follow it, and merge the results with the original key list
#    lets assume they are in the same relative path
# Aaaargh who came up with this crap

# Return array of paths that have to processed for paging
# Each element is a tuple of path (as arrayref of subpaths)
# and url to follow
# Assumes that all responses can be retrieved from
# and be joined using the same path in JSON
# Only pass hashref as data.
# TODO: support lookup of links in arrays?
sub _page_paths
{
    my ($self, $data) = @_;

    my @paths;

    foreach my $key (sort keys %$data) {
        my $lkey = $key."_links";
        my $ref = ref($data->{$key});
        if (exists($data->{$lkey}) &&
            $ref eq 'ARRAY' &&
            ref($data->{$lkey}) eq 'ARRAY'
            ) {
            foreach my $link (@{$data->{$lkey}}) {
                if (exists($link->{rel}) &&
                    $link->{rel} eq 'next' &&
                    exists($link->{href})) {
                    # only first one
                    push(@paths, [[$key], $link->{href}]);
                    last;
                }
            }
        } elsif ($ref eq 'HASH') {
            foreach my $rpath_tuple ($self->_page_paths($data->{$key})) {
                # add current key to path element (i.e. the path is relative to $key)
                unshift(@{$rpath_tuple->[0]}, $key);
                push(@paths, $rpath_tuple);
            }
        }
    }

    return @paths;
}

# only hashrefs
sub _page
{
    my ($self, $method, $response, $headers) = @_;

    my $err;

    foreach my $path_tuple ($self->_page_paths($response)) {
        # No body, this is GET only
        # We only care about the response headers of the first batch
        $self->debug("_page method $method url $path_tuple->[1]");
        my ($tresponse, $trheaders, $terr) = $self->_call($method, $path_tuple->[1], $headers);
        if ($terr) {
            # no temp err here, a failure in the paged GET repsonse is a failure nonetheless
            $err = $terr;
            last;
        } else {
            my @path = @{$path_tuple->[0]};
            # extend path of tresponse in path of response
            my $rarray = $response;
            foreach my $p (@path) {
                $rarray = $rarray->{$p};
                $tresponse = $tresponse->{$p};
            }
            push(@$rarray, @$tresponse);
        };
    }

    return $response, $err;
}

=item rest

Given a Request instance C<req>, perform this request.
All options are passed to the headers method.
The token option is added if the token attribute exists and
if not token option was already in the options.

=cut

sub rest
{
    my ($self, $req, %opts) = @_;

    # methods that require options, must pass said option as body
    # general call is $rc->$method($url, [body if options], $headers)

    my $method = $req->{method};
    my $rservice = $req->{service};
    my $service;
    if ($rservice) {
        $service = $self->{services}->{$rservice};
        if (!$service) {
            $self->debug("REST $method request endpoint $req->{endpoint} service $rservice has no known service");
        }
    } else {
        $self->debug("REST $method request endpoint $req->{endpoint} has no service");
    }

    # url
    my $url = $req->endpoint($service);
    if (!$url) {
        my $msg = "REST $method request endpoint $req->{endpoint} ".
            ($service ? "service $service" : "no service")." has no endpoint url";
        $self->error($msg);
        return mkresponse(error => $msg);
    }

    my @args = ($url);

    # body if needed
    my $body;
    if (grep {$method eq $_} @METHODS_REQUIRE_OPTIONS) {
        my $data = $req->opts_data;
        $body = $json->encode($data);
        push(@args, $body);
    }

    # headers
    $opts{token} = $self->{token} if (exists($self->{token}) && !exists $opts{token});
    my $headers = $req->headers(%opts);
    push(@args, $headers);

    $self->debug("REST $method url $url, ".(defined $body ? '' : 'no ')."body, headers ".join(',', sort keys %$headers));
    if ($self->{debugapi}) {
        # might contain sensitive data, eg security token
        my $headers_txt = join(',', map {"$_=$headers->{$_}"} sort keys %$headers);
        $self->debug("REST $method full headers $headers_txt");
        $self->debug("REST $method full body $body") if $body;
    }

    my ($response, $rheaders, $err) = $self->_call($method, @args);
    # The err here could be a failure in the paged GET repsonse
    ($response, $err) = $self->_page($method, $response, $headers) if (!$err && $response && ref($response) eq 'HASH');

    my %ropts = (
        data => $response,
        headers => $rheaders,
        error => $err,
    );
    $ropts{result_path} = $req->{result} if defined $req->{result};
    return mkresponse(%ropts);
}

=pod

=back

=cut

1;
