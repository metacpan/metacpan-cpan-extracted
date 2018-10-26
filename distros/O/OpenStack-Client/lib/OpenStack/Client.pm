#
# Copyright (c) 2018 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package OpenStack::Client;

use strict;
use warnings;

use HTTP::Request  ();
use LWP::UserAgent ();

use JSON        ();
use URI::Encode ();

use OpenStack::Client::Response ();

our $VERSION = '1.0005';

=encoding utf8

=head1 NAME

OpenStack::Client - A cute little client to OpenStack services

=head1 SYNOPSIS

    #
    # First, connect to an API endpoint via the Keystone
    # authorization service
    #
    use OpenStack::Client::Auth ();

    my $endpoint = 'http://openstack.foo.bar:5000/v2.0';

    my $auth = OpenStack::Client::Auth->new($endpoint,
        'tenant'   => $ENV{'OS_TENANT_NAME'},
        'username' => $ENV{'OS_USERNAME'},
        'password' => $ENV{'OS_PASSWORD'}
    );

    my $glance = $auth->service('image',
        'region' => $ENV{'OS_REGION_NAME'}
    );

    my @images = $glance->all('/v2/images', 'images');

    #
    # Or, connect directly to an API endpoint by URI
    #
    use OpenStack::Client ();

    my $endpoint = 'http://glance.foo.bar:9292';

    my $glance = OpenStack::Client->new($endpoint,
        'token' => {
            'id' => 'foo'
        }
    );

    my @images = $glance->all('/v2/images', 'images');

=head1 DESCRIPTION

C<OpenStack::Client> is a no-frills OpenStack API client which provides generic
access to OpenStack APIs with minimal remote service discovery facilities; with
a minimal client, the key understanding of the remote services are primarily
predicated on an understanding of the authoritative OpenStack API documentation:

    http://developer.openstack.org/api-ref.html

Authorization, authentication, and access to OpenStack services such as the
OpenStack Compute and Networking APIs is made convenient by
L<OpenStack::Client::Auth>.  Further, some small handling of response body data
such as obtaining the full resultset of a paginated response is handled for
convenience.

Ordinarily, a client can be obtained conveniently by using the C<services()>
method on a L<OpenStack::Client::Auth> object.

=head1 INSTANTIATION

=over

=item C<OpenStack::Client-E<gt>new(I<$endpoint>, I<%opts>)>

Create a new C<OpenStack::Client> object connected to the specified
I<$endpoint>.  The following values may be specified in I<%opts>:

=over

=item * B<token>

A token obtained from a L<OpenStack::Client::Auth> object.

=back

=cut

sub new ($%) {
    my ($class, $endpoint, %opts) = @_;

    die 'No API endpoint provided' unless $endpoint;

    $opts{'package_ua'}       ||= 'LWP::UserAgent';
    $opts{'package_request'}  ||= 'HTTP::Request';
    $opts{'package_response'} ||= 'OpenStack::Client::Response';

    my $ua = $opts{'package_ua'}->new(
        'ssl_opts' => {
            'verify_hostname' => 0
        }
    );

    return bless {
        'package_ua'       => $opts{'package_ua'},
        'package_request'  => $opts{'package_request'},
        'package_response' => $opts{'package_response'},
        'ua'               => $ua,
        'endpoint'         => $endpoint,
        'token'            => $opts{'token'}
    }, $class;
}

=back

=head1 INSTANCE METHODS

These methods are useful for identifying key attributes of an OpenStack service
endpoint client.

=over

=item C<$client-E<gt>endpoint()>

Return the absolute HTTP URI to the endpoint this client provides access to.

=cut

sub endpoint ($) {
    shift->{'endpoint'};
}

=item C<$client-E<gt>token()>

If a token object was specified when creating C<$client>, then return it.

=cut

sub token ($) {
    shift->{'token'};
}

sub uri ($$) {
    my ($self, $path) = @_;

    return join '/', map {
        my $part = $_;

        $part =~ s/^\///;
        $part =~ s/\/$//;
        $part
    } $self->{'endpoint'}, $path;
}

=back

=head1 PERFORMING REMOTE CALLS

=over

=cut

sub request {
    my ($self, %args) = @_;

    $args{'headers'} ||= {};

    my $request = $self->{'package_request'}->new(
        $args{'method'} => $self->uri($args{'path'})
    );

    my @headers = $self->_get_headers_list($args{'headers'});

    my $count = scalar @headers;

    for (my $i=0; $i<$count; $i+=2) {
        my $name  = $headers[$i];
        my $value = $headers[$i+1];

        $request->header($name => $value);
    }

    if (defined $args{'body'}) {
        #
        # Allow the request body to be supplied by a subroutine reference
        # which, when called, will supply a chunk of data returned as per the
        # behavior of LWP::UserAgent.  This is useful for uploading arbitrary
        # amounts of data in a request body.
        #
        if (ref($args{'body'}) =~ /CODE/) {
            $request->content($args{'body'});
        } else {
            $request->content(JSON::encode_json($args{'body'}));
        }
    }

    return bless $self->{'ua'}->request($request,
        defined $args{'handler'}? $args{'handler'}: ()),
        $self->{'package_response'};
}

=item C<$client-E<gt>call(I<$args>)>

Perform a call to the service endpoint using named arguments in the hash.  The
following arguments are required:

=over

=item C<method> - Request method

=item C<path> - Resource path

=back

The following arguments are optional:

=over

=item C<headers> - Request headers

Headers are case I<insensitive>; if duplicate header values are declared under
different cases, it is undefined which headers shall take precedence.  The
following headers are sent by default:

=over

=item Accept

Defaults to C<application/json, text/plain>.

=item Accept-Encoding

Defaults to C<identity, gzip, deflate, compress>.

=item Content-Type

Defaults to C<application/json>, although some API calls (e.g., a PATCH)
expect a different type; the case of an image update, the expected
type is C<application/openstack-images-v2.1-json-patch> or some version
thereof.

=back

Except for C<X-Auth-Token>, any additional token will be added to the request.

=item C<body> - Request body

This may be a scalar reference to a data structure to be encoded to JSON, or a
CODE reference to a subroutine which, when called, will return a chunk of data
to be supplied to the API endpoint; the stream is ended when the supplied
subroutine returns an empty string or undef.

=item C<handler> - Response body handler function

When specified, this function will be called with two arguments; the first
argument is a scalar value containing a chunk of data in the response body, and
the second is a scalar reference to a L<HTTP::Response> object representing the
current response.  This is useful for retrieving very large resources without
having to store the entire response body in memory at once for parsing.

=back

All forms of this method may return the following:

=over

=item * For B<application/json>: A decoded JSON object

=item * For other response types: The unmodified response body

=back

In exceptional conditions (such as when the service returns a 4xx or 5xx HTTP
response), the client will die with the raw text response from the HTTP
service, indicating the nature of the service-side failure to service the
current call.

=item C<$client-E<gt>call(I<$method>, I<$path>, I<$body>)>

Perform a call to the service endpoint using the HTTP method I<$method>,
accessing the resource I<$path> (relative to the absolute endpoint URI),
passing an arbitrary value in I<$body>.

=item C<$client-E<gt>call(I<$method>, I<$headers>, I<$path>, I<$body>)>

Perform a call to the service endpoint using the HTTP method I<$method>,
accessing the resource I<$path> (relative to the absolute endpoint URI),
specifying the headers in I<$headers>, passing an arbitrary value in I<$body>.

=back

=head1 EXAMPLES

The following shows how one may update image metadata using the PATCH method
supported by version 2 of the Image API.  C<@image_updates> is an array of hash
references of the structure defined by the PATCH RFC (6902) governing
"JavaScript Object Notation (JSON) Patch"; i.e., operations consisting of
C<add>, C<replace>, or C<delete>.

    my $headers = {
        'Content-Type' => 'application/openstack-images-v2.1-json-patch'
    };

    my $response = $glance->call({
        'method'  => 'PATCH',
        'headers' => $headers,
        'path'    => qq[/v2/images/$image->{id}],
        'body'    => \@image_updates
    );

=cut

sub call {
    my $self = shift;

    if (scalar @_ == 4) {
        return $self->call({
            'method'  => $_[0],
            'headers' => $_[1],
            'path'    => $_[2],
            'body'    => $_[3]
        });
    } elsif (scalar @_ == 3) {
        return $self->call({
            'method'  => $_[0],
            'headers' => {},
            'path'    => $_[1],
            'body'    => $_[2],
        });
    } elsif (scalar @_ == 2) {
        return $self->call({
            'method'  => $_[0],
            'headers' => {},
            'path'    => $_[1],
            'body'    => undef
        });
    } elsif (scalar @_ != 1) {
        die "Invalid number of arguments: @_";
    }

    my ($args) = @_;

    return $self->request(%{$args})->decode_json;
}

sub _lc_merge {
    my ($a, $b, %opts) = @_;

    my %lc_keys_a = map {
        lc $_ => $_
    } keys %{$a};

    foreach my $key_b (keys %{$b}) {
        my $key_a = $lc_keys_a{lc $key_b};

        if (!defined($key_a)) {
            $a->{$key_b} = $b->{$key_b};
        } elsif (exists $a->{$key_a} && $opts{'replace'}) {
            $a->{$key_a} = $b->{$key_b};
        }
    }

    return;
}

#
# Internal method for call() to process headers; returns a list of header name
# and value pairs
#
sub _get_headers_list {
    my ($self, $headers) = @_;

    my %DEFAULTS = (
        'Accept'          => 'application/json, text/plain',
        'Accept-Encoding' => 'identity, gzip, deflate, compress',
        'Content-Type'    => 'application/json'
    );

    #
    # The client should be not adding X-Auth-Token explicitly, so force it to
    # the one received during authentication
    #
    my %OVERRIDES = (
        'X-Auth-Token' => $self->token
    );

    my %new_headers = %{$headers};

    _lc_merge(\%new_headers, \%DEFAULTS);
    _lc_merge(\%new_headers, \%OVERRIDES, 'replace' => 1);

    return %new_headers;
}

=head1 FETCHING REMOTE RESOURCES

=over

=item C<$client-E<gt>get(I<$path>, I<%opts>)>

Issue an HTTP GET request for resource I<$path>.  The keys and values
specified in I<%opts> will be URL encoded and appended to I<$path> when forming
the request.  Response bodies are decoded as per C<$client-E<gt>call()>.

=cut

sub get ($$%) {
    my ($self, $path, %opts) = @_;

    my $params;

    foreach my $name (sort keys %opts) {
        my $value = $opts{$name};

        $params .= "&" if defined $params;

        $params .= sprintf "%s=%s", map {
            URI::Encode::uri_encode($_)
        } $name, $value;
    }

    if (defined $params) {
        #
        # $path might already have request parameters; if so, just append
        # subsequent values with a & rather than ?.
        #
        if ($path =~ /\?/) {
            $path .= "&$params";
        } else {
            $path .= "?$params";
        }
    }

    return $self->call('GET' => $path);
}

=item C<$client-E<gt>each(I<$path>, I<$opts>, I<$callback>)>

=item C<$client-E<gt>each(I<$path>, I<$callback>)>

Issue an HTTP GET request for the resource I<$path>, while passing each
decoded response object to I<$callback> in a single argument.  I<$opts> is taken
to be a HASH reference containing zero or more key-value pairs to be URL encoded
as parameters to each GET request made.

=cut

sub each ($$@) {
    my ($self, $path, @args) = @_;

    my $opts = {};
    my $callback;

    if (scalar @args == 2) {
        ($opts, $callback) = @args;
    } elsif (scalar @args == 1) {
        ($callback) = @args;
    } else {
        die 'Invalid number of arguments';
    }

    while (defined $path) {
        my $result = $self->get($path, %{$opts});

        $callback->($result);

        $path = $result->{'next'};
    }

    return;
}

=item C<$client-E<gt>every(I<$path>, I<$attribute>, I<$opts>, I<$callback>)>

=item C<$client-E<gt>every(I<$path>, I<$attribute>, I<$callback>)>

Perform a series of HTTP GET request for the resource I<$path>, decoding the
result set and passing each value within each physical JSON response object's
attribute named I<$attribute>, to the callback I<$callback> as a single
argument.  I<$opts> is taken to be a HASH reference containing zero or more
key-value pairs to be URL encoded as parameters to each GET request made.

=cut

sub every ($$$@) {
    my ($self, $path, $attribute, @args) = @_;

    my $opts = {};
    my $callback;

    if (scalar @args == 2) {
        ($opts, $callback) = @args;
    } elsif (scalar @args == 1) {
        ($callback) = @args;
    } else {
        die 'Invalid number of arguments';
    }

    while (defined $path) {
        my $result = $self->get($path, %{$opts});

        unless (defined $result->{$attribute}) {
            die "Response from $path does not contain attribute '$attribute'";
        }

        foreach my $item (@{$result->{$attribute}}) {
            $callback->($item);
        }

        $path = $result->{'next'};
    }

    return;
}

=item C<$client-E<gt>all(I<$path>, I<$attribute>, I<$opts>)>

=item C<$client-E<gt>all(I<$path>, I<$attribute>)>

Perform a series of HTTP GET requests for the resource I<$path>, decoding the
result set and returning a list of all items found within each response body's
attribute named I<$attribute>.  I<$opts> is taken to be a HASH reference
containing zero or more key-value pairs to be URL encoded as parameters to each
GET request made.

=cut

sub all ($$$@) {
    my ($self, $path, $attribute, $opts) = @_;

    my @items;

    $self->every($path, $attribute, $opts, sub {
        my ($item) = @_;

        push @items, $item;
    });

    return @items;
}

=back

=head1 CREATING AND UPDATING REMOTE RESOURCES

=over

=item C<$client-E<gt>put(I<$path>, I<$body>)>

Issue an HTTP PUT request to the resource at I<$path>, in the form of a JSON
encoding of the contents of I<$body>.

=cut

sub put ($$$) {
    my ($self, $path, $body) = @_;

    return $self->call('PUT' => $path, $body);
}

=item C<$client-E<gt>post(I<$path>, I<$body>)>

Issue an HTTP POST request to the resource at I<$path>, in the form of a
JSON encoding of the contents of I<$body>.

=cut

sub post ($$$) {
    my ($self, $path, $body) = @_;

    return $self->call('POST' => $path, $body);
}

=back

=head1 DELETING REMOTE RESOURCES

=over

=item C<$client-E<gt>delete(I<$path>)>

Issue an HTTP DELETE request of the resource at I<$path>.

=cut

sub delete ($$) {
    my ($self, $path) = @_;

    return $self->call('DELETE' => $path);
}

=back

=head1 SEE ALSO

=over

=item L<OpenStack::Client::Auth>

The OpenStack Keystone authentication and authorization interface

=back

=head1 AUTHOR

Written by Alexandra Hrefna Hilmisdóttir <xan@cpanel.net>

=head1 CONTRIBUTORS

=over

=item Brett Estrade <brett@cpanel.net>

=back

=head1 COPYRIGHT

Copyright (c) 2018 cPanel, L.L.C.  Released under the terms of the MIT license.
See LICENSE for further details.

=cut

1;
