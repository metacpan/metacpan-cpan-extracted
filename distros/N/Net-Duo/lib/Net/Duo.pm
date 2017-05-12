# Perl interface for the Duo multifactor authentication service.
#
# This Perl module collection provides a Perl interface to the Duo multifactor
# authentication service (https://www.duosecurity.com/).  It differs from the
# Perl API sample code in that it abstracts some of the API details and throws
# rich exceptions rather than requiring the caller deal with JSON data
# structures directly.
#
# This module is intended primarily for use as a base class for more
# specialized Perl modules implementing the specific Duo APIs, but it can also
# be used directly to make generic API calls.

package Net::Duo 1.01;

use 5.014;
use strict;
use warnings;

use Carp qw(croak);
use Digest::SHA qw(hmac_sha1_hex);
use HTTP::Request;
use JSON ();
use LWP::UserAgent 6.00;
use Net::Duo::Exception;
use Perl6::Slurp;
use POSIX qw(strftime);
use URI::Escape qw(uri_escape_utf8);

# All dies are of constructed objects, which perlcritic misdiagnoses.
## no critic (ErrorHandling::RequireCarping)

##############################################################################
# Constructor
##############################################################################

# Create a new Net::Duo object, which will be used for subsequent calls.
#
# $class - Class of object to create
# $args  - Anonymous hash of arguments with the following keys:
#   api_hostname    - API hostname for the Duo API integration
#   integration_key - Public key for the Duo API integration
#   key_file        - Path to file with integration information
#   secret_key      - Secret key for the Duo API integration
#   user_agent      - User agent object to use instead of LWP::UserAgent
#
# Returns: Newly-created object
#  Throws: Net::Duo::Exception on any failure
sub new {
    my ($class, $args_ref) = @_;
    my $self = {};

    # Load integration information from key_file if set.
    my $keys;
    if ($args_ref->{key_file}) {
        my $json     = JSON->new->relaxed(1);
        my $key_data = slurp($args_ref->{key_file});
        $keys = eval { $json->decode($key_data) };
        if ($@) {
            die Net::Duo::Exception->propagate($@);
        }
    }

    # Integration data from $args_ref overrides key_file data.
    for my $key (qw(api_hostname integration_key secret_key)) {
        $self->{$key} = $args_ref->{$key} // $keys->{$key};
        if (!defined($self->{$key})) {
            my $error = "missing parameter to Net::Duo::new: $key";
            die Net::Duo::Exception->internal($error);
        }
    }

    # Create or set the user agent object.
    $self->{agent} = $args_ref->{user_agent} // LWP::UserAgent->new;

    # Create the JSON decoder that we'll use for subsequent operations.
    $self->{json} = JSON->new->utf8(1);

    # Bless and return the new object.
    bless($self, $class);
    return $self;
}

##############################################################################
# General methods
##############################################################################

# Internal method to canonicalize the arguments.  The Duo API requires that
# all data be URL-encoded and then either used as GET arguments or sent in the
# POST body.
#
# $self     - Net::Duo object
# $args_ref - Reference to hash of arguments (may be undef)
#
# Returns: URL-encoded string representing those arguments
#          undef if there are no arguments
sub _canonicalize_args {
    my ($self, $args_ref) = @_;

    # Return undef if there are no arguments.
    return if !defined($args_ref);

    # Encode the arguments into a list of key and value pairs.
    my @pairs;
    while (my ($key, $value) = each %{$args_ref}) {
        my $encoded_key   = uri_escape_utf8($key);
        my $encoded_value = uri_escape_utf8($value);
        my $pair          = $encoded_key . q{=} . $encoded_value;
        push(@pairs, $pair);
    }

    # Return the arguments joined with &.
    return join(q{&}, sort(@pairs));
}

# Internal method to sign a Duo API call and stores the appropriate
# Authorization header in the HTTP::Request.  For the signature specification,
# see the Duo API documentation.
#
# $self    - Net::Duo object
# $request - HTTP::Request object that will be used for the call
# $path    - URI path for the REST endpoint
# $args    - URI-encoded arguments to the call
#
# Returns: undef
sub _sign_call {
    my ($self, $request, $path, $args) = @_;
    my $date   = $request->header('Date');
    my $method = uc($request->method);
    my $host   = $self->{api_hostname};

    # Generate the request information that should be signed.
    my $data = join("\n", $date, $method, $host, $path, $args // q{});

    # Generate a SHA-1 HMAC as the signature.
    my $signature = hmac_sha1_hex($data, $self->{secret_key});

    # The HTTP Basic Authentication username is the integration key.
    my $username = $self->{integration_key};

    # Set the Authorization header.
    $request->authorization_basic($username, $signature);
    return;
}

# Make a generic Duo API call with no assumptions about its return data type.
# This returns the raw HTTP::Response object without any further processing.
# For most Duo APIs, use call_json instead, which assumes that the call
# returns JSON in a particular structure and checks the status of the HTTP
# response.
#
# $self     - Net::Duo object
# $method   - HTTP method (GET, PUT, POST, or DELETE)
# $path     - URL path to the REST endpoint to call
# $args_ref - Reference to a hash of additional arguments
#
# Returns: The HTTP::Response object from the API call
#  Throws: Net::Duo::Exception on any failure
sub call {
    my ($self, $method, $path, $args_ref) = @_;
    my $host = $self->{api_hostname};
    my $args = $self->_canonicalize_args($args_ref);
    $method = uc($method);

    # Verify that the URL path starts with a slash.
    if ($path !~ m{ \A / }xms) {
        my $error = "REST endpoint '$path' does not begin with /";
        die Net::Duo::Exception->internal($error);
    }

    # Set up the request.
    my $request = HTTP::Request->new;
    $request->method($method);
    $request->protocol('HTTP/1.1');
    $request->date(time());
    $request->header(Host => $host);

    # Use an undocumented feature of LWP::Protocol::https to ensure that the
    # certificate subject is from duosecurity.com.  This header is not passed
    # to the remote host, only used internally by LWP.
    my $subject_regex = qr{ CN=[^=]+ [.] duosecurity [.] com \z }xms;
    $request->header('If-SSL-Cert-Subject' => $subject_regex);

    # Sign the request.
    $self->_sign_call($request, $path, $args);

    # For POST and PUT, send the arguments as form data.  Otherwise, add them
    # to the path as GET parameters.
    if ($method eq 'POST' || $method eq 'PUT') {
        $request->content_type('application/x-www-form-urlencoded');
        $request->content($args);
        $request->uri('https://' . $host . $path);
    } elsif (!defined($args)) {
        $request->uri('https://' . $host . $path);
    } else {
        $request->uri('https://' . $host . $path . q{?} . $args);
    }

    # Make the request and return the response.
    return $self->{agent}->request($request);
}

# Make a generic Duo API call that returns JSON and do the return status
# checking that's common to most of the Duo API calls.  There are a few
# exceptions, like /logo, which do not return JSON and therefore cannot be
# called using this method).
#
# $self     - Net::Duo object
# $method   - HTTP method (GET, PUT, POST, or DELETE)
# $path     - URL path to the REST endpoint to call
# $args_ref - Reference to a hash of additional arguments
#
# Returns: Reference to hash corresponding to the JSON result
#  Throws: Net::Duo::Exception on any failure
sub call_json {
    my ($self, $method, $path, $args_ref) = @_;

    # Use the simpler call() method to do most of the work.  This returns the
    # HTTP::Response object.  Retrieve the content of the response as well.
    my $response = $self->call($method, $path, $args_ref);
    my $content = $response->decoded_content;

    # If the content was empty, we have a failure of some sort.
    if (!defined($content)) {
        if ($response->is_success) {
            die Net::Duo::Exception->protocol('empty response');
        } else {
            die Net::Duo::Exception->http($response);
        }
    }

    # Otherwise, try to decode the JSON.  If we cannot, treat this as an
    # HTTP failure if we didn't get success and a protocol failure
    # otherwise.
    my $data = eval { $self->{json}->decode($content) };
    if ($@) {
        if ($response->is_success) {
            my $error = 'invalid JSON in reply';
            die Net::Duo::Exception->protocol($error, $content);
        } else {
            die Net::Duo::Exception->http($response);
        }
    }

    # Check whether the API call succeeded.  If not, throw an exception.
    if (!defined($data->{stat}) || $data->{stat} ne 'OK') {
        die Net::Duo::Exception->api($data, $content);
    }

    # Return the response portion of the reply.
    if (!defined($data->{response})) {
        my $error = 'no response key in JSON reply';
        die Net::Duo::Exception->protocol($error, $content);
    }
    return $data->{response};
}

1;
__END__

=for stopwords
API LWP libwww perl JSON CPAN auth APIs namespace prepended ARGS hostname
username Auth AUTH sublicense MERCHANTABILITY NONINFRINGEMENT Allbery
multifactor

=head1 NAME

Net::Duo - API for Duo multifactor authentication service

=head1 SYNOPSIS

    my $duo = Net::Duo->new({ key_file => '/path/to/keys.json' });
    my $reply = $duo->call_json('GET', '/auth/v2/check');

=head1 REQUIREMENTS

Perl 5.14 or later and the modules HTTP::Request and HTTP::Response (part
of HTTP::Message), JSON, LWP (also known as libwww-perl), Perl6::Slurp,
and URI::Escape (part of URI), all of which are available from CPAN.

=head1 DESCRIPTION

Net::Duo provides an object-oriented Perl interface for generic calls to
one of the the Duo Security REST APIs.  This module is intended primarily
for use as a base class for more specialized Perl modules implementing the
specific Duo APIs, but it can also be used directly to make generic API
calls.

On failure, all methods throw a Net::Duo::Exception object.  This can be
interpolated into a string for a simple error message, or inspected with
method calls for more details.  This is also true of all methods in all
objects in the Net::Duo namespace.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new Net::Duo object.  This should be used for all subsequent API
calls.  ARGS should be a hash reference with one or more of the following
keys:

=over 4

=item api_hostname

The API hostname returned by Duo when the API integration was created.

This key is required if C<key_file> is not set.

=item integration_key

The integration key returned by Duo when the API integration was created.
This is effectively the public "username" for this integration.

This key is required if C<key_file> is not set.

=item key_file

The path to a file in JSON format that contains the key and hostname data
for a Duo integration.  This file should contain one JSON object with keys
C<integration_key>, C<secret_key>, and C<api_hostname>.  These are the
three data values that are returned when one creates a new Duo API
integration.

Be aware that the C<secret_key> value in this file is security-sensitive
information equivalent to a password.  Anyone in possession of that key
has complete control of all data and actions to which the integration has
access.

Either this key or all of C<integration_key>, C<secret_key>, and
C<api_hostname> must be provided.  If both this key and some of those
keys are provided, their values will override the values retrieved from
the C<key_file> file.

=item secret_key

The secret key returned by Duo when the API integration was created.  This
is security-sensitive information equivalent to a password.  Anyone in
possession of that key has complete control of all data and actions to
which the integration has access.  Do not hard-code this into programs;
instead, read it from a file with appropriate permissions or retrieve it
via some other secure mechanism.

This key is required if C<key_file> is not set.

=item user_agent

The user agent to use for all requests.  This should be a Perl object that
supports the same API as LWP::UserAgent.

Normally, the caller will not provide this key, in which case Net::Duo will
create an LWP::UserAgent object internally to use to make Duo API calls.
This argument is provided primarily so that the user agent can be overridden
for unit testing.

=back

=back

=head1 INSTANCE METHODS

=over 4

=item call(METHOD, PATH[, ARGS])

Make a generic Duo API call, with no assumptions about the response.

This is a low-level escape hatch to make any Duo API call that this module
does not know about, regardless of what format in which it returns its
results.  The caller will have to provide all of the details (HTTP method,
URL path, and all arguments as a reference to a hash of key/value pairs).
The URL path must start with a slash.

The return value is the resulting HTTP::Response object from the web API
call.  No error checking will be performed.  The caller is responsible for
examining the HTTP::Response object for any problems, including internal
or HTTP errors.

Most Duo API calls return structured JSON and follow a standard pattern
for indicating errors.  For those calls, use call_json() instead of this
method.  call() is needed only for the small handful of API calls that do
not return JSON in that format, such as the Auth API C</logo> endpoint.

=item call_json(METHOD, PATH[, ARGS])

Make a generic Duo API call that returns a JSON response.

This is the escape hatch to use to make any Duo API call that this module
does not know about.  The caller will have to provide all of the details
(HTTP method, URL path, and all arguments as a reference to a hash of
key/value pairs).  The URL path must start with a slash.

The return value will be only the value of the response key from the
returned JSON.  This method still handles checking the C<stat> value from
Duo and throwing a Net::Duo::Exception object on call failure.

This method cannot be used with the small handful of API calls that do not
return JSON, such as the Auth API C</logo> endpoint.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 The Board of Trustees of the Leland Stanford Junior
University

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

L<Duo Auth API|https://www.duosecurity.com/docs/authapi>

L<Duo Verify API|https://www.duosecurity.com/docs/duoverify>

L<Duo Admin API|https://www.duosecurity.com/docs/adminapi>

This module is part of the Net::Duo distribution.  The current version of
Net::Duo is available from CPAN, or directly from its web site at
L<http://www.eyrie.org/~eagle/software/net-duo/>.

=cut
