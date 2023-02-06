use strict;
use warnings;
use PDL;
use PDL::Graphics::Prima::Simple;

my $x = sequence(100)/10 + 0.1;
my $y = sin($x);
auto_twiddle(0);
my $main = plot(
	-data => ds::Pair($x, sin $x),
	title => 'Sine Wave',
);

$main->insert(Plot =>
	place => {
		relx => 0.65, rely => 0.65, relheight => 0.25, relwidth => 0.25,
		anchor => 'sw',
	},
	-data => ds::Pair($x, cos $x),
	title => 'Cosine Wave',
	x => {
		scaling => sc::Log,
	},
);
twiddle();
