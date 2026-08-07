#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk;
use Punk::WebSocket ();
use PunkWSRef qw(encode_client encode_server decode_ref);

# The RFC 6455 frame codec (include/punk/punk_ws.h), checked against the
# independent pure-Perl implementation in t/lib/PunkWSRef.pm - a shared
# misreading of the spec cannot pass both. Plus the five hardening rules
# the codec adds over a naive implementation.

# opcodes
use constant { OP_CONT => 0x0, OP_TEXT => 0x1, OP_BIN => 0x2,
               OP_CLOSE => 0x8, OP_PING => 0x9, OP_PONG => 0xA };

sub dec { Punk::WebSocket::_decode_frame(@_) }

# ---- encode: byte-identical to the reference --------------------------------
{
    for my $case (
        [ 'empty',      ''            ],
        [ 'short',      'hello'       ],
        [ '125 (max 7-bit)',  'x' x 125    ],
        [ '126 (16-bit tier)', 'x' x 126   ],
        [ '65535 (16-bit max)', 'x' x 65535 ],
        [ '65536 (64-bit tier)', 'x' x 65536 ],
    ) {
        my ($name, $payload) = @$case;
        is(Punk::WebSocket::_encode_frame(OP_TEXT, 1, $payload),
           encode_server(opcode => OP_TEXT, fin => 1, payload => $payload),
           "encode text $name matches the reference");
        is(Punk::WebSocket::_encode_frame(OP_BIN, 1, $payload),
           encode_server(opcode => OP_BIN, fin => 1, payload => $payload),
           "encode binary $name matches the reference");
    }
    is(Punk::WebSocket::_encode_frame(OP_TEXT, 0, 'part'),
       encode_server(opcode => OP_TEXT, fin => 0, payload => 'part'),
       'a non-final frame clears FIN');
    is(Punk::WebSocket::_encode_close(1000, 'bye'),
       encode_server(opcode => OP_CLOSE, fin => 1,
                     payload => pack('n', 1000) . 'bye'),
       'close frame carries the code big-endian then the reason');
    is(Punk::WebSocket::_encode_close(1009),
       encode_server(opcode => OP_CLOSE, fin => 1, payload => pack 'n', 1009),
       'close with no reason is just the code');
    is(length(Punk::WebSocket::_encode_close(1000, 'x' x 200)) - 4, 123,
       'an over-long close reason is clamped to 123 bytes');
}

# ---- decode: agrees with the reference on client frames ---------------------
{
    for my $payload ('', 'hello', 'x' x 125, 'x' x 126, 'x' x 65536) {
        my $bytes = encode_client(opcode => OP_TEXT, payload => $payload);
        my $ref   = decode_ref($bytes);
        my @got   = dec($bytes);
        is($got[0], $ref->{consumed}, 'consumed matches the reference ('
            . length($payload) . ' byte payload)');
        is($got[1], $ref->{fin},     'fin matches');
        is($got[2], $ref->{opcode},  'opcode matches');
        is($got[3], $ref->{payload}, 'payload unmasks to the same bytes');
    }
}

# ---- need-more at every length tier ----------------------------------------
{
    my $frame = encode_client(opcode => OP_TEXT, payload => 'x' x 300);
    for my $n (0, 1, 2, 3, 4, 7, 8, length($frame) - 1) {
        my @got = dec(substr $frame, 0, $n);
        is($got[0], 0, "a $n-byte prefix asks for more data");
    }
    is((dec($frame))[0], length $frame, 'the whole frame decodes');
}

# ---- two frames in one buffer ----------------------------------------------
{
    my $a = encode_client(opcode => OP_TEXT, payload => 'one');
    my $b = encode_client(opcode => OP_TEXT, payload => 'two');
    my @first = dec($a . $b);
    is($first[3], 'one', 'first frame from a shared buffer');
    is($first[0], length $a, 'consumed exactly the first frame');
    my @second = dec(substr $a . $b, $first[0]);
    is($second[3], 'two', 'second frame follows');
}

# ---- fix 2: client frames must be masked (1002) -----------------------------
{
    my $unmasked = encode_server(opcode => OP_TEXT, payload => 'hi');
    is((dec($unmasked))[0], -1,
       'an unmasked client frame is a protocol error (close 1002)');
    is((dec($unmasked, 0, 0))[0], length $unmasked,
       'the same frame is fine when masking is not required (client mode)');
}

# ---- fix 3: control frames must be FIN and <= 125 bytes (1002) --------------
{
    is((dec(encode_client(opcode => OP_PING, fin => 0, payload => 'x')))[0],
       -1, 'a fragmented control frame is a protocol error');
    is((dec(encode_client(opcode => OP_CLOSE, payload => 'x' x 126)))[0],
       -1, 'an over-long control frame is a protocol error');
    is((dec(encode_client(opcode => OP_PING, payload => 'x' x 125)))[0] > 0,
       1, 'a 125-byte control frame is allowed');
    is((dec(encode_client(opcode => 0xB, payload => '')))[0], -1,
       'a reserved control opcode is a protocol error');
    is((dec(encode_client(opcode => 0x3, payload => '')))[0], -1,
       'a reserved data opcode is a protocol error');
}

# ---- fix 4: oversized payloads are refused from the header (1009) -----------
{
    my $big = encode_client(opcode => OP_TEXT, payload => 'x' x 5000);
    is((dec($big, 1024))[0], -2,
       'a frame over max_message_size is refused (close 1009)');
    is((dec($big, 0))[0], length $big, 'and allowed when unbounded');
    # the header alone is enough to refuse it - no payload buffered
    is((dec(substr($big, 0, 8), 1024))[0], -2,
       'refused from the header, before the payload arrives');
}

# ---- RSV and 64-bit MSB ------------------------------------------------------
{
    my $f = encode_client(opcode => OP_TEXT, payload => 'x');
    my $rsv = $f;
    substr($rsv, 0, 1) = chr(ord(substr $rsv, 0, 1) | 0x40);   # RSV1
    is((dec($rsv))[0], -1, 'a set RSV bit is a protocol error');

    my $msb = pack('C', 0x81) . pack('C', 0x80 | 127)
            . pack('Q>', (1 << 63) | 4) . 'MASK' . 'abcd';
    is((dec($msb))[0], -1, 'a 64-bit length with the MSB set is refused');
}

# ---- fix 1: UTF-8 validation (1007) -----------------------------------------
{
    ok(Punk::WebSocket::_utf8_valid("plain ascii"), 'ascii is valid utf8');
    ok(Punk::WebSocket::_utf8_valid("caf\xc3\xa9"), 'two-byte sequence');
    ok(Punk::WebSocket::_utf8_valid("\xe2\x82\xac"), 'three-byte sequence');
    ok(Punk::WebSocket::_utf8_valid("\xf0\x9f\x92\xa9"), 'four-byte sequence');
    ok(!Punk::WebSocket::_utf8_valid("\xff"), 'a stray 0xff is invalid');
    ok(!Punk::WebSocket::_utf8_valid("\xc3"), 'a truncated sequence is invalid');
    ok(!Punk::WebSocket::_utf8_valid("\x80\x80"),
       'a lone continuation byte is invalid');
    ok(!Punk::WebSocket::_utf8_valid("\xc0\xaf"),
       'an overlong encoding is invalid');
    ok(!Punk::WebSocket::_utf8_valid("\xed\xa0\x80"),
       'a surrogate is invalid');
    ok(!Punk::WebSocket::_utf8_valid("\xf4\x90\x80\x80"),
       'beyond U+10FFFF is invalid');
}

# ---- close codes a peer may send (RFC 6455 7.4) -----------------------------
{
    ok(Punk::WebSocket::_close_code_ok($_), "close $_ is sendable")
        for 1000, 1001, 1002, 1003, 1007, 1008, 1009, 1010, 1011, 3000, 4999;
    ok(!Punk::WebSocket::_close_code_ok($_), "close $_ is not sendable")
        for 999, 1004, 1005, 1006, 1015, 2999, 5000;
}

# ---- leak gate ---------------------------------------------------------------
{
    my $frame = encode_client(opcode => OP_TEXT, payload => 'x' x 512);
    dec($frame) for 1 .. 5000;
    my ($before) = `ps -o rss= -p $$` =~ /(\d+)/;
    for (1 .. 100_000) {
        my @got = dec($frame);
        my $out = Punk::WebSocket::_encode_text($got[3]);
    }
    my ($after) = `ps -o rss= -p $$` =~ /(\d+)/;
    my $growth = $after - $before;
    cmp_ok($growth, '<=', 512,
        "encode+decode is steady state over 100k frames (grew ${growth}KB)");
}

done_testing();
