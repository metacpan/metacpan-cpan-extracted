use strict;
use utf8;
use warnings;

use Test::More;
use Net::IDN::Punycode ();
use Net::IDN::Punycode::PP ();

BEGIN {
  plan skip_all => 'no XS version' if eval {
    \&Net::IDN::Punycode::decode_punycode ==
    \&Net::IDN::Punycode::PP::decode_punycode; }
}

BEGIN {
  plan skip_all => 'Test::LeakTrace required'
    unless eval { require Test::LeakTrace; Test::LeakTrace->import; 1 }
}

use Test::NoWarnings;

no warnings 'utf8';    # perl 5.12 and older warn on the fixtures below

our @calls = (
  ["b\x{fc}cher", \&Net::IDN::Punycode::encode_punycode,
    "successful encode"],
  ["bcher-kva", \&Net::IDN::Punycode::decode_punycode,
    "successful decode"],
  [("a" x 3855).chr(0x10FFFF), \&Net::IDN::Punycode::encode_punycode,
    "encode croaking on the delta guard"],
  [("a" x 4368).chr(983183), \&Net::IDN::Punycode::encode_punycode,
    "encode croaking on the skipped basic code point guard"],
  ["a".chr(0x110000), \&Net::IDN::Punycode::encode_punycode,
    "encode croaking on a code point above Unicode"],
  ["a".chr(0xD800), \&Net::IDN::Punycode::encode_punycode,
    "encode croaking on a surrogate code point"],
  ["a-99999999999999999999", \&Net::IDN::Punycode::decode_punycode,
    "decode croaking on the digit weight guard"],
  ["\x80", \&Net::IDN::Punycode::decode_punycode,
    "decode croaking on a non-base character"],
  ["a-9", \&Net::IDN::Punycode::decode_punycode,
    "decode croaking on an incomplete encoded code point"],
  ["a-!", \&Net::IDN::Punycode::decode_punycode,
    "decode croaking on an invalid digit"],
  ["a-kk503321e", \&Net::IDN::Punycode::decode_punycode,
    "decode croaking on the delta accumulator guard"],
  ["a-j023p", \&Net::IDN::Punycode::decode_punycode,
    "decode croaking on a code point above Unicode"],
  ["ib9b", \&Net::IDN::Punycode::decode_punycode,
    "decode croaking on a surrogate code point"],
);

use warnings 'utf8';

plan tests => 1 + 1 * (scalar @calls) + 1;

foreach my $test (@calls)
{
  my ($input, $function, $comment) = @{$test};

  no_leaks_ok(sub {
    eval { $function->($input) }
  }, $comment.' leaks no memory');
}

{
  use warnings FATAL => 'utf8';
  require Encode;
  my $bytes = "abc\xE2\x82";
  Encode::_utf8_on($bytes);
  no_leaks_ok(sub {
    eval { Net::IDN::Punycode::encode_punycode($bytes) }
  }, 'encode croaking on malformed UTF-8 leaks no memory');
}
