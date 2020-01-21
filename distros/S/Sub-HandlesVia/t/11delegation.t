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

#require B::Deparse;
#for my $method (qw/ spin wheel_ref wheel_colour /) {
#	diag("sub $method");
#	diag(B::Deparse->new->coderef2text($unicycle->can($method)));
#}

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


done_testing;
