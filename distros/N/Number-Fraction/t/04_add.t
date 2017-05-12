use Test::More tests => 11;
use Number::Fraction ':constants';

my $f = '1/2';
my $f2 = '1/4';

ok($f + $f2 eq '3/4');
ok($f + $f2 == 0.75);
ok($f + '1/4' eq '3/4');
ok($f + '1/4' == 0.75);
ok('1/4' + $f eq '3/4');
ok('1/4' + $f == 0.75);
ok('1/2' + '4/8' eq '1/1');
ok('1/2' + '4/8' == 1);
ok($f + 0.25 == 0.75);
ok($f + 1 == 1.5);
$f = eval { $f + [] };
ok($@);
