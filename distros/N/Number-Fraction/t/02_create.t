use Test::More tests => 33;
use Number::Fraction;

my $f = eval {Number::Fraction->new('a', 'b') };
ok($@, 'Two non-digits');

$f = eval { Number::Fraction->new(1, 'c') };
ok($@, 'One non-digit');

$f = eval { Number::Fraction->new([]) };
ok($@, 'Array ref');

$f = Number::Fraction->new('1/2');
cmp_ok(ref $f, 'eq', 'Number::Fraction', 'String: 1/2');
cmp_ok($f, 'eq', '1/2', '... as a string');
cmp_ok($f, '==', 0.5, '... as a number');

$f = Number::Fraction->new(1, 2);
cmp_ok(ref $f, 'eq', 'Number::Fraction', 'Two digits');
cmp_ok($f, 'eq', '1/2', '... as a string');
cmp_ok($f, '==', 0.5, '... as a number');

my $f1 = Number::Fraction->new($f);
cmp_ok(ref $f1, 'eq', 'Number::Fraction', 'Number::Fraction');
cmp_ok($f1, 'eq', '1/2', '... as a string');
cmp_ok($f1, '==', 0.5, '... as a number');

$f1 = Number::Fraction->new;
cmp_ok(ref $f1, 'eq', 'Number::Fraction', 'Empty constructor');
cmp_ok($f1, 'eq', '0', '... as a string');
cmp_ok($f1, '==', 0, '... as a number');

my $f2 = Number::Fraction->new(4, 8);
cmp_ok(ref $f2, 'eq', 'Number::Fraction', 'Two more digits');
cmp_ok($f2, 'eq', '1/2', '... as a string');
cmp_ok($f2, '==', 0.5, '... as a number');

$f2 = Number::Fraction->new('4/8');
cmp_ok(ref $f2, 'eq', 'Number::Fraction', 'String: 4/8');
cmp_ok($f2, 'eq', '1/2', '... as a string');
cmp_ok($f2, '==', 0.5, '... as a number');

my $f3 = Number::Fraction->new(2, 1);
cmp_ok(ref $f3, 'eq', 'Number::Fraction', 'Another two digits');
cmp_ok($f3, 'eq', '2', '... as a string');
cmp_ok($f3, '==', 2, '... as a number');

$f3 = Number::Fraction->new('2/1');
cmp_ok(ref $f3, 'eq', 'Number::Fraction', 'String: 2/1');
cmp_ok($f3, 'eq', '2', '... as a string');
cmp_ok($f3, '==', 2, '... as a number');

$f3 = Number::Fraction->new(2);
cmp_ok(ref $f3, 'eq', 'Number::Fraction', 'Another Number::Fraction');
cmp_ok($f3, 'eq', '2', '... as a string');
cmp_ok($f3, '==', 2, '... as a number');

$f3 = Number::Fraction->new('2');
cmp_ok(ref $f3, 'eq', 'Number::Fraction', 'One more digit');
cmp_ok($f3, 'eq', '2', '... as a string');
cmp_ok($f3, '==', 2, '... as a number');
