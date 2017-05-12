use strict;
use warnings;
use PDL;
use Prima qw(Application);
use PDL::Graphics::Prima;
use PDL::NiceSlice;

my $wDisplay = Prima::MainWindow->create(
	text    => 'Symbols Test',
	size	=> [500, 500],
);

my $N_symbols = 200;
my $colors = pal::Rainbow->apply(random($N_symbols));

$wDisplay->insert('Plot',
	-data => ds::Pair(
		3 * grandom($N_symbols), 3 * grandom($N_symbols),
		plotType => ppair::Symbols(
			orientation => 360 * random($N_symbols),
			filled      => (random($N_symbols) > 0.5),
			N_points    => 8 * random($N_symbols),
			skip        => 3 * random($N_symbols),
			colors => $colors,
		),
	),
	pack => { fill => 'both', expand => 1},
);

run Prima;

