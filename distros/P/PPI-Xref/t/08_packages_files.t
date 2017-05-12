use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my $pfi = $xref->packages_files_iter;
ok($pfi, "packages_files_iter");
my @pf;
while (my $pf = $pfi->next) {
  push @pf, $pf->string;
}

is_deeply(\@pf,
          [
           "A\t$lib/A.pm\t1",
           "A::X\t$lib/A.pm\t5",
           "A::Y\t$lib/A.pm\t7",
           "B\t$lib/B.pm\t1",
           "C\t$lib/B.pm\t6",
           "C\t$lib/B.pm\t7",
           "D\t$lib/B.pm\t7",
           "D\t$lib/B.pm\t9",
           "E\t$lib/E.pm\t1",
           "F\t$lib/F.pm\t1",
          ],
         "packages_files");

done_testing();
