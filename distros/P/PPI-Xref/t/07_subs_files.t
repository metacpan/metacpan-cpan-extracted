use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my $sfi = $xref->subs_files_iter;
ok($sfi, "subs_files_iter");
my @sf;
while (my $sf = $sfi->next) {
  push @sf, $sf->string;
}

is_deeply(\@sf,
          [
           "A::X::a3\t$lib/A.pm\t6",
           "A::Y::a4\t$lib/A.pm\t8",
           "A::a1\t$lib/A.pm\t2",
           "A::a2\t$lib/A.pm\t3",
           "B::b1\t$lib/B.pm\t3",
           "B::b2\t$lib/B.pm\t5",
           "C::c1\t$lib/B.pm\t7",
           "D::d1\t$lib/B.pm\t7",
           "D::d2\t$lib/B.pm\t9",
           "F::f1\t$lib/F.pm\t2",
           "main::f1\t$lib/f.pl\t2",
           "main::g1\t$lib/g.pl\t1",
          ],
         "subs_files");

done_testing();
