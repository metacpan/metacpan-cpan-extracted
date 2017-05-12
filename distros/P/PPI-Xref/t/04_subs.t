use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

is_deeply([$xref->subs],
          [
           "A::X::a3",
           "A::Y::a4",
           "A::a1",
           "A::a2",
           "B::b1",
           "B::b2",
           "C::c1",
           "D::d1",
           "D::d2",
           "F::f1",
           "main::f1",
           "main::g1",
          ],
         "subs");

done_testing();
