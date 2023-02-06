use strict;
use warnings;
use PDL;
use Prima qw(Application Buttons);
use PDL::Graphics::Prima;
use PDL::NiceSlice;

my $wDisplay = Prima::MainWindow->create(
	text    => 'Animation',
	size	=> [500, 500],
);

# The plot widget
my $plot;

# The data
my $N_symbols = 200;
my $xs = grandom($N_symbols);
my $ys = grandom($N_symbols);

# variables needed for the timer behavior
my ($dx, $min, $dmin, $max, $N_x_steps, $data_set);
my $x_timer = Prima::Timer->create(
	timeout => 30,
	onTick => sub {
		my $self = shift;
		
		if ($N_x_steps > 0) {
			# Perform the step
			$xs += $dx;
			$min += $dmin;
			$max += $dmin;
			$N_x_steps--;
			$data_set->change_data($xs, $ys);
			$plot->x->minmax($min, $max);
		}
		else {
			# Stop the timer if it's reached the last step
			$self->stop;
		}
	}
);

$wDisplay->insert(Button =>
	pack => {
		anchor => 'nw', fill => 'x',
	},
	text => 'Swap xs',
	onClick => sub {
		($min, $max) = $plot->x->minmax;
		$plot->x->minmax($min, $max);
		$x_timer->start;
		$N_x_steps = 30;
		$dx = -2 * $xs / $N_x_steps;
		$dmin = -($min + $max) / $N_x_steps;
	},
);

my $colors = pal::Rainbow->apply(random($N_symbols));

$data_set = ds::Pair(
	$xs, $ys,
	plotType => ppair::Symbols(
		orientation => 360 * random($N_symbols),
		filled      => (random($N_symbols) > 0.5),
		N_points    => 8 * random($N_symbols),
		skip        => 3 * random($N_symbols),
		colors => $colors,
	),
);
$plot = $wDisplay->insert('Plot',
	-data => $data_set,
	pack => { fill => 'both', expand => 1},
);

run Prima;
