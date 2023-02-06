use strict;
use warnings;
use PDL;
use Prima qw(Application InputLine);
use PDL::Graphics::Prima;
use PDL::NiceSlice;

##########################################################
# Utility function to make it easy to slowly push values #
##########################################################

sub PDL::cycle_push {
	my ($self, $value) = @_;
	
	# retrieve the current offset and take the next step
	my $curr_offset = $self->hdr->{push_offset} || 0;
	$curr_offset++;
	$curr_offset = 0 if $curr_offset == $self->nelem;
	
	# Store the value
	$self->set($curr_offset, $value);
	
	# Update the position
	$self->hdr->{push_offset} = $curr_offset;
}

sub PDL::uncycle {
	my $self = shift;
	return $self->rotate(-$self->hdr->{push_offset} - 1);
}

########################
# Buld the application #
########################

my $window = Prima::MainWindow->create(
	text    => 'Animation',
	size	=> [500, 600],
);

my $freq = 2;
use Scalar::Util qw(looks_like_number);
my $input_line = $window->insert(InputLine =>
	text => $freq,
	pack => {
		side => 'top', fill => 'x', anchor => 'sw', pady => 10,
	},
	onKeyUp => sub {
		my $self = shift;
		my $new_value = $self->text;
		if (looks_like_number($new_value)) {
			$freq = $new_value;
			$self->backColor(cl::White);
		}
		else {
			$self->backColor(cl::Yellow);
		}
	}
);

my $ys = zeroes(200)->setvaltobad(0);
my $xs = $ys->copy;
$ys->cycle_push(0);
$xs->cycle_push(0);

# The plot widget
my $plot = $window->insert(Plot =>
	pack => {
		side => 'top', fill => 'both', anchor => 'sw', expand => 1,
	},
	-data => ds::Pair($xs, $ys, plotType => ppair::Lines),
);

my $dt = 0.05;
my $total_phase = 0;
my $t = 0;

Prima::Timer->create(
	timeout => $dt * 1000,
	onTick => sub {
		$t += $dt;
		$xs->cycle_push($t);
		$total_phase += $dt * $freq;
		$ys->cycle_push(sin($total_phase));
		$plot->dataSets->{data} = ds::Pair($xs->uncycle, $ys->uncycle,
				plotType => ppair::Lines);
	},
)->start;

run Prima;
