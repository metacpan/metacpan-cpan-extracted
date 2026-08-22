package Punk::Test::WS;

use 5.010;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.28';

our @EXPORT_OK = qw(
    encode_client encode_server decode_ref accept_key handshake_request
    upgrade_env
);

use Digest::SHA ();
use MIME::Base64 ();

my $GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

sub encode_client {
    my (%a) = @_;
    my $payload = defined $a{payload} ? $a{payload} : '';
    my $opcode  = defined $a{opcode}  ? $a{opcode}  : 1;
    my $fin     = exists $a{fin}      ? $a{fin}     : 1;
    my $mask    = $a{mask} || pack 'C4', map { int rand 256 } 1 .. 4;

    my $len = length $payload;
    my $out = pack 'C', ($fin ? 0x80 : 0) | ($opcode & 0x0F);
    if    ($len < 126)     { $out .= pack 'C', 0x80 | $len }
    elsif ($len <= 0xFFFF) { $out .= pack 'C', 0x80 | 126; $out .= pack 'n', $len }
    else                   { $out .= pack 'C', 0x80 | 127; $out .= pack 'Q>', $len }
    $out .= $mask;

    my @m = unpack 'C4', $mask;
    my @p = unpack 'C*', $payload;
    $p[$_] ^= $m[$_ % 4] for 0 .. $#p;
    return $out . pack 'C*', @p;
}

# A server frame: never masked.
sub encode_server {
    my (%a) = @_;
    my $payload = defined $a{payload} ? $a{payload} : '';
    my $opcode  = defined $a{opcode}  ? $a{opcode}  : 1;
    my $fin     = exists $a{fin}      ? $a{fin}     : 1;

    my $len = length $payload;
    my $out = pack 'C', ($fin ? 0x80 : 0) | ($opcode & 0x0F);
    if    ($len < 126)     { $out .= pack 'C', $len }
    elsif ($len <= 0xFFFF) { $out .= pack 'C', 126; $out .= pack 'n', $len }
    else                   { $out .= pack 'C', 127; $out .= pack 'Q>', $len }
    return $out . $payload;
}

# Decode one frame. Returns a hashref (consumed, fin, opcode, payload,
# masked), or undef when more bytes are needed, or a string error name.
sub decode_ref {
    my ($buf) = @_;
    return undef if length $buf < 2;
    my ($b0, $b1) = unpack 'C2', $buf;
    my $fin    = ($b0 & 0x80) ? 1 : 0;
    my $rsv    = ($b0 >> 4) & 0x07;
    my $opcode = $b0 & 0x0F;
    my $masked = ($b1 & 0x80) ? 1 : 0;
    my $len    = $b1 & 0x7F;
    my $off    = 2;

    return 'rsv' if $rsv;
    if ($opcode & 0x08) {
        return 'control-fragmented' unless $fin;
        return 'control-too-long'   if $len > 125;
    }

    if ($len == 126) {
        return undef if length $buf < 4;
        $len = unpack 'n', substr $buf, 2, 2;
        $off = 4;
    }
    elsif ($len == 127) {
        return undef if length $buf < 10;
        $len = unpack 'Q>', substr $buf, 2, 8;
        return 'length-msb' if $len & (1 << 63);
        $off = 10;
    }

    my $mask;
    if ($masked) {
        return undef if length $buf < $off + 4;
        $mask = substr $buf, $off, 4;
        $off += 4;
    }
    return undef if length $buf < $off + $len;

    my $payload = substr $buf, $off, $len;
    if ($masked) {
        my @m = unpack 'C4', $mask;
        my @p = unpack 'C*', $payload;
        $p[$_] ^= $m[$_ % 4] for 0 .. $#p;
        $payload = pack 'C*', @p;
    }
    return {
        consumed => $off + $len, fin => $fin, opcode => $opcode,
        payload  => $payload,    masked => $masked,
    };
}

sub accept_key {
    my ($key) = @_;
    return MIME::Base64::encode_base64(Digest::SHA::sha1($key . $GUID), '');
}

# A complete client handshake request for a live server test.
sub handshake_request {
    my (%a) = @_;
    my $path = $a{path} || '/';
    # exists, not truth: a test asking for an empty key means "send no
    # key", which is exactly the case the server must reject
    my $key = exists $a{key} ? $a{key}
            : MIME::Base64::encode_base64(
                  pack('C16', map { int rand 256 } 1 .. 16), '');
    my $ver  = exists $a{version} ? $a{version} : 13;
    my $req  = "GET $path HTTP/1.1\r\n"
             . "Host: $a{host}\r\n"
             . "Upgrade: websocket\r\n"
             . "Connection: Upgrade\r\n";
    $req .= "Sec-WebSocket-Key: $key\r\n"          if defined $key && length $key;
    $req .= "Sec-WebSocket-Version: $ver\r\n"      if defined $ver;
    $req .= "Sec-WebSocket-Protocol: $a{protocol}\r\n" if $a{protocol};
    $req .= "$_\r\n" for @{ $a{extra} || [] };
    $req .= "\r\n";
    return wantarray ? ($req, $key) : $req;
}

# The PSGI env of an upgrade request, for driving an app in-process: the C
# handshake in punk_wshandshake.h validates env headers, not raw bytes.
# Returns ($env, $key); the caller adds psgix.io and any cookies.
sub upgrade_env {
    my (%a) = @_;
    my $key = MIME::Base64::encode_base64(
                  pack('C16', map { int rand 256 } 1 .. 16), '');
    my $env = {
        REQUEST_METHOD              => 'GET',
        PATH_INFO                   => $a{path} || '/',
        QUERY_STRING                => $a{query} // '',
        SERVER_NAME                 => 'localhost', SERVER_PORT => 80,
        HTTP_HOST                   => 'localhost',
        'psgi.url_scheme'           => 'http',
        HTTP_UPGRADE                => 'websocket',
        HTTP_CONNECTION             => 'Upgrade',
        HTTP_SEC_WEBSOCKET_KEY      => $key,
        HTTP_SEC_WEBSOCKET_VERSION  => 13,
    };
    $env->{HTTP_SEC_WEBSOCKET_PROTOCOL} = $a{protocol} if $a{protocol};
    return ($env, $key);
}

1;

__END__

=head1 NAME

Punk::Test::WS - a pure-Perl RFC 6455 codec for testing WebSocket servers

=head1 SYNOPSIS

    use Punk::Test::WS qw(encode_client decode_ref accept_key);

    syswrite $sock, encode_client(opcode => 1, payload => 'hello');
    my $frame = decode_ref($bytes);   # { fin, opcode, payload, ... }

=head1 DESCRIPTION

An independent pure-Perl implementation of the WebSocket wire format,
used by L<Punk::Test> to drive websocket routes and by Punk's own test
suite to cross-check the C codec in C<punk_ws.h> - two implementations
of the spec, written separately, so a shared misunderstanding cannot
hide. It depends only on core modules (L<Digest::SHA>,
L<MIME::Base64>).

Nothing here touches Punk's C: this is deliberately the client's view
of the protocol.

=head1 FUNCTIONS

All exported on request.

=head2 encode_client(%args)

One client frame - always masked, per RFC 6455 5.3. Arguments:
C<payload> (default empty), C<opcode> (default 1, text), C<fin>
(default 1), C<mask> (4 random bytes unless given). Returns the wire
bytes.

=head2 encode_server(%args)

One server frame - never masked. Same arguments minus C<mask>. Useful
for sending a deliberately unmasked frame at a server that must refuse
it.

=head2 decode_ref($bytes)

Decode one frame off the front of C<$bytes>. Returns a hashref
(C<consumed>, C<fin>, C<opcode>, C<payload>, C<masked>), or C<undef>
when more bytes are needed, or a string error name (C<rsv>,
C<control-fragmented>, C<control-too-long>, C<length-msb>) for a
protocol violation.

=head2 accept_key($key)

The C<Sec-WebSocket-Accept> digest for a C<Sec-WebSocket-Key>, per the
RFC.

=head2 handshake_request(%args)

A complete client upgrade request for a live TCP test. Arguments:
C<path>, C<host>, C<key> (pass an empty string to send no key - the
case a server must reject), C<version> (default 13), C<protocol>,
C<extra> (an arrayref of additional raw header lines). In list context
returns C<($request, $key)>.

=head2 upgrade_env(%args)

The PSGI env of an upgrade request, for driving a compiled app
in-process: Punk's C handshake validates env headers, not raw bytes.
Arguments: C<path>, C<query>, C<protocol>. Returns C<($env, $key)>;
the caller adds C<psgix.io> and any cookies.

=head1 SEE ALSO

L<Punk::Test::WS::Conn> - a client-side connection over any socket,
built on this codec. L<Punk::Test>, L<Punk::WebSocket>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
