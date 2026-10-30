use strict;
use utf8;
use warnings;

use Test::More;
use Net::IDN::Punycode::PP ();

use Test::NoWarnings;

no warnings 'utf8';    # perl 5.12 and older warn on the fixtures below

# chr(0xFFFFFFFF) is fatal where ivsize is 4, so build it at runtime, and
# perl 5.8 treats its encoding as malformed
my $max_uv32 = eval { my $cp = 0xFFFFFFFF; chr $cp };
undef $max_uv32 unless defined $max_uv32 && utf8::valid($max_uv32);

our @encode_dies = (
  (defined $max_uv32
    ? ["a".$max_uv32, qr/invalid code point/,
        "a code point far above Unicode"]
    : ()),
  ["a".chr(0x110000), qr/invalid code point/,
    "a code point just above Unicode"],
  ["a".chr(0xD800), qr/invalid code point/,
    "a surrogate code point"],
  [("a" x 4368).chr(983183), qr/exceeds punycode limit/,
    "the skipped basic code points overflow the delta accumulator"],
  [("a" x 3855).chr(0x10FFFF), qr/exceeds punycode limit/,
    "a long basic prefix overflows the delta accumulator"],
);

our @decode_dies = (
  ["\x80-a", qr/non-base character/,
    "a non-basic character before the delimiter"],
  ["a=", qr/invalid digit/,
    "a basic but non-alphanumeric character"],
  ["NMzZNlL6SU", qr/incomplete encoded code point/,
    "truncated label without a delimiter"],
  ["abc-td", qr/incomplete encoded code point/,
    "truncated label after base characters"],
  ["z", qr/incomplete encoded code point/,
    "single digit ending mid code point"],
  ["a-99999999999999999999", qr/exceeds punycode limit/,
    "digit weight overflows"],
  ["a-kk503321e", qr/exceeds punycode limit/,
    "delta accumulator overflows"],
  ["a-j023p", qr/invalid code point/,
    "decodes just above U+10FFFF"],
  ["ib9b", qr/invalid code point/,
    "decodes to a surrogate code point"],
  [("a" x 3900)."-2x485856a", qr/exceeds punycode limit/,
    "a label only an unguarded encoder could produce"],
);

our @malformed = (
  ["abc\xE2\x82", "a truncated UTF-8 sequence"],
  ["\xE2\x82abc", "a truncated UTF-8 sequence at the start"],
  ["abc\xFF", "a byte which starts no UTF-8 sequence"],
  ["a\xC0\x80b", "an overlong encoding"],
);

use warnings 'utf8';

plan tests => 1 + 18
  + 2 * (scalar @encode_dies)
  + 2 * (scalar @decode_dies)
  + 6 * (scalar @malformed);

{
  my $line = __LINE__ + 1;
  is(eval { Net::IDN::Punycode::PP::decode_punycode() }, undef,
    'decode_punycode without arguments dies');
  like($@, qr/^Usage:/, 'decode_punycode usage message');
  like($@, qr/ at \Q$0\E line $line\.\n\z/,
    'decode_punycode usage message names the caller');
  $line = __LINE__ + 1;
  is(eval { Net::IDN::Punycode::PP::encode_punycode() }, undef,
    'encode_punycode without arguments dies');
  like($@, qr/^Usage:/, 'encode_punycode usage message');
  like($@, qr/ at \Q$0\E line $line\.\n\z/,
    'encode_punycode usage message names the caller');
  is(eval { Net::IDN::Punycode::PP::decode_punycode("a", "b") }, undef,
    'decode_punycode with two arguments dies');
  like($@, qr/^Usage:/, 'decode_punycode usage message for two arguments');
  is(eval { Net::IDN::Punycode::PP::encode_punycode("a", "b") }, undef,
    'encode_punycode with two arguments dies');
  like($@, qr/^Usage:/, 'encode_punycode usage message for two arguments');

  my $near = chr(0x10FE4F).("a" x 3856);
  is(Net::IDN::Punycode::PP::decode_punycode(
      Net::IDN::Punycode::PP::encode_punycode($near)), $near,
    'a delta near the limit before a long basic run round-trips');

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  is(Net::IDN::Punycode::PP::decode_punycode(undef), "",
    'decode_punycode(undef) returns the empty string');
  is(Net::IDN::Punycode::PP::encode_punycode(undef), "",
    'encode_punycode(undef) returns the empty string');
  is(@warnings, 2, 'undef input warns once per call');
  like($warnings[0], qr/uninitialized/, 'the warning names the cause');

  is(Net::IDN::Punycode::PP::decode_punycode(""), "",
    'decode_punycode("") returns the empty string');
}

foreach my $test (@encode_dies)
{
  my ($input, $message, $comment) = @{$test};

  is(eval { Net::IDN::Punycode::PP::encode_punycode($input) }, undef,
    $comment.' (encode_punycode dies)');
  like($@, $message, $comment.' (encode_punycode message)');
}

foreach my $test (@decode_dies)
{
  my ($label, $message, $comment) = @{$test};

  is(eval { Net::IDN::Punycode::PP::decode_punycode($label) }, undef,
    $comment.' (decode_punycode dies)');
  like($@, $message, $comment.' (decode_punycode message)');
}

require Encode;

foreach my $test (@malformed)
{
  my ($bytes, $comment) = @{$test};

  no warnings 'utf8';
  Encode::_utf8_on($bytes);
  my $line = __LINE__ + 1;
  is(eval { Net::IDN::Punycode::PP::encode_punycode($bytes) }, undef,
    $comment.' (encode_punycode dies)');
  like($@, qr/malformed UTF-8/, $comment.' (encode_punycode message)');
  like($@, qr/ at \Q$0\E line $line\.\n\z/,
    $comment.' (encode_punycode names the caller)');
  $line = __LINE__ + 1;
  is(eval { Net::IDN::Punycode::PP::decode_punycode($bytes) }, undef,
    $comment.' (decode_punycode dies)');
  like($@, qr/non-base character/, $comment.' (decode_punycode message)');
  like($@, qr/ at \Q$0\E line $line\.\n\z/,
    $comment.' (decode_punycode names the caller)');
}

{
  package Flip;
  use overload '""' => sub { $_[0]{calls}++ ? $_[0]{second} : $_[0]{first} },
    fallback => 1;
}

{
  no warnings 'utf8';
  my $bad = "abc\xE2\x82";
  Encode::_utf8_on($bad);
  my $flip = bless { first => "abc", second => $bad, calls => 0 }, 'Flip';
  is(Net::IDN::Punycode::PP::encode_punycode($flip), "abc-",
    'encode_punycode stringifies an object once');
  $flip = bless { first => "abc-", second => $bad, calls => 0 }, 'Flip';
  is(Net::IDN::Punycode::PP::decode_punycode($flip), "abc",
    'decode_punycode stringifies an object once');
}
