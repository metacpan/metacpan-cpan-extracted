use Test::More;

use strict;
use warnings;

use PPI::Xref;

use FindBin qw[$Bin];
require "$Bin/util.pl";
my ($xref, $lib) = get_xref();

ok($xref->process("$lib/B.pm"), "process file");

my $sfi = $xref->subs_files_iter({separator => '|'});
ok($sfi, "subs_files_iter separator");
my @sf;
while (my $sf = $sfi->next) {
    push @sf, $sf->string;
}

is_deeply(\@sf,
          [
           "A::X::a3|$lib/A.pm|6",
           "A::Y::a4|$lib/A.pm|8",
           "A::a1|$lib/A.pm|2",
           "A::a2|$lib/A.pm|3",
           "B::b1|$lib/B.pm|3",
           "B::b2|$lib/B.pm|5",
           "C::c1|$lib/B.pm|7",
           "D::d1|$lib/B.pm|7",
           "D::d2|$lib/B.pm|9",
           "F::f1|$lib/F.pm|2",
           "main::f1|$lib/f.pl|2",
           "main::g1|$lib/g.pl|1",
          ],
          "subs_files separator");

done_testing();
