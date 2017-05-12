use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my @mc;
for my $m ($xref->modules) {
  push @mc, "$m\t" . $xref->module_count($m);
}

is_deeply(\@mc,
          [
           "A\t2",
           "E\t2",
           "F\t1",
          ],
         "modules_counts");

done_testing();
