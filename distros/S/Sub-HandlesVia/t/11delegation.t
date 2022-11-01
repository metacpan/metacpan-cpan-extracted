use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{ package Local::Dummy1; use Test::Requires 'Moo' };

{
	package Local::Wheel;
	use Moo;
	has colour => (is => 'bare', default => 'black');
	sub spin { 'spinning' }
}

{
	package Local::Unicycle;
	use Moo;
	use Sub::HandlesVia;
	use Types::Standard qw( Object );
	has wheel => (
		is        => 'bare',
		isa       => Object,
		traits    => ['Hash'],
		handles   => {
			spin         => 'spin',
			wheel_ref    => [ sub { join '|', map ref, @_ }, [] ],
			wheel_colour => [ get => 'colour' ],
			hack         => 'Code->execute',
		},
		default   => sub { Local::Wheel->new },
	);
}

my $unicycle = Local::Unicycle->new;

die if eval { $unicycle->wheel };
die if eval { $unicycle->{wheel}->colour };

for my $method (qw/spin wheel_ref wheel_colour/) {
	local $Data::Dumper::Deparse = 1;
	note "==== Local::Unicycle::$method ====";
	note explain( $unicycle->can($method) );
}

is(
	$unicycle->spin,
	'spinning',
);

is(
	$unicycle->wheel_ref({}),
	'Local::Wheel|ARRAY|HASH',
);

is(
	$unicycle->wheel_colour,
	'black',
);

$unicycle->{wheel} = sub { 'yay' };
is(
	$unicycle->hack,
	'yay',
);

{
	package Local::Bike;
	use Moo;
	use Sub::HandlesVia;
	use Types::Standard qw( Object );
	has front_wheel => (
		is        => 'bare',
		isa       => Object,
		traits    => ['Blessed'],
		handles   => {
			spin_front   => 'spin',
			colour_front => [ 'Hash->get' => 'colour' ],
			bleh         => '123foo',
		},
		default   => sub { Local::Wheel->new },
	);
	has back_wheel => (
		is        => 'bare',
		isa       => Object,
		traits    => ['Blessed'],
		handles   => {
			spin_back    => 'spin',
			colour_back  => [ 'Hash->get' => 'colour' ],
		},
		default   => sub { Local::Wheel->new },
	);
}

{
	no strict 'refs';
	*{'Local::Wheel::123foo'} = sub { 'wow' };
}

my $bike = Local::Bike->new;
is( $bike->spin_front,   'spinning' );
is( $bike->spin_back,    'spinning' );
is( $bike->colour_front, 'black' );
is( $bike->colour_back,  'black' );
is( $bike->bleh,         'wow' );

for my $method (qw/spin_front spin_back colour_front colour_back bleh/) {
	local $Data::Dumper::Deparse = 1;
	note "==== Local::Bike::$method ====";
	note explain( $bike->can($method) );
}

done_testing;
