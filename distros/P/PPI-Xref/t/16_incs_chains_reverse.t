use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my $ici = $xref->incs_chains_iter({reverse_chains => 1});
ok($ici, "incs_chains_iter");
my @ic;
while (my $ic = $ici->next) {
  push @ic, $ic->string;
}

is_deeply(\@ic,
          [
           "$lib/A.pm\t2\t$lib/B.pm",
           "$lib/A.pm\t4\t$lib/B.pm",
           "$lib/F.pm\t3\t$lib/E.pm\t1\t$lib/f.pl\t2\t$lib/E.pm\t8\t$lib/B.pm",
           "$lib/g.pl\t3\t$lib/f.pl\t2\t$lib/E.pm\t8\t$lib/B.pm",
          ],
         "incs_chains_reverse");

done_testing();
