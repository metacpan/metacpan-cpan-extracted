use strict;
use Test::More tests => 34;

BEGIN { use_ok('Physics::Unit::Scalar') };


my $d = new Physics::Unit::Distance('98000000 mi');
ok(defined $d,   "new Physics::Unit::Distance");
is(ref($d), 'Physics::Unit::Distance', 'Distance type');

my $s = new Physics::Unit::Speed('45mi/fortnight');
ok(defined $s,   "new Physics::Unit::Speed");
is(ref($s), 'Physics::Unit::Speed', 'Speed type');

my $m = new Physics::Unit::Mass('205lbm');
ok(defined $s,   "new Physics::Unit::Mass");
is(ref($m), 'Physics::Unit::Mass', 'Mass type');

my $a = new Physics::Unit::Acceleration('205 furlongs/fortnight^2');
ok(defined $s,   "new Physics::Unit::Acceleration");
is(ref($a), 'Physics::Unit::Acceleration', 'Acceleration type');

my $i = new Physics::Unit::Time('205 score');
ok(defined $s,   "new Physics::Unit::Time");
is(ref($i), 'Physics::Unit::Time', 'Time type');


$d = new Physics::Unit::Distance('98 mi');
my $dstr = $d->ToString;
like($dstr, '/^157715\.71\d* meter$/', '98 mi');

$d->add('10 km');
$dstr = $d->ToString;
like($dstr, '/^167715\.71\d* meter$/', '98 mi + 10 km');

is($d->value, 167715.712, '98 mi + 10 km == 167715.712');
is($d->default_unit->name, 'meter', 'distance default unit');


$dstr = $d->ToString('mile');
like($dstr, '/^104\.21371192237\d* mile$/', '98 mi + 10 km == 104.. mile');


my $dv = $d->convert('mile');
like($dv, qr/104\.213711922373\d*/, '98 mi + 10 km value in miles');


my $d2 = new Physics::Unit::Distance('2000');
is($d2->ToString, '2000 meter', '2000 meter');


# Manipulate Times

my $t = Physics::Unit::Time->new('36 years');
is($t->ToString, '1136073600 second', '36 years');


# Compute a Speed = Distance / Time

my $speed = $d->divide($t);
is(ref $speed, 'Physics::Unit::Speed',
   'Speed type determined automagically');

my $sstr = $speed->ToString;
like($sstr, '/^0.00014762750582\d* mps$/', 'speed');



# Try to create an object, with a bad definition string
eval q($d = new Physics::Unit::Time('3m'););
my $errmsg = $@;
ok($errmsg, 'bad definition string');


# Construct a Physics::Unit::Distance - the class is
# determined automagically

$d = new Physics::Unit::Scalar('3m');
ok(defined $d,   "new Physics::Unit::Scalar(3m)");
is(ref($d), 'Physics::Unit::Distance', 'Distance type auto-gen');

# Create a Scalar with an unknown dimensionality
$s = new Physics::Unit::Scalar('kg m s');
is($s->ToString, '1000 m gm s', '1000 m gm s');


my $f = $s->divide('3000 s^3');   # $f is a Physics::Unit::Force
ok(defined $f,   "Physics::Unit::Force");
is(ref($f), 'Physics::Unit::Force', 'Force type');
like($f->ToString, '/^0\.00033333333333\d* newton$/', 'Force ToString');


# From the example in the Scalar documentation, new() method:

# This creates an object of a derived class
$d = new Physics::Unit::Distance('3 miles');
is(ref $d, 'Physics::Unit::Distance', 'object of a derived class');

# This does the same thing, type is figured out automagically
# $d will be a Physics::Unit::Distance
$d = new Physics::Unit::Scalar('3 miles');
is(ref $d, 'Physics::Unit::Distance', 'Distance figured automagically');


# Use the default unit for the subtype (for Distance, it's meters):
$d = new Physics::Unit::Distance(10);
is($d->ToString, '10 meter', '10 meter');

# This defaults to one meter:
$d = new Physics::Unit::Distance;
is($d->ToString, '1 meter', '1 meter');

# Copy constructor:
$d2 = $d->new;
is(ref $d, 'Physics::Unit::Distance', 'Distance copy constructor');
is($d->ToString, '1 meter', '1 meter');

