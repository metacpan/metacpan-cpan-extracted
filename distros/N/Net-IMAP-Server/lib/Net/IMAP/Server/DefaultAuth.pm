package Net::IMAP::Server::DefaultAuth;

use warnings;
use strict;

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(user));

=head1 NAME

Net::IMAP::Server::DefaultAuth - Encapsulates per-connection
authorization information for an IMAP user.

=head1 DESCRIPTION

IMAP credentials are passed in one of two ways: using the L<LOGIN>
command, or the C<AUTHENTICATE> command.  L<LOGIN> sends the password
unencrypted; note, however, that L<Net::IMAP::Server> will not allow
the LOGIN command unless the connection is protected by either SSL or
TLS.  Thus, even when the C<LOGIN> command is used, the password is
not sent in the clear.

The default implementation accepts any username and password.  Most
subclasses will simply want to override L</auth_plain>, unless they
need to implement other forms of authorization than C<LOGIN> or
C<AUTHENTICATE PLAIN>.

=cut

=head1 METHODS

=head2 user [VALUE]

Gets or sets the plaintext username of the authenticated user.

=head2 provides_plain

If L</provides_plain> returns true (the default), C<LOGIN> capability
will be advertised when under a layer, and L</auth_plain> will be
called if the user sends the C<LOGIN> command.

=cut

sub provides_plain { return 1; }

=head2 auth_plain USER, PASSWORD

Returns true if the given C<USER> is allowed to log in using the
provided C<PASSWORD>.  This should also set L</user> to the username
if login was successful.  This path is used by both C<LOGIN> and
C<AUTHENTICATE PLAIN> commands.

=cut

sub auth_plain {
    my $self = shift;
    my ( $user, $pass ) = @_;
    $self->user($user);
    return 1;
}

=head2 sasl_provides

The C<AUTHENTICATE> command checks that the provided SASL
authentication type is in the list that L</sasl_provides> returns.  It
defaults to only C<PLAIN>.

=cut

sub sasl_provides {
    my $self = shift;
    return ("PLAIN");
}

=head2 sasl_plain

Called when the client requests C<PLAIN> SASL authentication.  This
parses the SASL protocol, and defers to L</auth_plain> to determine if
the username and password is actually allowed to log in.

=cut

sub sasl_plain {
    my $self = shift;
    return sub {
        my $line = shift;
        return \"" unless $line;

        my ( $authz, $user, $pass ) = split /\x{0}/, $line, 3;
        return -1 unless defined $authz and defined $user and defined $pass;
        return $self->auth_plain( $user, $pass );
    };
}

=head1 IMPLEMENTING NEW SASL METHODS

The L</sasl_plain> method is a simple example of implementing a SASL
protocol, albeit a very simple one.  SASL authentication methods
should expect to be called with no arguments, and should return an
anonymous function, which will be called each time the client
transmits more information.

Each time it is called, it will be passed the client data, which will
already have been base-64 decoded (the exception being the first time
it is called, when it will be called with the empty string).

If the function returns a scalar reference, the scalar will be base-64
encoded and transmitted to the client.  Anything which is not a scalar
reference will be interpreted as a boolean, as to whether the
authentication was successful.  Successful authentications should be
sure to set L</user> themselves.

=cut

1;
