use Test::More tests => 11;
use Number::Fraction ':constants';

my $f = '1/2';
my $f2 = '1/4';

ok($f * $f2 eq '1/8');
ok($f * $f2 == 0.125);
ok($f * '1/4' eq '1/8');
ok($f * '1/4' == 0.125);
ok('1/4' * $f eq '1/8');
ok('1/4' * $f == 0.125);
ok('1/2' * '4/8' eq '1/4');
ok('1/2' * '4/8' == 0.25);
ok($f * 2 == 1);
ok($f * 0.5 == 0.25);
$f = eval { $f * [] };
ok($@);
