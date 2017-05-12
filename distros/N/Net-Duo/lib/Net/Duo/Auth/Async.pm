# Class representing an asynchronous Duo authentication.
#
# This class wraps the transaction ID returned by Duo from an asynchronous
# authentication and provides a method to long-poll the status of that
# authentication attempt.

package Net::Duo::Auth::Async 1.01;

use 5.014;
use strict;
use warnings;

use Net::Duo;

# All dies are of constructed objects, which perlcritic misdiagnoses.
## no critic (ErrorHandling::RequireCarping)

# Create a new Net::Duo::Auth::Async object from the transaction ID and a
# Net::Duo object.
#
# $class - Class of object to create
# $duo   - Net::Duo object to use for calls
# $id    - The transaction ID of an asynchronous transaction
#
# Returns: Newly-created object
#  Throws: Net::Duo::Exception on any problem creating the object
sub new {
    my ($class, $duo, $id) = @_;
    my $self = { _duo => $duo, id => $id };
    bless($self, $class);
    return $self;
}

# Return the transaction ID.
#
# $self - The Net::Duo::Auth::Async object
#
# Returns: The underlying transaction ID
sub id {
    my ($self) = @_;
    return $self->{id};
}

# Check on the current status of an asynchronous authentication.  This uses
# long polling, meaning that the call returns for every status change,
# but does not otherwise have a timeout.
#
# $self - The Net::Duo::Auth::Async object
#
# Returns: Scalar context: the current status
#          List context: list of current status and reference to hash of data
#  Throws: Net::Duo::Exception on failure
sub status {
    my ($self) = @_;

    # Make the Duo call.
    my $data   = { txid => $self->{id} };
    my $uri    = '/auth/v2/auth_status';
    my $result = $self->{_duo}->call_json('GET', $uri, $data);

    # Ensure the response included a result field.
    if (!defined($result->{result})) {
        my $error = 'no authentication result from Duo';
        die Net::Duo::Exception->protocol($error, $result);
    }
    my $status = $result->{result};
    delete $result->{result};

    # Return the result as appropriate for context.
    return wantarray ? ($status, $result) : $status;
}

1;
__END__

=for stopwords
Allbery Auth MERCHANTABILITY NONINFRINGEMENT async sublicense

=head1 NAME

Net::Duo::Auth::Async - Representation of an asynchronous Duo authentication

=head1 SYNOPSIS

    use 5.010;

    my $config = get_config();
    my $duo = Net::Duo::Auth->new($config);
    my $async = $duo->auth_async({ username => 'user', factor => 'auto' });
    say scalar($async->status);

=head1 REQUIREMENTS

Perl 5.14 or later and the modules HTTP::Request and HTTP::Response (part
of HTTP::Message), JSON, LWP (also known as libwww-perl), Perl6::Slurp,
Sub::Install, and URI::Escape (part of URI), all of which are available
from CPAN.

=head1 DESCRIPTION

Net::Duo::Auth::Async represents an open asynchronous authentication
attempt with Duo.  It's a wrapper around the Duo async transaction ID and
the method to check on the status of that transaction.  This object can
either be created directly from a stored transaction ID or is returned by
the auth_async() method of Net::Duo::Auth.

=head1 CLASS METHODS

=over 4

=item new(DUO, ID)

Create a new Net::Duo::Auth::Async object from a Net::Duo object and a
transaction.  This should be used to recreate the Net::Duo::Auth::Async
object if the transaction ID were handed off to some other process that
then asks for status later.

=back

=head1 INSTANCE METHODS

=over 4

=item id()

Returns the transaction ID represented by this object.  This transaction
ID can be used later to recreate the object.

=item status()

Returns the status of the authentication.

In scalar context, returns only the status, which will be one of C<allow>,
C<deny>, and C<waiting>.  C<waiting> indicates that the authentication is
still in progress and has not yet completed.

In list context, returns the same status as the first element and a
reference to a hash of additional information as the second element.  The
hash will have one or more of the following keys:

=over 4

=item status

String detailing the progress or outcome of the authentication attempt.
See the Duo Auth API documentation for a complete list of possible values.

=item status_msg

A string describing the result of the authentication attempt.  If the
authentication attempt was denied, it may identify a reason.  This string
is intended for display to the user.

=item trusted_device_token

If the trusted devices option is enabled for this account, returns a token
for a trusted device that can later be passed to the Duo C<preauth>
endpoint.

=back

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
