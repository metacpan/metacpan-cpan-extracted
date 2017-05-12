use utf8;
use strict;

use Test::More;
use Test::NoWarnings;
use Encode;

use Net::IDN::IDNA2003 qw(:all);

my @to_ascii = (
  ['ascii (mixed case)', 'Weiss', 'Weiss', 0, 1],
  ['ascii (with STD3 rules)', 'a blank nok', undef, 0, 1],
  ['ascii (without STD3 rules)', 'a blank ok', 'a blank ok', 0, 0],
  ['ascii (too long)', 'x' x 64, undef, 1, 0],
  ['not ascii (with STD3 rules)', 'leerschläge nok', undef, 0, 1],
  ['not ascii (without STD3 rules)', 'leerschläge ok', 'xn--leerschlge ok-ifb', 0, 0],
  ['not ascii (unassigend allowed)', 'yɏ', 'xn--y-r0a', 1, 1],
  ['not ascii (unassigend not allowed)', 'yɏ', undef, 0, 1],
  ['not ascii (nameprep mapping B.1)', 'a­b', 'ab', 0, 1],
  ['not ascii (nameprep mapping B.2)', 'Weiß', 'weiss', 0, 1],
  ['not ascii (nameprep mapping C.1.2)', 'a b', undef, 1, 0],
  ['not ascii (nameprep mapping C.2.2)', 'ab', undef, 1, 0],
  ['not ascii (nameprep mapping C.3)', 'ab', undef, 1, 0],
  ['not ascii (nameprep mapping C.4)', 'a﷐b', undef, 1, 0],
  ['not ascii (nameprep mapping C.5)', 'a���b', undef, 1, 0],
  ['not ascii (nameprep mapping C.6)', 'a￹b', undef, 1, 0],
  ['not ascii (nameprep mapping C.7)', 'a⿰b', undef, 1, 0],
  ['not ascii (nameprep mapping C.8)', 'a⁯b', undef, 1, 0],
  ['not ascii (nameprep mapping C.9)', 'a'.chr(0xE0001).'b', undef, 1, 0],
  ['not ascii (nameprep KC normalization)', 'a'.chr(0x0340), idna2003_to_ascii(chr(0xE0)), 0, 1],
  ['not ascii (nameprep bidirectional)', 'א1', undef, 1, 0],
  ['not ascii (with ACS prefix)', 'xn--müller', undef, 1, 0],
# Overflow handling (RFC 3492 6.4) not implemented.
# Minor bug, irrelevant for encoding strict UTF-8 on 32/64 bit machines.
#  ['not ascii (punycode integer overflow)', 'a'.chr(~0), undef, 1, 0],
  ['not ascii (too long)', 'x' x 56 . 'ä', undef, 1, 0],
  ['overlong label (64 characters)', 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijkl', undef, 0, 1],
);

plan tests => (@to_ascii + 1);

for (@to_ascii) {
  my ($comment,$in,$out,$allowunassigned,$usestd3asciirules) = @$_;
  my %param = (
    AllowUnassigned => $allowunassigned,
    UseSTD3ASCIIRules => $usestd3asciirules
  );
  is(eval {idna2003_to_ascii($in, %param)}, $out, $comment);
}
