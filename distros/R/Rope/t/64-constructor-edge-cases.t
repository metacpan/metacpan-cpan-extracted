use Test::More;

use Rope (no_import => 1);

{
	package ConstructEdge;

	use Rope;

	property name => (
		value => 'default',
		initable => 1,
		writeable => 1,
		enumerable => 1,
	);

	property fixed => (
		value => 'cannot init',
		initable => 0,
		writeable => 0,
		enumerable => 0,
	);

	property age => (
		initable => 1,
		writeable => 1,
		enumerable => 1,
		builder => sub {
			return 25;
		}
	);

	1;
}

# new with hashref instead of list
my $k = ConstructEdge->new({ name => 'hashref' });
is($k->{name}, 'hashref', 'new accepts hashref');

# new with list
my $k2 = ConstructEdge->new(name => 'list');
is($k2->{name}, 'list', 'new accepts list');

# error: trying to init non-initable property
eval {
	ConstructEdge->new(fixed => 'override');
};
like($@, qr/Cannot initalise Object \(ConstructEdge\) property \(fixed\) as initable is not set to true/,
	'non-initable property rejects init');

# builder provides default when no value given
my $k3 = ConstructEdge->new();
is($k3->{age}, 25, 'builder provides default value');

# builder is overridden by initable value
my $k4 = ConstructEdge->new(age => 30);
is($k4->{age}, 30, 'initable value overrides builder');

# new properties can be added dynamically via constructor
my $k5 = ConstructEdge->new(name => 'dynamic', extra => 'bonus');
is($k5->{extra}, 'bonus', 'unknown params create new writeable properties');
$k5->{extra} = 'updated';
is($k5->{extra}, 'updated', 'dynamically added property is writeable');

# get_initialised
{
	package InitTrack;

	use Rope;

	prototyped (
		val => 42,
	);

	1;
}

my $obj = InitTrack->new();
my $id = ${$obj}->{identifier};
my $init = Rope->get_initialised('InitTrack', $id);
ok($init, 'get_initialised returns the object');
is($init->{val}, 42, 'get_initialised object has correct value');

done_testing();
