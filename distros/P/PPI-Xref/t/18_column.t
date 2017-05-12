use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my $sfi = $xref->subs_files_iter({column => 1});
ok($sfi, "subs_files_iter column");
my @sf;
while (my $sf = $sfi->next) {
    push @sf, $sf->string;
}

is_deeply(\@sf,
          [
           "A::X::a3\t$lib/A.pm\t6\t1",
           "A::Y::a4\t$lib/A.pm\t8\t5",
           "A::a1\t$lib/A.pm\t2\t1",
           "A::a2\t$lib/A.pm\t3\t1",
           "B::b1\t$lib/B.pm\t3\t1",
           "B::b2\t$lib/B.pm\t5\t1",
           "C::c1\t$lib/B.pm\t7\t1",
           "D::d1\t$lib/B.pm\t7\t21",
           "D::d2\t$lib/B.pm\t9\t13",
           "F::f1\t$lib/F.pm\t2\t1",
           "main::f1\t$lib/f.pl\t2\t1",
           "main::g1\t$lib/g.pl\t1\t1",
          ],
          "subs_files column");

done_testing();
