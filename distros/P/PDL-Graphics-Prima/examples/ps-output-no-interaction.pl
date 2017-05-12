use strict;
use warnings;
use PDL;
use PDL::Graphics::Prima;
use PDL::NiceSlice;

# This script generates png output without pulling up the GUI interface.
# The actual plot is stolen from test-error-bars

my $N_points = $ARGV[0] || 30;

my $plot = Prima::Plot->create(
	-data => ds::Pair(
		3 * grandom($N_points), 3 * grandom($N_points),
		plotTypes => [
			ppair::ErrorBars(y_err => grandom($N_points), colors => cl::LightRed,
				x_left_err => grandom($N_points), x_err => grandom($N_points)),
			ppair::Blobs(radius => 4),
		]
	),
	x => 'x data',
	y => 'y data',
	title => 'test',
	size => [640, 480],
);

$plot->save_to_postscript('test.ps');
