#!/usr/bin/perl
# Compression-codec coverage — covers what the deleted t/c/test_flate.c,
# test_rle.c, test_lzw.c and test_predictor.c used to test.
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Filter') }

# ── Adler-32 (RFC 1950) ──────────────────────────────────
is(PDF::Make::Filter::adler32(''),  1, 'adler32: empty = 1');
is(PDF::Make::Filter::adler32('a'), (1 + 97) | ((1 + 97) << 16),
   'adler32: single byte');
# RFC 1950 example: adler32("Wikipedia") = 0x11e60398
is(PDF::Make::Filter::adler32('Wikipedia'), 0x11e60398,
   'adler32: "Wikipedia" example');
is(PDF::Make::Filter::adler32('123456789'), 0x091e01de,
   'adler32: "123456789" example');

# ── Flate (zlib-wrapped DEFLATE) ─────────────────────────
{
    for my $raw ('', 'a', 'hello world',
                 "\0" x 1000,                  # trivially compressible
                 join('', map chr, 0..255),    # full byte range
                 join('', map { chr(rand(256)) } 1..500)) {
        my $enc = PDF::Make::Filter::flate_encode($raw);
        my $dec = PDF::Make::Filter::flate_decode($enc);
        is($dec, $raw, "flate: roundtrip " . length($raw) . " bytes");
    }
}

# zlib header byte is 0x78 (deflate, 32K window) for typical streams
{
    my $enc = PDF::Make::Filter::flate_encode('hello');
    is(ord(substr($enc, 0, 1)), 0x78, 'flate: zlib CMF byte = 0x78');
}

# Large input that exceeds a single deflate block (>64K)
{
    my $raw = 'abcdefghij' x 7000;   # 70 000 bytes
    my $enc = PDF::Make::Filter::flate_encode($raw);
    ok(length($enc) < length($raw), 'flate: 70KB compresses');
    is(PDF::Make::Filter::flate_decode($enc), $raw, 'flate: 70KB roundtrip');
}

# ── Raw DEFLATE (RFC 1951) ───────────────────────────────
{
    for my $level (0, 1, 6, 9) {
        my $raw = 'abcabcabcabcabcabcabc';
        my $enc = PDF::Make::Filter::deflate_encode($raw, $level);
        is(PDF::Make::Filter::deflate_decode($enc), $raw,
           "deflate level $level: roundtrip");
    }
}

# Store-mode (level 0) output never shrinks below original
{
    my $raw = 'abcdefghij' x 100;
    my $enc = PDF::Make::Filter::deflate_encode($raw, 0);
    ok(length($enc) >= length($raw),
       'deflate store mode: output >= input size');
    is(PDF::Make::Filter::deflate_decode($enc), $raw,
       'deflate store mode: roundtrip');
}

# Corrupted flate data should die, not hang
{
    eval { PDF::Make::Filter::flate_decode("\x78\x9c\xff\xff\xff\xff") };
    ok($@, 'flate: corrupt data rejected');
}

# ── RunLengthDecode (§7.4.5) ────────────────────────────
{
    is(PDF::Make::Filter::rle_decode("\x80"), '', 'rle: EOD-only');
    is(PDF::Make::Filter::rle_decode(''),     '', 'rle: empty');

    # Literal run: length N means "copy N+1 literal bytes"
    is(PDF::Make::Filter::rle_decode("\x00A\x80"), 'A', 'rle: literal single');
    is(PDF::Make::Filter::rle_decode("\x04ABCDE\x80"), 'ABCDE',
       'rle: literal of 5 bytes (length byte 4)');

    # Repeat run: byte N in [129..255] means "repeat next byte 257-N times"
    is(PDF::Make::Filter::rle_decode("\xFEA\x80"), 'AAA',
       'rle: repeat 3 = 257-254');
    is(PDF::Make::Filter::rle_decode("\x81A\x80"), 'A' x 128,
       'rle: max repeat 128');
}

# RLE encode/decode roundtrip, including repetitive and mixed data
{
    for my $raw ('', 'A', 'AAAABBBCC',
                 'The quick brown fox jumps over the lazy dog',
                 'X' x 500,
                 join('', map { chr($_ & 0xff) } 1..1024)) {
        my $enc = PDF::Make::Filter::rle_encode($raw);
        is(PDF::Make::Filter::rle_decode($enc), $raw,
           'rle: roundtrip ' . length($raw) . ' bytes');
    }
}

# Missing EOD marker still decodes what it has
is(PDF::Make::Filter::rle_decode("\x00A"), 'A',
   'rle: missing EOD tolerated');


# ── LZWDecode (§7.4.4) ──────────────────────────────────
{
    # Known-good LZW stream decodes to "-----A---B" (literal dashes + table refs)
    my $enc = pack("H*", "800B6050220C0C8501");
    is(PDF::Make::Filter::lzw_decode($enc), '-----A---B',
       'lzw: known pattern decodes correctly');
    is(PDF::Make::Filter::lzw_decode($enc, early_change => 1), '-----A---B',
       'lzw: early_change=1 still works');
}

# Empty input: clear code → EOD
is(PDF::Make::Filter::lzw_decode("\x80\x40"), '', 'lzw: clear+EOD');

# Single literal byte ("A") + EOD, packed MSB-first at 9-bit code width
# CLEAR(256)=100000000, 'A'(65)=001000001, EOD(257)=100000001
is(PDF::Make::Filter::lzw_decode(pack("C*", 0x80, 0x10, 0x60, 0x20)), 'A',
   'lzw: single literal + EOD');

# ── PNG predictor (10-15) — encode/decode roundtrip ─────
{
    # Generate a small 4-row, 4-column grayscale image (16 bytes)
    my $raw = pack("C*", 0x10, 0x20, 0x30, 0x40,
                         0x12, 0x22, 0x32, 0x42,
                         0x14, 0x24, 0x34, 0x44,
                         0x16, 0x26, 0x36, 0x46);

    for my $p (10, 11, 12, 13, 14, 15) {
        my $enc = PDF::Make::Filter::predictor_encode(
            predictor => $p, colors => 1, bits => 8, columns => 4, data => $raw);
        my $dec = PDF::Make::Filter::predictor_decode(
            predictor => $p, colors => 1, bits => 8, columns => 4, data => $enc);
        is($dec, $raw, "predictor $p: roundtrip");
    }
}

# Predictor 1 (no prediction) — roundtrip is a no-op even if the encoded
# stream includes PNG row-filter bytes internally
{
    my $raw = "row1row2row3";
    my $enc = PDF::Make::Filter::predictor_encode(
        predictor => 1, columns => 4, data => $raw);
    is(PDF::Make::Filter::predictor_decode(
            predictor => 1, columns => 4, data => $enc),
       $raw, 'predictor 1: roundtrip');
}

# ── TIFF predictor 2 ────────────────────────────────────
{
    # Horizontally-differenced row: predictor 2 subtracts previous sample
    my $raw = pack("C*", 10, 11, 13, 16, 20, 25);
    my $enc = PDF::Make::Filter::tiff_predictor_encode(
        colors => 1, bits => 8, columns => 6, data => $raw);
    my $dec = PDF::Make::Filter::tiff_predictor_decode(
        colors => 1, bits => 8, columns => 6, data => $enc);
    is($dec, $raw, 'tiff predictor: roundtrip');
    # First byte is unchanged, others are differences
    is(ord(substr($enc, 0, 1)), 10, 'tiff predictor: first byte unchanged');
}

done_testing;
