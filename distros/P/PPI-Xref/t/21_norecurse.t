use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref({recurse => 0});

ok($xref->process("$lib/B.pm"), "process file");

is_deeply([$xref->files],
          [
           "$lib/A.pm",
           "$lib/B.pm",
           "$lib/E.pm",
           # But no "$lib/F.pm".
          ],
         "files norecurse");

is_deeply([$xref->subs],
          [
           "B::b1",
           "B::b2",
           "C::c1",
           "D::d1",
           "D::d2",
          ],
         "subs norecurse");

done_testing();
