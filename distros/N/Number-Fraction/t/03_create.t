use Test::More tests => 5;
use Number::Fraction ':constants';

my $f = '1/2';
cmp_ok(ref $f, 'eq', 'Number::Fraction', 'Create from string');
cmp_ok($f, 'eq', '1/2', 'Created correct string');
cmp_ok($f, '==', 0.5, 'Created correct number');

no Number::Fraction;
$f = '1/2';
ok(!ref $f, 'Fail to create from string');

use Number::Fraction ':something';
$f = '1/2';
ok(!ref $f, 'Still fail to create from string');

