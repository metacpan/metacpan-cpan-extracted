
use FindBin qw/$Bin/;
use Test::More;

use Schedule::Pluggable;
my $no_tests = 0;
ok($ps = Schedule::Pluggable->new, "Instatiated Object");
$no_tests++;
ok($ps->run_in_series([ qq!$Bin/succeed.pl! ]), "One Job");
$no_tests++;
done_testing( $no_tests );
