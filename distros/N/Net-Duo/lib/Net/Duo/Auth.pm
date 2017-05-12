# Perl interface for the Duo Auth API.
#
# This Perl module collection provides a Perl interface to the Auth API
# integration for the Duo multifactor authentication service
# (https://www.duosecurity.com/).  It differs from the Perl API sample code in
# that it wraps all the returned data structures in objects with method calls,
# abstracts some of the API details, and throws rich exceptions rather than
# requiring the caller deal with JSON data structures directly.

package Net::Duo::Auth 1.01;

use 5.014;
use strict;
use warnings;

use parent qw(Net::Duo);

use Carp qw(croak);
use Net::Duo::Auth::Async;
use URI::Escape qw(uri_escape_utf8);

# All dies are of constructed objects, which perlcritic misdiagnoses.
## no critic (ErrorHandling::RequireCarping)

##############################################################################
# Auth API methods
##############################################################################

# Helper function to validate and canonicalize arguments to the auth and
# auth_async functions.  Ensures that the arguments meet the calling contract
# for the auth method (see below) and returns a reference to a new hash with
# the canonicalized copy of data.
#
# $self     - The Net::Duo::Auth object
# $args_ref - Reference to hash of arguments to an auth function
#
# Returns: Reference to hash of canonicalized arguments
#  Throws: Text exception on internal call method error
sub _canonicalize_auth_args {
    my ($self, $args_ref) = @_;
    my %args = %{$args_ref};

    # Ensure we have either username or user_id, but not neither or both.
    my $user_count = grep { defined($args{$_}) } qw(username user_id);
    if ($user_count < 1) {
        croak('no username or user_id specified');
    } elsif ($user_count > 1) {
        croak('username and user_id both given');
    }

    # Ensure factor is set.
    if (!defined($args{factor})) {
        croak('no factor specified');
    }

    # Set some defaults that we provide in our API guarantee.
    my $factor = $args{factor};
    if ($factor eq 'push' || $factor eq 'phone' || $factor eq 'auto') {
        $args{device} //= 'auto';
    }

    # Convert pushinfo to a URL-encoded string if it is present.  We use this
    # logic rather than _canonicalize_args so that we can preserve order.
    if ($args{pushinfo}) {
        my @pushinfo = @{ $args{pushinfo} };
        my @pairs;
        while (@pushinfo) {
            my $encoded_key   = uri_escape_utf8(shift(@pushinfo));
            my $encoded_value = uri_escape_utf8(shift(@pushinfo));
            my $pair          = $encoded_key . q{=} . $encoded_value;
            push(@pairs, $pair);
        }
        $args{pushinfo} = join(q{&}, @pairs);
    }

    # Return the results.  Currently, we don't validate any of the other
    # arguments and just pass them straight to Duo.  We could do better about
    # this.
    return \%args;
}

# Perform a synchronous user authentication.  The user will be authenticated
# given the factor and additional information provided in the $args argument.
# The call will not return until the user has authenticated or the call has
# failed for some reason.  To do long-polling instead, see the auth_async
# method.
#
# $self     - The Net::Duo::Auth object
# $args_ref - Reference to hash of arguments, chosen from:
#   user_id  - ID of user (either this or username is required)
#   username - Username of user (either this or user_id is required)
#   factor   - One of auto, push, passcode, or phone
#   ipaddr   - IP address of user (optional)
# For factor == push:
#   device           - ID of the device (optional, default is "auto")
#   type             - String to display before prompt (optional)
#   display_username - String instead of username (optional)
#   pushinfo         - Reference to array of pairs to show user (optional)
# For factor == passcode:
#   passcode - The passcode to validate
# For factor == phone:
#   device - The ID of the device to call (optional, default is "auto")
#
# Returns: Scalar context: true if user was authenticated, false otherwise
#          List context: true/false for success, then hash of additional data
#            status               - Status of authentication
#            status_msg           - Detailed status message
#            trusted_device_token - Token to use later for /preauth
#  Throws: Net::Duo::Exception on failure
sub auth {
    my ($self, $args_ref) = @_;
    my $args = $self->_canonicalize_auth_args($args_ref);

    # Make the call to Duo.
    my $result = $self->call_json('POST', '/auth/v2/auth', $args);

    # Ensure we got a valid result.
    if (!defined($result->{result})) {
        my $error = 'no authentication result from Duo';
        die Net::Duo::Exception->protocol($error, $result);
    } elsif ($result->{result} ne 'allow' && $result->{result} ne 'deny') {
        my $error = "invalid authentication result $result->{result}";
        die Net::Duo::Exception->protocol($error, $result);
    }

    # Determine whether the authentication succeeded, and return the correct
    # results.
    my $success = $result->{result} eq 'allow';
    delete $result->{result};
    return wantarray ? ($success, $result) : $success;
}

# Perform an asynchronous authentication.
#
# Takes the same arguments as the auth method, but starts an asynchronous
# authentication.  Returns a transaction ID, which can be passed to
# auth_status() to long-poll the result of the authentication.
#
# $self     - The Net::Duo::Auth object
# $args_ref - Reference to hash of arguments, chosen from:
#
# Returns: The transaction ID to poll with auth_status()
#  Throws: Net::Duo::Exception on failure
sub auth_async {
    my ($self, $args_ref) = @_;
    my $args = $self->_canonicalize_auth_args($args_ref);
    $args->{async} = 1;

    # Make the call to Duo.
    my $result = $self->call_json('POST', '/auth/v2/auth', $args);

    # Return the transaction ID.
    if (!defined($result->{txid})) {
        my $error = 'no transaction ID in response to async auth call';
        die Net::Duo::Exception->protocol($error, $result);
    }
    return Net::Duo::Auth::Async->new($self, $result->{txid});
}

# Confirm that authentication works properly.
#
# $self - The Net::Duo::Auth object
#
# Returns: Server time in seconds since UNIX epoch
#  Throws: Net::Duo::Exception on failure
sub check {
    my ($self) = @_;
    my $result = $self->call_json('GET', '/auth/v2/check');
    return $result->{time};
}

# Send one or more passcodes (depending on Duo configuration) to a user via
# SMS.  This should always succeed, so any error results in an exception.
#
# $self     - The Net::Duo::Auth object
# $username - The username to send SMS passcodes to
# $device   - ID of the device to which to send passcodes (optional)
#
# Returns: undef
#  Throws: Net::Duo::Exception on failure
sub send_sms_passcodes {
    my ($self, $username, $device) = @_;
    my $data = {
        username => $username,
        factor   => 'sms',
        device   => $device // 'auto',
    };
    my $result = $self->call_json('POST', '/auth/v2/auth', $data);
    if ($result->{status} ne 'sent') {
        my $status  = $result->{status};
        my $message = $result->{status_msg};
        my $error   = "sending SMS passcodes returned $status: $message";
        die Net::Duo::Exception->protocol($error, $result);
    }
    return;
}

1;
__END__

=for stopwords
Allbery Auth MERCHANTABILITY NONINFRINGEMENT sublicense SMS passcode
passcodes ipaddr pushinfo

=head1 NAME

Net::Duo::Auth - Perl interface for the Duo Auth API

=head1 SYNOPSIS

    my $duo = Net::Duo::Auth->new({ key_file => '/path/to/keys.json' });
    my $timestamp = $duo->check;

=head1 REQUIREMENTS

Perl 5.14 or later and the modules HTTP::Request and HTTP::Response (part
of HTTP::Message), JSON, LWP (also known as libwww-perl), Perl6::Slurp,
Sub::Install, and URI::Escape (part of URI), all of which are available
from CPAN.

=head1 DESCRIPTION

Net::Duo::Auth is an implementation of the Duo Auth REST API for Perl.
Method calls correspond to endpoints in the REST API.  Its goal is to
provide a native, natural interface for all Duo operations in the API from
inside Perl, while abstracting away as many details of the API as can be
reasonably handled automatically.

Currently, only a tiny number of available methods are implemented.

For calls that return complex data structures, the return from the call
will generally be an object in the Net::Duo::Auth namespace.  These
objects all have methods matching the name of the field in the Duo API
documentation that returns that field value.  Where it makes sense, there
will also be a method with the same name but with C<set_> prepended that
changes that value.  No changes are made to the Duo record itself until
the commit() method is called on the object, which will make the
underlying Duo API call to update the data.

On failure, all methods throw a Net::Duo::Exception object.  This can be
interpolated into a string for a simple error message, or inspected with
method calls for more details.  This is also true of all methods in all
objects in the Net::Duo namespace.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new Net::Duo::Auth object, which is used for all subsequent
calls.  This constructor is inherited from Net::Duo.  See L<Net::Duo> for
documentation of the possible arguments.

=back

=head1 INSTANCE METHODS

=over 4

=item auth(ARGS)

Perform a Duo synchronous authentication.

The user will be authenticated given the factor and additional information
provided in ARGS.  The call will not return until the user has
authenticated or the call has failed for some reason.  To do long-polling
instead, see auth_async().

ARGS should be a reference to a hash.  The following keys may always be
present:

=over 4

=item user_id

The Duo ID of the user to authenticate.  Either this or C<username>, but
only one or the other, must be specified.

=item username

The username of the user to authenticate.  Either this or C<username>, but
only one or the other, must be specified.

=item factor

The authentication factor to use, chosen from C<push>, C<passcode>, or
C<phone>, or C<auto> to use whichever of C<push> or C<phone> appears best
for this user's devices according to Duo.  Required.

=item ipaddr

The IP address of the user, used for logging and to support sending an
C<allow> response without further verification if the user is coming from
a trusted network as configured in the integration.

=back

Additional keys may be present depending on C<factor>.  For a C<factor>
value of C<push>:

=over 4

=item device

The ID of the device to which to send the push notification, or C<auto> to
send to the first push-capable device.  Optional, defaulting to C<auto>.

=item type

This string is displayed in the Duo Mobile app before the word C<request>.
The default is C<Login>, so the phrase C<Login request> appears in the
push notification text and on the request details screen.  You may want to
specify C<Transaction>, C<Transfer>, etc.  Optional.

=item display_username

String to display in Duo Mobile in place of the user's Duo username.
Optional.

=item pushinfo

A reference to a list of additional key/value pairs to display to the user
as part of the authentication request.  For example:

    { pushinfo => [from => 'login portal', domain => 'example.com'] }

This is a list rather than a hash so that it preserves the order of
arguments, but there should always be an even number of members in the
list.

=back

For a C<factor> value of C<passcode>:

=over 4

=item passcode

The passcode to validate.  Required.

=back

For a C<factor> value of C<phone>:

=over 4

=item phone

The ID of the device to call, or C<auto> to call the first available
device.  Optional and defaults to C<auto>.

=back

In a scalar context, this method returns true if the user was successfully
authenticated and false if authentication failed for any reason.  In a
list context, the same status argument is returned as the first member of
the list, and the second member of the list will be a reference to a hash
of additional data.  Possible keys are:

=over 4

=item status

String detailing the progress or outcome of the authentication attempt.

=item status_msg

A string describing the result of the authentication attempt.  If the
authentication attempt was denied, it may identify a reason.  This string
is intended for display to the user.

=item trusted_device_token

If the trusted devices option is enabled for this account, returns a token
for a trusted device that can later be passed to the Duo C<preauth>
endpoint.

=back

If you are looking for the Duo C<sms> factor type, use the
send_sms_passcodes() method instead.

=item auth_async(ARGS)

Perform a Duo asynchronous authentication.

An authentication attempt will be started for a user according to the
information provided in ARGS.  The return value from this call will be a
Net::Duo::Admin::Async object, which provides a status() method, to get
the status of the authentication, and an id() method, to recover the
underlying transaction ID.  This approach allows the application to get
the authentication status at each stage, instead of receiving no
information until the authentication has succeeded or failed.

ARGS should be a reference to a hash with the same parameters as were
specified for the L</auth()> method.

=item check()

Calls the Duo C<check> endpoint.  This can be used as a simple check that
all of the integration arguments are correct and the client can
authenticate to the Duo authentication API.  On success, it returns the
current time on the Duo server in seconds since UNIX epoch.

=item send_sms_passcodes(USERNAME[, DEVICE])

Send a new batch of passcodes to the specified user via SMS.  By default,
the passcodes will be sent to the first SMS-capable device (the Duo
C<auto> behavior).  The optional second argument specifies a device ID to
which to send the passcodes.  Any failure will result in an exception.

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

This module is part of the Net::Duo distribution.  The current version of
Net::Duo is available from CPAN, or directly from its web site at
L<http://www.eyrie.org/~eagle/software/net-duo/>.

=cut
