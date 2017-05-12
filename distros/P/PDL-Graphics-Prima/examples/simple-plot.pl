use strict;
use warnings;
use PDL;
use PDL::Graphics::Prima::Simple;

my $xs = sequence(100)/10;
my $ys = sin($xs) + 3 * sequence(3)->transpose;
my $colors = pal::Rainbow->apply(sequence(3)->transpose);
plot(
	-data => ds::Pair($xs, $ys,
		plotType => [
			ppair::Diamonds,
			ppair::Lines(thread_like => 'points'),
		],
		colors => $colors,
	),
);

plot(
	-data => ds::Pair($xs, $ys,
		color => cl::LightGreen,
	)
);

plot(
	-data => ds::Pair($xs, $ys),
	color => cl::LightGreen,
);
