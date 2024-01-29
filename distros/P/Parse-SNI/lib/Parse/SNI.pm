package Parse::SNI;

=pod

=encoding utf8

=head1 NAME

Parse::SNI - parse Server Name Indication from TLS handshake

=head1 SYNOPSIS

    use Parse::SNI;
    use IO::Socket;

    my $srv = IO::Socket::INET->new( LocalAddr => 'localhost', LocalPort => 443, Listen => 1 ) or die $@;

    while ( my $cli = $srv->accept() ) {
        $cli->sysread( my $buf, 4096 ) or next;
        my $sni = parse_sni($buf);
    }

=cut

use strict;
use Exporter 'import';

our $VERSION = '0.10';

use constant {
    TLS_HEADER_LEN                  => 5,
    TLS_HANDSHAKE_CONTENT_TYPE      => 0x16,
    TLS_HANDSHAKE_TYPE_CLIENT_HELLO => 0x01,
};

our @EXPORT = qw(parse_sni);

=head1 FUNCTIONS

=head2 parse_sni($data)

Tries to parse SNI from the passed data string, which should contain complete initial TLS handshake record from the client.
On success returns SNI string in scalar context and C<(SNI string, start position of SNI in $data)> in list context.
On error dies with human readable message. One of the usefull error message to parse is C</Incomplete TLS record: expected \d+ bytes, got \d+/>.
This may occure when u didn't read all of initial handshake from the client. You should catch it, read remaining message from the client and
try again.

This function exported by default.

=cut

# this code was adopted from https://github.com/dlundquist/sniproxy/

sub parse_sni {
    my @data = unpack('C*', $_[0]);

    die 'Too short data' if @data < TLS_HEADER_LEN;

    if ( $data[0] & 0x80 && $data[2] == 1 ) {
        die 'Received SSL 2.0 Client Hello which can not support SNI.';
    }

    if ( $data[0] != TLS_HANDSHAKE_CONTENT_TYPE ) {
        die 'Request did not begin with TLS handshake.';
    }

    my $tls_version_major = $data[1];
    my $tls_version_minor = $data[2];

    if ( $tls_version_major < 3 ) {
        die "Received SSL v$tls_version_major.$tls_version_minor handshake which can not support SNI.";
    }

    my $len = ($data[3] << 8) + $data[4] + TLS_HEADER_LEN;
    die "Incomplete TLS record: expected $len bytes, got " . @data if $len > @data;

    my $pos = TLS_HEADER_LEN;
    die 'Incorrect TLS header length (1)' if $pos + 1 > @data;
    die 'Not a client hello' if $data[$pos] != TLS_HANDSHAKE_TYPE_CLIENT_HELLO;

    $pos += 38;

    die 'Incorrect TLS header length (2)' if $pos + 1 > @data;
    $len = $data[$pos];
    $pos += 1 + $len;

    die 'Incorrect TLS header length (3)' if $pos + 2 > @data;

    $len = ($data[$pos] << 8) + $data[$pos + 1];
    $pos += 2 + $len;

    die 'Incorrect TLS header length (4)' if $pos + 1 > @data;

    $len = $data[$pos];
    $pos += 1 + $len;

    if ( $pos == @data && $tls_version_major == 3 && $tls_version_minor == 0 ) {
        die 'Received SSL 3.0 handshake without extensions';
    }

    die 'Incorrect TLS header length (5)' if $pos + 2 > @data;

    $len = ($data[$pos] << 8) + $data[$pos+1];
    $pos += 2;

    die 'Incorrect TLS header length (6)' if $pos + $len > @data;

    my $end = $pos + $len;
    while ( $pos + 4 <= $end ) {
        my $ext_len = ($data[$pos + 2] << 8) + $data[$pos + 3];

        if ( $data[$pos] == 0x00 && $data[$pos + 1] == 0x00 ) {
            die 'Incorrect TLS header length (7)' if $pos + 4 + $ext_len > $end;

            $pos += 4;
            my $end = $pos + $ext_len;
            $pos += 2;
            while ( $pos + 3 < $end ) {
                my $len = ($data[$pos+1] << 8) + $data[$pos+2];
                die 'Incorrect TLS header length (8)' if $pos + 3 + $len > $end;

                if ( $data[$pos] == 0x00 ) {
                    my $sni = join '', map { chr } @data[$pos+3..$pos+2+$len];
                    return wantarray ? ( $sni, $pos+3 ) : $sni;
                }

                $pos += 3 + $len;
            }
        }

        $pos += 4 + $ext_len;
    }

    die 'Incorrect TLS header length (9)' if $pos != $end;
    die 'No Host header included in this request';
}

1;

=head1 SEE ALSO

L<sniproxy|https://github.com/dlundquist/sniproxy/>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
