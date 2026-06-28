#!/usr/bin/perl
# ASCII85 and ASCIIHex filter coverage — covers what t/c/test_ascii85.c and
# t/c/test_asciihex.c used to test.
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('PDF::Make::Filter') }

# ── ASCII85 encode/decode ───────────────────────────────

# Empty input → only the ~> terminator after decode
is(PDF::Make::Filter::ascii85_decode('~>'), '', 'ascii85: empty');
is(PDF::Make::Filter::ascii85_decode(''),   '', 'ascii85: empty (no EOD)');

# The classic Wikipedia example
{
    my $raw = 'Man is distinguished, not only by his reason, but by this'
            . ' singular passion from other animals, which is a lust of'
            . ' the mind, that by a perseverance of delight in the'
            . ' continued and indefatigable generation of knowledge,'
            . ' exceeds the short vehemence of any carnal pleasure.';
    my $enc = PDF::Make::Filter::ascii85_encode($raw);
    like($enc, qr/~>$/, 'ascii85: encode ends with ~>');
    is(PDF::Make::Filter::ascii85_decode($enc), $raw, 'ascii85: wikipedia roundtrip');
}

# The 'z' shorthand for four zero bytes
{
    my $zeros = "\0\0\0\0";
    my $enc   = PDF::Make::Filter::ascii85_encode($zeros);
    like($enc, qr/^z/, 'ascii85: four zero bytes encode to z');
    is(PDF::Make::Filter::ascii85_decode($enc), $zeros, 'ascii85: z roundtrip');
}

# 'z' in the middle of a stream
{
    my $raw = "ABC" . "\0\0\0\0" . "XYZ";
    my $enc = PDF::Make::Filter::ascii85_encode($raw);
    is(PDF::Make::Filter::ascii85_decode($enc), $raw, 'ascii85: z in middle');
}

# Final partial group of 1-4 bytes (non-multiple of 4)
for my $len (1..7) {
    my $raw = join('', map { chr(0x40 + $_) } 1..$len);
    my $enc = PDF::Make::Filter::ascii85_encode($raw);
    is(PDF::Make::Filter::ascii85_decode($enc), $raw,
       "ascii85: $len-byte roundtrip");
}

# High bytes (0x80-0xFF) — stresses the base-85 unpacking
{
    my $raw = join('', map chr, 0..255);
    my $enc = PDF::Make::Filter::ascii85_encode($raw);
    is(PDF::Make::Filter::ascii85_decode($enc), $raw, 'ascii85: 0..255 roundtrip');
}

# Whitespace and CRLF are tolerated in decode input
{
    my $raw = 'The quick brown fox';
    my $enc = PDF::Make::Filter::ascii85_encode($raw);
    (my $spaced = $enc) =~ s/(..)/$1 /g;    # insert spaces
    is(PDF::Make::Filter::ascii85_decode($spaced), $raw,
       'ascii85: whitespace tolerated');

    (my $newlined = $enc) =~ s/(..)/$1\n/g;
    is(PDF::Make::Filter::ascii85_decode($newlined), $raw,
       'ascii85: newlines tolerated');
}

# ── ASCIIHex encode/decode ──────────────────────────────

is(PDF::Make::Filter::asciihex_encode(''), '>', 'asciihex: empty encode');
is(PDF::Make::Filter::asciihex_decode('>'), '', 'asciihex: empty decode');

# Simple ASCII roundtrip
{
    my $raw = 'Hello';    # 48 65 6C 6C 6F
    my $enc = PDF::Make::Filter::asciihex_encode($raw);
    is($enc, '48656C6C6F>', 'asciihex: Hello encodes correctly');
    is(PDF::Make::Filter::asciihex_decode($enc), $raw, 'asciihex: roundtrip');
}

# Lowercase hex on decode
is(PDF::Make::Filter::asciihex_decode('48656c6c6f>'), 'Hello',
   'asciihex: lowercase hex decoded');

# Whitespace between pairs is ignored
is(PDF::Make::Filter::asciihex_decode("48 65\n6C 6C\n6F>"), 'Hello',
   'asciihex: whitespace tolerated');

# Missing '>' terminator decodes what it has
is(PDF::Make::Filter::asciihex_decode("48656C6C6F"), 'Hello',
   'asciihex: missing EOD marker tolerated');

# Odd number of hex digits — final digit is padded with 0
# '4' becomes 0x40
is(PDF::Make::Filter::asciihex_decode('4>'), chr(0x40),
   'asciihex: odd final digit padded');
is(PDF::Make::Filter::asciihex_decode('414>'), "A" . chr(0x40),
   'asciihex: mixed even + odd final digit');

# Full 0..255 byte roundtrip
{
    my $raw = join('', map chr, 0..255);
    my $enc = PDF::Make::Filter::asciihex_encode($raw);
    is(PDF::Make::Filter::asciihex_decode($enc), $raw,
       'asciihex: 0..255 roundtrip');
    like($enc, qr/^[0-9A-F]*>$/, 'asciihex: output is uppercase hex + >');
}

done_testing;
