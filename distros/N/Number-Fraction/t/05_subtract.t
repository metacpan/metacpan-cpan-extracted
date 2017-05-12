use Test::More tests => 13;
use Number::Fraction ':constants';

my $f = '1/2';
my $f2 = '1/4';

ok($f - $f2 eq '1/4');
ok($f - $f2 == 0.25);
ok($f - '1/4' eq '1/4');
ok($f - '1/4' == 0.25);
ok('1/2' - $f2 eq '1/4');
ok('1/2' - $f2 == 0.25);
ok('1/2' - '4/8' eq '0');
ok('1/2' - '4/8' == 0);
ok($f - 0.25 == 0.25);
ok($f - -1 == 1.5);
ok(1.5 - $f == 1);
ok(1   - $f == 0.5);
$f = eval { $f - [] };
ok($@);
