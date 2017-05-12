use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my $sfi = $xref->subs_files_iter({column => 1, finish => 1});
ok($sfi, "subs_files_iter column finish");
my @sf;
while (my $sf = $sfi->next) {
    push @sf, $sf->string;
}

is_deeply(\@sf,
          [
           "A::X::a3\t$lib/A.pm\t6\t1\t6\t9",
           "A::Y::a4\t$lib/A.pm\t8\t5\t8\t13",
           "A::a1\t$lib/A.pm\t2\t1\t2\t9",
           "A::a2\t$lib/A.pm\t3\t1\t4\t1",
           "B::b1\t$lib/B.pm\t3\t1\t3\t9",
           "B::b2\t$lib/B.pm\t5\t1\t5\t9",
           "C::c1\t$lib/B.pm\t7\t1\t7\t31",
           "D::d1\t$lib/B.pm\t7\t21\t7\t29",
           "D::d2\t$lib/B.pm\t9\t13\t9\t21",
           "F::f1\t$lib/F.pm\t2\t1\t2\t9",
           "main::f1\t$lib/f.pl\t2\t1\t2\t9",
           "main::g1\t$lib/g.pl\t1\t1\t1\t9",
          ],
          "subs_files column finish");

done_testing();
