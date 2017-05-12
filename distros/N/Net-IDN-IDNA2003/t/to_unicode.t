use utf8;
use strict;

use Test::More;
use Test::NoWarnings;

use Net::IDN::IDNA2003 qw(:all);

my @to_unicode = (
  ['Invalid deltas', 'xn--oops', 'xn--oops', 0, 1],
  ['blank (with STD3 rules)', 'xn--ml er-kva', 'xn--ml er-kva', 0, 1],
  ['blank (without STD3 rules)', 'xn--ml er-kva', 'mül er', 0, 0],
  ['unassigned (unassigned allowed)', 'xn--y-r0a', 'yɏ', 1, 1],
  ['unassigned (unassigned not allowed)', 'xn--y-r0a', 'xn--y-r0a', 0, 1],
  ['arbitrary unicode string (unassigend not allowed, without STD3 rules)0 0', 'yɏ ', 'yɏ ', 0, 0],
  ['arbitrary unicode string (unassigend not allowed, with STD3 rules)0 1', 'yɏ ', 'yɏ ', 0, 1],
  ['arbitrary unicode string (unassigend allowed, without STD3 rules)1 0', 'yɏ ', 'yɏ ', 1, 0],
  ['arbitrary unicode string (unassigend allowed, with STD3 rules)1 1', 'yɏ ', 'yɏ ', 1, 1],
  ['arbitrary ascii string (unassigend not allowed, without STD3 rules)', '-,!@;]{)	', '-,!@;]{)	', 0, 0],
  ['arbitrary ascii string (unassigend not allowed, with STD3 rules)', '-,!@;]{)	', '-,!@;]{)	', 0, 1],
  ['arbitrary ascii string (unassigend allowed, without STD3 rules)', '-,!@;]{)	', '-,!@;]{)	', 1, 0],
  ['arbitrary ascii string (unassigend allowed, with STD3 rules)', '-,!@;]{)	', '-,!@;]{)	', 1, 1],
  ['empty string', '', '', 0, 1],
  ['no basic code point', 'xn--4ca0bs', 'äöü', 0, 1],
  ['bad trailing hyphen', 'xn--kva-', 'xn--kva-', 0, 1],
  ['bad leading hyphen', 'xn---4ca0bs', 'xn---4ca0bs', 0, 1],
  ['hyphen in the middle', 'xn--jrg-mller-q9ae', 'jürg-müller', 0, 1],
  ['encoded leading/trailing hyphens (without STD3 rules)', 'xn---h!?--gra', '-äh!?-', 0, 0],
  ['encoded leading/trailing hyphens (with STD3 rules)', 'xn---h!?--gra', 'xn---h!?--gra',0 , 1],
  ['nameprep', 'xn--Weiß und Grn-7ob', 'weiss und grün', 0, 0],
  ['encoded upper case (with nameprep)', 'xn--Weiß und GRN-fcb', 'xn--Weiß und GRN-fcb', 0, 0],
  ['encoded upper case (without nameprep)', 'xn--Weiss und GRN-fcb', 'xn--Weiss und GRN-fcb', 0, 0],
);

plan tests => (@to_unicode + 1);

for (@to_unicode) {
  my ($comment,$in,$out,$allowunassigned,$usestd3asciirules) = @$_;
  my %param = (
    AllowUnassigned => $allowunassigned,
    UseSTD3ASCIIRules => $usestd3asciirules
  );
  is(idna2003_to_unicode($in, %param), $out, $comment);
}
