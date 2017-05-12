use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my $ifi = $xref->incs_files_iter;
ok($ifi, "incs_files_iter");
my @if;
while (my $if = $ifi->next) {
  push @if, $if->string;
}

is_deeply(\@if,
          [
           "$lib/B.pm\t2\t$lib/A.pm\tuse\tA",
           "$lib/B.pm\t4\t$lib/A.pm\tno\tA",
           "$lib/B.pm\t8\t$lib/E.pm\trequire\tE",
           "$lib/E.pm\t2\t$lib/f.pl\tdo\tf.pl",
           "$lib/E.pm\t3\t$lib/F.pm\tuse\tF",
           "$lib/f.pl\t1\t$lib/E.pm\tuse\tE",
           "$lib/f.pl\t3\t$lib/g.pl\trequire\tg.pl",
          ],
         "incs_files");

done_testing();
