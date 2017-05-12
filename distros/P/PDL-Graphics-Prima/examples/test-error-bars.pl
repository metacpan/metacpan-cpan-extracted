use strict;
use warnings;
use PDL;
use Prima qw(Application);
use PDL::Graphics::Prima;
use PDL::NiceSlice;

my $N_points = $ARGV[0] || 30;

my $wDisplay = Prima::MainWindow->create(
	text    => 'Error Bar Test',
	size	=> [500, 500],
);

$wDisplay->insert('Plot',
	-data => ds::Pair(
		3 * grandom($N_points), 3 * grandom($N_points),
		plotTypes => [
			ppair::ErrorBars(y_err => grandom($N_points), color => cl::LightRed,
				x_left_err => grandom($N_points), x_err => grandom($N_points)),
			ppair::Blobs(radius => 4),
		]
	),
	pack => { fill => 'both', expand => 1},
	x => {
		label => 'x data',
	},
	y => {
		label => 'y data',
	},
	title => 'test',
);

run Prima;

