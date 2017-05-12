use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

is_deeply([$xref->packages],
          [
           "A",
           "A::X",
           "A::Y",
           "B",
           "C",
           "D",
           "E",
           "F",
          ],
         "packages");

done_testing();
