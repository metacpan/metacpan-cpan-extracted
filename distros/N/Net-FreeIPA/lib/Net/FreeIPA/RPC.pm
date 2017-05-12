package Net::FreeIPA::RPC;
$Net::FreeIPA::RPC::VERSION = '3.0.2';
use strict;
use warnings;

use Readonly;

use REST::Client;
use JSON::XS;

use Net::FreeIPA::Error;
use Net::FreeIPA::API::Magic;
use Net::FreeIPA::Request;
use Net::FreeIPA::Response;

use LWP::UserAgent;
# Add kerberos support
use LWP::Authen::Negotiate;

Readonly my $IPA_CA_CERT => '/etc/ipa/ca.crt';
Readonly my $IPA_URL_LOGIN_PASSWORD => '/ipa/session/login_password';
Readonly my $IPA_URL_LOGIN_KERBEROS => '/ipa/session/login_kerberos';
Readonly my $IPA_URL_JSON => '/ipa/session/json';
Readonly my $IPA_URL_REFERER => '/ipa';

=head1 NAME

Net::FreeIPA::RPC provides RPC handling for Net::FreeIPA

=head2 Public methods

=over

=item new_rpc

Create a new L<REST::Client> instance, will be used throughout the remainder of the
instance.

An authentication cookie will be retrieved (and will be used for the actual
FreeIPA API calls).

Returns undef on failure, 1 on success.

=over

=item Arguments

=over

=item host: host to connect to

=back

=item Options

=over

=item username: the username to use for username/password based login

=item password: the password to use for username/password login

=item krbcc: kerberos credentials cache to use (set via KRB5CCNAME)

=back

=back

=cut

sub new_client
{
    my ($self, $host, %opts) = @_;

    # Make a LWP::UserAgent with a cookiejar,
    # connect once and reuse cookiejar for remainder

    my $url = "https://$host";

    my $browser = LWP::UserAgent->new();
    # Temporary cookie_jar
    $browser->cookie_jar( {} );

    my $rc = REST::Client->new(
        host => $url,
        ca => $IPA_CA_CERT,
        useragent => $browser,
        );

    my ($login_url, $body);
    my $headers = {
        'referer' => "$url$IPA_URL_REFERER",
    };
    if ($opts{username}) {
        $self->debug("Login using username/password");
        $login_url = $IPA_URL_LOGIN_PASSWORD;

        my $query = $rc->buildQuery(user => $opts{username}, password => $opts{password});
        # buildQuery is for the GET method, so you have to remove the '?'
        $body = substr($query, 1);

        $headers->{"Content-Type"} = "application/x-www-form-urlencoded";
        $headers->{"Accept"} = "text/plain";
    } else {
        local $ENV{KRB5CCNAME} = $opts{krbcc} if $opts{krbcc};
        # follow auth plugins, for LWP::Auth::Negotiate magic
        $rc->setFollow(1);
        $self->debug("Login using kerberos");
        $login_url = $IPA_URL_LOGIN_KERBEROS;
    }

    $rc->POST($login_url, $body, $headers);
    my $code = $rc->responseCode();
    my $content = $rc->responseContent();

    if ($code == 200) {
        $self->debug("Successful login");

        # prep JSON REST API
        $rc->addHeader("Content-Type", "application/json");
        $rc->addHeader("Accept", "applicaton/json");
        $rc->addHeader('referer', "$url$IPA_URL_REFERER");

        $self->{rc} = $rc;
        $self->{id} = 0;
        $self->{json} = JSON::XS->new();
        $self->{json}->canonical(1); # sort the keys, to create reproducable results
        $self->set_api_version('API');

        # Reset error atrribute (will be adapted by rpc method)
        $self->{error} = mkerror();
        return 1;
    } else {
        $content = '<undef>' if ! defined($content);
        # Do no print possible password
        $self->error("Login failed (url $url$login_url code $code): $content");
        # Set error attribute
        $self->{error} = mkerror("Login failed (url $url$login_url code $code)");
        return;
    }
}

=item set_apiversion

Set the API version for this session.

If no version string is passed, the C<api_version> attribute
is set to undef (effecitively removing it), and this is typically
interpreted by the server as using the latest version.

If the string C<API> is passed as version,
it will use verison from C<Net::FreeIPA::API>.

If the version is a C<version> instance, the used version is
stringified and any leading 'v' is removed.

Returns the version that was set version on success, undef otherwise.
(If you want to get the current version, use the C<api_version> attribute.
This method will always set a version.)

=cut

sub set_api_version
{
    my ($self, $version) = @_;

    if (defined($version)) {
        if ( (! ref($version)) && ($version eq 'API')) {
            $version = Net::FreeIPA::API::Magic::version();
            $self->debug("set_api_version using API version $version");
        };

        if (ref($version) eq 'version') {
            $version = $version->stringify();
            $version =~ s/^v//;
        }
    };

    $self->{api_version} = $version;
    $self->debug("set api_version to ".(defined($version) ? $version : '<undef>'));
    return $version;
}

=item post

Make a JSON API post using C<request>.

Return Response instance, undef on failure to get the REST client via the C<rc> attribute.

=cut

sub post
{
    my ($self, $request, %opts) = @_;

    # set request post options, do not override
    foreach my $postopt (sort keys %{$request->{post}}) {
        $opts{$postopt} = $request->{post}->{$postopt} if ! defined($opts{$postopt});
    }

    # For now, only support the API version from Net::FreeIPA::API
    if ($self->{api_version}) {
        $request->{opts}->{version} = $self->{api_version};
    }

    $request->{id} = $self->{id} if ! defined($request->{id});

    # For convenience
    my $rc = $self->{rc};
    return if (! defined($rc));

    my $json_req = $self->{json}->encode($request->post_data());
    $self->debug("JSON POST $json_req") if $self->{debugapi};
    $rc->POST($IPA_URL_JSON, $json_req);

    my $code = $rc->responseCode();
    my $content = $rc->responseContent();
    my ($ans, $err);

    if ($code == 200) {
        $ans = $self->{json}->decode($content);
        $self->debug("Successful JSON POST".($self->{debugapi} ? " JSON $content" : ""));
    } else {
        $ans = $content;

        $content = '<undef>' if ! defined($content);
        $self->error("POST failed (url $IPA_URL_JSON code $code): $content");
        # Set error (not processed anymore by rpc)
        $err = "POST failed (url $IPA_URL_JSON code $code)";
    }

    return mkresponse(answer => $ans, error => $err);
}


=item rpc

Make a JSON API rpc call.
Returns response on successful POST (and no error attribute is set,
even if the answer contains an error), undef otherwise
(and the error attribute is set).

Arguments

=over

=item request: request instance (request rpc options are added to the options, without overriding)

=back

Options

=over

=item result_path: passed to the response

=item noerror

An array ref with errorcodes or errornames that are not reported as an error.
(Still return C<undef>).

=back

Response is stored in the response attribute (and is reset).

=cut

sub rpc
{
    my ($self, $request, %opts) = @_;

    # Reset any previous result and error
    $self->{response} = undef;
    $self->{error} = undef;

    my ($ret, $response, $errmsg);

    my $ref = ref($request);
    if ($ref eq 'Net::FreeIPA::Request') {
        if ($request) {
            # set request rpc options, do not override
            foreach my $rpcopt (sort keys %{$request->{rpc}}) {
                $opts{$rpcopt} = $request->{rpc}->{$rpcopt} if ! defined($opts{$rpcopt});
            }

            $response = $self->post($request);
        } else {
            $errmsg = "error in request $request->{error}";
        }
    } else {
        $errmsg = "Not supported rpc argument type $ref";
    }

    if ($response) {
        # At this point, POST was succesful, and we interpret the response
        my $command = $request->{command};

        # Redefine the response error according to answer
        my $error = $response->set_error($response->{answer}->{error});
        # (re)set the result, also in case of error-in-answer,
        # it will reset the result attribute
        $response->set_result($opts{result_path});

        if ($error) {
            my @noerrors = grep {defined($_) && $error == $_} @{$opts{noerror} || []};

            my $error_method = @noerrors ? 'debug' : 'error';

            $self->$error_method("$command got error ($error)");
        } else {
            $self->warn("$command got truncated result") if $self->{response}->{answer}->{result}->{truncated};
        };

        # Set and return response attribute
        $self->{response} = $response;
        return $response;
    } else {
        if ($errmsg) {
            $self->error($errmsg);
            $self->{error} = mkerror($errmsg);
        } else {
            $self->{error} = $response->{error};
        };
        return;
    };
}


# Possible code for batch
#   requests can come from API::Function
#     API::Function is not unittested
sub batch
{
    my ($self, @requests) = @_;

    # Make a large batch request
    #   increase the id of each request, update the $self->id
    #     use request->post_data, make arrayref?
    # rpc the batchrequest
    # split the rpc batchresponse answer
    #   make a response instance for each request
    #   pass each sub-response through rpc for postprocessing
    #     extract the rpc options from each request
    #     requires change to rpc to handle responses or factor out the response post processing code
    # return list of responses
}

=item get_api_commands

Retrieve the API commands metadata.

The result attribute holds the commands hashref.

Returns commands hasref on success, undef on failure.

=cut

sub get_api_commands
{
    my ($self) = @_;

    # Cannot use the API::Function here, this is to be used to generate them
    my $req = mkrequest('json_metadata', args => [], opts => {command => "all"});
    my $resp = $self->rpc($req, result_path => 'result/commands');
    return $resp ? $resp->{result} : undef;
}


=item get_api_version

Retrieve the API version from the server.

The result attribute holds the version.

(To retrieve the latest version remove
the C<api_version> attribute first).

Does not set the version.

Returns the C<api_version> on success, undef on failure.

=cut

sub get_api_version
{
    my ($self) = @_;

    # Cannot use the API::Function here, this is to be used to generate them
    my $req = mkrequest('env', args => ['api_version'], opts => {});
    my $resp = $self->rpc($req, result_path => 'result/result/api_version');
    return  $resp ? $resp->{result} : undef;
}

=pod

=back

=cut

1;
