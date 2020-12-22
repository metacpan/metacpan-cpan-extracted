use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok 'SVG::Timeline';
}

ok(my $tl = SVG::Timeline->new);
isa_ok($tl, 'SVG::Timeline');

done_testing;
