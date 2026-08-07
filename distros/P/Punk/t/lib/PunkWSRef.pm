package PunkWSRef;

use 5.010;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    encode_client encode_server decode_ref accept_key handshake_request
);

# An independent pure-Perl RFC 6455 implementation, used only by the test
# suite: the C codec in include/punk/punk_ws.h is checked against this, so
# a shared misunderstanding of the spec cannot hide. Transcribed from the
# Perl reference helpers in Hypersonic's Protocol::WebSocket::Frame (same
# author) rather than from Punk's C, deliberately.

use Digest::SHA ();
use MIME::Base64 ();

use constant GUID => '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

# A client frame: always masked, per RFC 6455 5.3.
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
    return MIME::Base64::encode_base64(Digest::SHA::sha1($key . GUID), '');
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

1;
