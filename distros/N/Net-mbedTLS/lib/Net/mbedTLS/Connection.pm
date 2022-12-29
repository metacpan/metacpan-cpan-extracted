package Net::mbedTLS::Connection;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::mbedTLS::Connection - Abstract class representing a TLS connection

=head1 SYNOPSIS

(See L<Net::mbedTLS::Client> for a sample creation of C<$tls>.)

    my $sent = $tls->write('Hello');

    my $output = "\0" x 100;
    my $got = $tls->read($output);

… or, to abstract over TLS in general:

    my $fh = $tls->tied_fh();

    print {$fh} "hey there\n";

=head1 DESCRIPTION

This class implements methods common to both server & client TLS
connections.

=head1 METHODS: General

=head2 $fh = I<OBJ>->tied_fh()

Returns a L<Net::mbedTLS::Connection::Tied> instance for I<OBJ>.
See that module for details.

=head1 METHODS: I/O

=head2 $sent = I<OBJ>->read( $PRE_EXTENDED_STRING )

Tries to read from the peer.

$PRE_EXTENDED_STRING is a scalar that will receive the result of
the read. (This is more efficient than creating a new string on
each read.)

Note the following caveats regarding C<$PRE_EXTENDED_STRING>:

=over

=item * If it is undef or empty an exception is thrown.

=item * Depending on how Perl stores the string in memory, its
character length may increase during the read. (This is an effect
of how Perl stores strings in memory.)

(Perl internals note: SvUTF8 is turned off after the read.)

=back

Returns one of:

=over

=item * A positive integer, to represent the number of bytes sent.

=item * 0, to indicate that there is nothing to read, and the TLS
session is done.

=item * undef, to indicate a non-fatal error (e.g., C<ERR_SSL_WANT_READ>).
That error will be the result of I<OBJ>’s C<error()>.

=back

Fatal errors cause a L<Net::mbedTLS::X::Base> instance to be thrown.

=head2 $sent = I<OBJ>->write( $BYTE_STRING )

Tries to send all of $BYTE_STRING to the peer.

Returns the same possibilities as C<read()> above, except that 0
is not returned.

=head2 $done = I<OBJ>->shake_hands()

Performs a TLS handshake. Not strictly needed because C<read()> and
C<write()> will automatically do the handshake “under the hood”, but
if you want to know when the handshake is done this is still useful.

The return is a boolean that indicates completion. If it’s falsy
then the handshake isn’t done, and you’ll need to call this again
once the underlying socket is ready for whatever mbedTLS wants. That
should only happen for non-blocking sockets.

Example non-blocking operation:

    my $done;

    until ($done = $tls->shake_hands()) {
        vec( my $bitmask, fileno($socket), 1 ) = 1;

        if ($tls->error() == Net::mbedTLS::ERR_SSL_WANT_READ) {
            select $bitmask, undef, undef, undef;
        }
        if ($tls->error() == Net::mbedTLS::ERR_SSL_WANT_WRITE) {
            select undef, $bitmask, undef, undef;
        }
        else { ... }
    }

=head2 $done = I<OBJ>->close_notify()

Sends a TLS-level close notification. Should normally happen once
you’re done using the connection.

The return is as for C<shake_hands()>.

=head1 METHODS: INTROSPECTION

=head2 $num = I<OBJ>->error()

The last error code from mbedTLS.

=head2 $fh = I<OBJ>->fh()

A convenience method that returns the Perl filehandle from which you
created I<OBJ>.

=head2 $num = I<OBJ>->verification_result()

Returns a bitmask that represents the peer certificate verification
result. Possible bitmask values are the various C<X509_BADCERT_*>
constants from L<Net::mbedTLS>.
(See mbedTLS’s C<mbedtls_ssl_get_verify_result()>.)

=head2 $str = I<OBJ>->tls_version_name()

A string version of the negotiated TLS version (e.g., C<TLSv1.2>).

=head2 $str = I<OBJ>->ciphersuite()

A string that describes the TLS session’s negotiated cipher suite.

=head2 @certs = I<OBJ>->peer_certificates()

The peer’s certificate chain, in DER (i.e., binary) format.

If you want PEM (Base64) you can use L<Crypt::Format>, e.g.:

    my $pem = Crypt::Format::der2pem($der, 'CERTIFICATE');

This croaks if called outside list context.

=head2 $num = I<OBJ>->max_out_record_payload()

The maximum outgoing record payload, in bytes.

=cut

sub tied_fh {
    my ($self) = @_;

    local ($@, $!);
    require Net::mbedTLS::Connection::Tied;
    return Net::mbedTLS::Connection::Tied->new($self);
}

1;
