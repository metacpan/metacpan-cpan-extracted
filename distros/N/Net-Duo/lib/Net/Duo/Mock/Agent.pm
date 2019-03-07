# Mock LWP::UserAgent for Net::Duo testing.
#
# This module provides the same interface as LWP::UserAgent, for the methods
# that Net::Duo calls, and verifies that the information passed in by Duo is
# correct.  It can also simulate responses to exercise response handling in
# Net::Duo.
#
# All tests are reported by Test::More, and no effort is made to produce a
# predictable number of test results.  This means that any calling test
# program should probably not specify a plan and instead use done_testing().
#
# SPDX-License-Identifier: MIT

package Net::Duo::Mock::Agent 1.02;

use 5.014;
use strict;
use warnings;

use Carp qw(croak);
use Digest::SHA qw(hmac_sha1_hex);
use Encode qw(decode);
use HTTP::Request;
use HTTP::Response;
use JSON ();
use Perl6::Slurp;
use Test::More;
use URI::Escape qw(uri_unescape);

##############################################################################
# Mock API
##############################################################################

# Verify the signature on the request.
#
# The signature uses the Basic Authentication Scheme and should use the
# integration key as the username and the hash of the call as the password.
# This function duplicates the signature and ensures it's correct.  All test
# results are reported via Test::More functions.
#
# $self    - Net::Duo::Mock::Agent object
# $request - HTTP::Request object to verify
#
# Returns: undef
sub _verify_signature {
    my ($self, $request) = @_;
    my $date   = $request->header('Date');
    my $method = uc($request->method);
    my $host   = $self->{api_hostname};

    # Get the partial URI.  We have to strip the scheme and hostname back off
    # of it again.  Verify the scheme and hostname while we're at it.
    my $uri = URI->new($request->uri);
    is($uri->scheme, 'https', 'Scheme');
    is($uri->host,   $host,   'Hostname');
    my $path = $uri->path;

    # Get the username and "password" (actually the hash).  Verify the
    # username.
    my ($username, $password) = $request->authorization_basic;
    is($username, $self->{integration_key}, 'Username');

    # If there is request data, sort it for signing purposes.
    my $args;
    if ($method eq 'GET') {
        $args = $uri->query // q{};
    } else {
        $args = $request->content // q{};
    }
    $args = join(q{&}, sort(split(m{&}xms, $args)));

    # Generate the hash of the request and check it.
    my $data      = join("\n", $date, $method, $host, $path, $args);
    my $signature = hmac_sha1_hex($data, $self->{secret_key});
    is($password, $signature, 'Signature');
    return;
}

# Given an HTTP::Request, pretend to perform the request and return an
# HTTP::Response object.  The content of the HTTP::Response object will be
# determined by the most recent calls to the testing API.  Each request resets
# the response.  If no response has been configured, throw an exception.
#
# $self    - Net::Duo::Mock::Agent object
# $request - HTTP::Request object to verify
#
# Returns: An HTTP::Response object
#  Throws: Exception on fatally bad requests or on an unconfigured test
sub request {
    my ($self, $request) = @_;

    # Throw an exception if we got an unexpected call.
    if (!@{ $self->{expected} }) {
        croak('saw an unexpected request');
    }
    my $expected = shift(@{ $self->{expected} });

    # Verify the signature on the request.  We continue even if it doesn't
    # verify and check the rest of the results.
    $self->_verify_signature($request);

    # Ensure the method and URI match what we expect, and extract the content.
    is($request->method, $expected->{method}, 'Method');
    my $uri = $request->uri;
    my $content;
    if ($request->method eq 'GET') {
        if ($uri =~ s{ [?] (.*) }{}xms) {
            $content = $1;
        } else {
            $content = q{};
        }
    } else {
        $content = $request->content // q{};
    }
    is($uri, $expected->{uri}, 'URI');

    # Decode the content.
    my @pairs = split(m{&}xms, $content // q{});
    my %content;
    for my $pair (@pairs) {
        my ($key, $value) = split(m{=}xms, $pair, 2);
        $key   = decode('UTF-8', uri_unescape($key));
        $value = decode('UTF-8', uri_unescape($value));
        $content{$key} = $value;
    }

    # Check the content.
    if ($expected->{content}) {
        is_deeply(\%content, $expected->{content}, 'Content');
    } else {
        is($content, q{}, 'Content');
    }

    # Return the configured response.
    my $response = $expected->{response};
    return $response;
}

##############################################################################
# Test API
##############################################################################

# Constructor for the mock agent.  Takes the same arguments as are passed to
# the Net::Duo constructor (minus the user_agent argument) so that the mock
# knows the expected keys and hostname.
#
# $class    - Class into which to bless the object
# $args_ref - Arguments to the Net::Duo constructor
#   api_hostname    - API hostname for the Duo API integration
#   integration_key - Public key for the Duo API integration
#   key_file        - Path to file with integration information
#   secret_key      - Secret key for the Duo API integration
#
# Returns: New Net::Duo::Mock::Agent object
#  Throws: Text exception on failure to read keys
sub new {
    my ($class, $args_ref) = @_;
    my $self = {};

    # Load integration information from key_file if set.
    my $keys;
    if ($args_ref->{key_file}) {
        my $json     = JSON->new()->relaxed(1);
        my $key_data = slurp($args_ref->{key_file});
        $keys = $json->decode($key_data);
    }

    # Integration data from $args_ref overrides key_file data.
    for my $key (qw(api_hostname integration_key secret_key)) {
        $self->{$key} = $args_ref->{$key} // $keys->{$key};
    }

    # Create the JSON decoder that we'll use for subsequent operations.
    $self->{json} = JSON->new->utf8(1);

    # Create the queue of expected requests.
    $self->{expected} = [];

    # Bless and return the new object.
    bless($self, $class);
    return $self;
}

# Configure an expected request and the response to return.  Either response
# or response_file should be given.  If response_file is given, an
# HTTP::Response with a status code of 200 and the contents of that file as
# the body (Content-Type: application/json).
#
# $self     - Net::Duo::Mock::Agent object
# $args_ref - Expected request and response information
#   method        - Expected method of the request
#   uri           - Expected URI of the request without any query string
#   content       - Expected query or post data as reference (may be undef)
#   response      - HTTP::Response object to return to the caller
#   response_data - Partial data structure to add to generic JSON in response
#   response_file - File containing JSON to return as a respose
#   next_offset   - Return paging metadata with this next_offset key
#   total_objects - Value for the paging metadata if next_offset is given
#
# Returns: undef
#  Throws: Text exception on invalid parameters
#          Text exception if response_file is not readable
sub expect {
    my ($self, $args_ref) = @_;

    # Verify consistency of the arguments.
    my @response_args  = qw(response response_data response_file);
    my $response_count = grep { defined($args_ref->{$_}) } @response_args;
    if ($response_count < 1) {
        croak('no response, response_data, or response_file specified');
    } elsif ($response_count > 1) {
        croak('too many of response, response_data, and response_file given');
    }

    # Build the response object if needed.
    my $response;
    if ($args_ref->{response}) {
        $response = $args_ref->{response};
    } else {
        $response = HTTP::Response->new(200, 'Success');
        $response->header('Content-Type', 'application/json');
        my $reply;
        if (defined($args_ref->{response_data})) {
            my $data = $args_ref->{response_data};
            $reply = { stat => 'OK', response => $data };
        } else {
            my $contents = slurp($args_ref->{response_file});
            my $data     = $self->{json}->decode($contents);
            $reply = { stat => 'OK', response => $data };
        }
        if (defined($args_ref->{next_offset})) {
            $reply->{metadata} = {
                next_offset   => $args_ref->{next_offset},
                prev_offset   => 0,
                total_objects => $args_ref->{total_objects},
            };
        } elsif (exists($args_ref->{next_offset})) {
            $reply->{metadata} = {
                prev_offset   => 0,
                total_objects => $args_ref->{total_objects},
            };
        }
        $response->content($self->{json}->encode($reply));
    }

    # Set the expected information for call verification later.
    my $expected = {
        method   => uc($args_ref->{method}),
        uri      => 'https://' . $self->{api_hostname} . $args_ref->{uri},
        content  => $args_ref->{content},
        response => $response,
    };
    push(@{ $self->{expected} }, $expected);
    return;
}

1;
__END__

=for stopwords
Allbery JSON URI CPAN ARGS API uri hostname sublicense MERCHANTABILITY
NONINFRINGEMENT

=head1 NAME

Net::Duo::Mock::Agent - Mock LWP::UserAgent for Net::Duo testing

=head1 SYNOPSIS

    # Build the Net::Duo object and the mock.
    my %args = (key_file => 'admin.json');
    my $mock = Net::Duo::Mock::Agent->new(\%args);
    $args{user_agent} = $mock;
    my $duo = Net::Duo::Admin->new(\%args);

    # Indicate what to expect and then make the Net::Duo call.
    $mock->expect(
        {
            method        => 'GET',
            uri           => '/admin/v1/users',
            response_file => 'response.json',
        }
    );
    my @users = $duo->users;

=head1 REQUIREMENTS

Perl 5.14 or later and the modules HTTP::Request and HTTP::Response (part
of HTTP::Message), JSON, Perl6::Slurp, and URI::Escape (part of URI), all
of which are available from CPAN.

=head1 DESCRIPTION

This module provides the same interface as LWP::UserAgent, for the methods
that Net::Duo calls, and verifies that the information passed in by Duo is
correct.  It can also simulate responses to exercise response handling in
Net::Duo.  To test Net::Duo, pass a Test::Mock::Duo::Agent object to the
constructor of a Net::Duo-based class as the user_agent argument.

All tests are reported by Test::More, and no effort is made to produce a
predictable number of test results.  This means that any calling test
program should probably not specify a plan and instead use done_testing().

This module is primarily used by the Net::Duo test suite and can be
ignored entirely when using Net::Duo normally.  It is provided as part of
the Net::Duo module install, instead of kept only in the distribution
source tree, because it may be useful for the test suites of other Perl
modules or programs that use Net::Duo internally and want to test that
integration without network access or a live Duo account to point to.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new Net::Duo::Mock::Agent object.  ARGS should be the same data
structure passed to the Net::Duo-derived constructor (with the obvious
exception of the user_agent argument, which is ignored).

=back

=head1 INSTANCE METHODS

=over 4

=item expect(ARGS)

Expect a REST API call from Net::Duo.  This method can be called multiple
times to build up a queue of expected requests.

ARGS is used to specify both the expected request data and the response
to return to the caller.  The same response is returned regardless of
whether the request is correct.

There are two ways to specify the response: a complete HTTP::Response
object, or the JSON data of the response.  If only the JSON data is
specified, the request will return a response with a status code of 200
and a Duo success result (C<stat> of C<OK>), with the supplied JSON data
as the C<response> key in the JSON response data.  The content will have
a Content-Type of C<application/json>.

ARGS should be a reference to a hash with keys selected from the
following:

=over 4

=item method

The expected method of the request.

=item uri

The expected URI of the request.  This should just be the path, not the
hostname or protocol portions of the full URL, and should not include any
GET parameters.

=item content

The expected content of the request.  This is the parameters in the URL
if the method is GET and the expected C<application/x-www-form-urlencoded>
content of the request for any other request type.  It may be empty or not
specified if the request should not contain any additional parameters.

=item response

An HTTP::Response object to return to the client.  This object is always
returned without modification to any request, even if it doesn't match the
expected request.

=item response_data

A data structure that will be converted to JSON and included as the value
of the C<response> key in the returned success response to the client.

=item response_file

A file containing JSON that will be included as the value of the
C<response> key in the returned success response to the client.

=item next_offset

Return paging metadata in the response, setting the C<next_offset> key to
this value, the C<prev_offset> key to 0, and the C<total_objects> key to
the value of the I<total_objects> parameter, which must be specified as
well.  Set this to C<undef> to include pagination information but without
a C<next_offset> key.

=item total_objects

Value to return in the C<total_objects> key in the paging metadata.

=back

=item request(REQUEST)

This is the interface called internally by Net::Duo to make an API call.
The interface is the same as the request() method of LWP::UserAgent:
REQUEST is an HTTP::Request object, and Net::Duo::Mock::Agent will return
an HTTP::Response object.  Currently, this is the only LWP::UserAgent
method implemented by this mock, since it's the only one that Net::Duo
uses.

When request() is called, it checks the content of the request against
whatever the mock was told to expect via the expect() method.  The results
of that comparison are reported via Test::More functions.  The expected
call is then cleared.  This means that expect() must be called between
each call to a Net::Duo method that would result in a REST API call
request.

If request() is called when no request was expected (via an expect() call),
it throws an exception.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 The Board of Trustees of the Leland Stanford Junior
University

Copyright 2019 Russ Allbery <rra@cpan.org>

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

L<Net::Duo>

This module is part of the Net::Duo distribution.  The current version of
Net::Duo is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/net-duo/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
