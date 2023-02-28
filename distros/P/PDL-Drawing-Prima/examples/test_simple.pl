use strict;
use warnings;
;
use PDL;
use Prima qw(Application);

die "You must supply at least two points\n" if @ARGV < 4 or @ARGV % 2 != 0;

my $coords = pdl(join(', ', @ARGV));
my ($start_x, $start_y, $stop_x, $stop_y) = @ARGV;

die "You must supply starting and stopping x- and y-coordinates\n" if not defined $stop_y;

my $wDisplay = Prima::MainWindow->create(
	text    => 'Large Draw Test',
	size	=> [500, 500],
);

$wDisplay->insert(Widget =>
	pack => { fill => 'both', expand => 1},
	color => cl::Black,
	backColor => cl::White,
	onPaint => sub {
		my $self = shift;
		$self->clear;
		$self->line($start_x, $start_y, $stop_x, $stop_y);
	},
);

run Prima;
