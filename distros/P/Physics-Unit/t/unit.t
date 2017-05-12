use Test::More tests => 49;

BEGIN { use_ok('Physics::Unit', (':ALL')) };
my $u;

my $mile = GetUnit('mile');
ok(defined $mile,   "GetUnit('mile')");

my $foot = GetUnit('foot');
my $c = $mile->convert($foot);     # $c == 5280
is($c, 5280, 'a mile is 5280 feet');


# Test that case is not significant in expressions

$ss = new Physics::Unit('FuRlOnG / fOrTnIgHt', 'SiLlY_SpEeD');
is($ss->name, 'silly_speed', 'silly_speed unit');

my $mph = $ss->convert('mph');
like($mph, '/^0.0003720238095\d*$/', 'silly_speed to mph');



# Test all the examples from the Physics::Unit documentation.

# Define your own units
$ss = new Physics::Unit('furlong / fortnight', 'ff');

# test the expanded representation of a unit
like($ss->expanded, '/^0.0001663095238\d* m s\^-1$/', '$ss->expanded');

#---------------------

# Convert from one to another
like($ss->convert('mph'), '/^0.00037202380952\d*$/', '$ss->convert(mph)');

# Get a Unit's conversion factor
is(GetUnit('foot')->factor, 0.3048, 'GetUnit(foot)->factor');

is(GetUnit('mph')->factor, 0.44704, 'GetUnit(mph)->factor');

#---------------------

# Test the equivalence of several units
$u = GetUnit('megaparsec');

ok($u->equal(GetUnit('mega parsec')));
ok($u->equal(GetUnit('kilo kilo parsec')));
ok($u->equal(GetUnit('kilo**2 parsec')));
ok($u->equal(GetUnit('square kilo parsec')));


#---------------------

InitBaseUnit('Beauty' => ['sonja', 'sonjas', 'smw']);
is(GetUnit('sonja')->type, 'Beauty', 'Sonja is beautiful');

#---------------------

InitPrefix('gonzo' => 1e100, 'piccolo' => 1e-100);
is(GetUnit('gonzo')->type, 'prefix', 'Gonzo');

$beauty_rate = new Physics::Unit('5 piccolosonja / hour');
ok(!defined $beauty_rate->type, 'beauty_rate type');

is($beauty_rate->factor, 5 * 1e-100 / 3600, 'beauty_rate->factor');

#---------------------

InitUnit( ['chris', 'cfm'] => '3 piccolosonjas' );
like(GetUnit('cfm')->expanded, '/^3\.?e-100 smw$/', 'not so beautiful');

#---------------------

InitUnit( ['mycron1'], '3600 sec' );
InitUnit( ['mycron2'], 'hour' );
$h = GetUnit('hour');
InitUnit( ['mycron3'], $h );

ok(Physics::Unit->equal('mycron1', 'mycron2'), 'mycron1 == mycron2');
ok(Physics::Unit->equal('mycron1', 'mycron3'), 'mycron1 == mycron3');

#---------------------

InitTypes( 'Aging' => 'chris / year' );
$uname = 'sonja per week';
$u = GetUnit($uname);
is($u->type, 'Aging', 'Aging');

#---------------------

# Create a new, anonymous unit:
$u = new Physics::Unit ('3 pi sonjas per s');
ok(!defined $u->name, 'no name');

# Create a new, named unit:
$u = new Physics::Unit ('3 pi sonjas per s', 'bloom');
is($u->name, 'bloom', 'bloom');

# Create a new unit with a list of names:
$u  = new Physics::Unit ('3 pi sonjas per s', 'b', 'blooms', 'blm');
is($u->name, 'b', 'primary name');

#---------------------

is(GetUnit('rod')->type, 'Distance', 'rod type');

#---------------------

$u1 = new Physics::Unit('kg m^2/s^2');
$t = $u1->type;
@types = sort @$t;
is($types[0], 'Energy', 'Energy');
is($types[1], 'Torque', 'Torque');


$u1->type('Energy');  #  This establishes the type once and for all
$t = $u1->type;
is($t, 'Energy', 'type fixed as Energy');

# . . .

# But if we use a predefined, named unit, we get a single type:
$u3 = GetUnit('joule')->new;    # *not*  Physics::Unit->new('joule');
is($u3->type, 'Energy', 'joule is Energy');

#---------------------

is(GetUnit('calorie')->expanded, '4184 m^2 gm s^-2', 'stuff');

#---------------------

$u = new Physics::Unit('36 m^2');
$u->divide('3 meters');
is($u->expanded, '12 m', '12 m');

$u->divide(3);
is($u->expanded, '4 m', '4 m');

$u->divide( new Physics::Unit('.5 sec') );
is($u->expanded, '8 m s^-1', '8 m s^-1');


# define your own units
$Uforce = new Physics::Unit('3 pi kg*nanoparsecs / femtofortnight sec');
ok(!defined $Uforce->name, '$Uforce->name');
like($Uforce->expanded, qr/2\.40216521602612\d*e\+0*20 m gm s\^-2/, '$Uforce->expanded');

$Uaccl1 = new Physics::Unit('meters per second squared');
ok(!defined $Uaccl1->name, '$Uforce->name');
is($Uaccl1->expanded, 'm s^-2', '$Uaccl1->expanded');

$Uaccl2 = new Physics::Unit('furlong / square score');
ok(!defined $Uaccl2->name, '$Uforce->name');
like($Uaccl2->expanded, qr/5\.04999528589989\d*e-0*16 m s\^-2/, '$Uaccl2->expanded');

# British spelling

my $centimetre = new Physics::Unit('centimetre / second');
my $centimetre_expanded = $centimetre->expanded ();
ok ($centimetre_expanded eq '0.01 m s^-1');

# DeleteNames
my @names;
my $numNames;
my @unitNames;

# FIXME:  Figure out why this doesn't work:
#     my $origNumNames = scalar ListUnits();
my @origNames = ListUnits();
my $origNumNames = scalar @origNames;

$u = GetUnit('kilo');
DeleteNames('kilo');
@names = ListUnits();
ok (scalar @names == $origNumNames - 1, 'Deleted kilo');

@unitNames = $u->names;
ok (scalar @unitNames == 0, 'kilo unit now has no name');
ok (Physics::Unit::LookName('kilo') == 0, "Can't find kilo");

$u = GetUnit('m');
DeleteNames('metre', 'metres');   # Who added these British spellings?
@names = ListUnits();
ok (scalar @names == $origNumNames - 3, 'Deleted British spellings');

@unitNames = $u->names;
ok (scalar @unitNames == 3, 'meter has fewer names');
ok (Physics::Unit::LookName('metre') == 0, "Can't find metre");

$u = GetUnit('microns');
DeleteNames($u);                # argument is a unit object
@names = ListUnits();
ok (scalar @names == $origNumNames - 6, "Fewer and fewer names");

$u = GetUnit('ounces');
DeleteNames(['ounces', 'oz']);  # argument is an array ref
@names = ListUnits();
ok (scalar @names == $origNumNames - 8, "Lost two more names");

@unitNames = $u->names;
ok (scalar @unitNames == 1, "oz is only name left for this unit");


