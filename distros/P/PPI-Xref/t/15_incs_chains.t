use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my $ici = $xref->incs_chains_iter;
ok($ici, "incs_chains_iter");
my @ic;
while (my $ic = $ici->next) {
  push @ic, $ic->string;
}

is_deeply(\@ic,
          [
           "$lib/B.pm\t2\t$lib/A.pm",
           "$lib/B.pm\t4\t$lib/A.pm",
           "$lib/B.pm\t8\t$lib/E.pm\t2\t$lib/f.pl\t1\t$lib/E.pm\t3\t$lib/F.pm",
           "$lib/B.pm\t8\t$lib/E.pm\t2\t$lib/f.pl\t3\t$lib/g.pl",
          ],
         "incs_chains");

done_testing();
