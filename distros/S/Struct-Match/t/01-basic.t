use Test::More;

use Struct::Match qw/match/;

# scalar
my $m = match 'one', 'one';
is($m, 1);
$m = match 'one', 'two';
is($m, 0);

# array
$m = match ['one', 'two', 'three'], ['one', 'two', 'three'];
is($m, 1);
$m = match ['one', 'two'], ['one', 'three'];
is($m, 0);

#hash
$m = match { one => 'two', three => 'four' }, { one => 'two', three => 'four' };
is($m, 1);
$m = match { one => 'two', three => 'four' }, { one => 'two', three => 'five' };
is($m, 0);

# code 
my $one = sub { 'meh' };
$m = match $one, $one;
is($m, 1);
$m = match $one, sub { 'meh' };
is($m, 0);
# around
$m = match $one, sub { 'meh' }, 1;
is($m, 1);

# object array
# as ref
my $obj = bless [qw/one two/], 'TEST::ARRAY';
$m = match $obj, $obj;
is($m, 1);
# deref
my $obj2 = bless [qw/one two/], 'TEST::ARRAY';
$m = match $obj, $obj2;
is($m, 1);
# no match
my $obj3 = bless [qw/one three/], 'TEST::ARRAY';
$m = match $obj, $obj3;
is($m, 0);

# object hash
# as ref
$obj = bless {qw/one two/}, 'TEST::HASH';
$m = match $obj, $obj;
is($m, 1);
# deref
$obj2 = bless {qw/one two/}, 'TEST::HASH';
$m = match $obj, $obj2;
is($m, 1);
# no match
$obj3 = bless {qw/one three/}, 'TEST::HASH';
$m = match $obj, $obj3;
is($m, 0);

done_testing();
