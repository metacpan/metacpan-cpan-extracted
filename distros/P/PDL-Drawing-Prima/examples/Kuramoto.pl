use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use Prima qw(Application Buttons Sliders Label);
use PDL::Drawing::Prima;

my $N_osc = shift || 50;
my $twopi = atan2(1,1) * 8;

my ($thetas, $omegas, $speed_colors);
# These will be initialized with the following function (defined below):
reset_sim();

my $dt = 2**-5;
my $K = 1.75;
my ($x_max, $y_max, $radius);

my ($main_window, $sim, $timer);

$main_window = Prima::MainWindow->create(
	text    => 'Kuramoto Simulator',
	sizeMin => [600, 200],
);

######################
# Start/Pause Button #
######################

$main_window->insert(Button =>
	text => 'Start',
	place => {
		anchor => 'sw',
		x => 5, width => 100,
		y => -45, rely => 1, height => 40,
	},
	onClick => sub {
		my $self = shift;
		if ($timer->get_active) {
			$self->text('Start');
			$timer->stop;
		}
		else {
			$self->text('Pause');
			$timer->start;
		}
	},
);

################
# Reset Button #
################

$main_window->insert(Button =>
	text => 'Reset',
	place => {
		anchor => 'sw',
		x => 110, width => 100,
		y => -45, rely => 1, height => 40,
	},
	onClick => sub {
		reset_sim();
		$sim->notify('Paint') unless($timer->get_active);
	},
);

# Re-randomizes the positions and velocities of the oscillators
sub reset_sim {
	$thetas = random($N_osc);
	$omegas = grandom($N_osc) + 0.01;
	my $hues = ($omegas - $omegas->min) / ($omegas->max - $omegas->min) * 300;
	my $hsv = ones(3, $N_osc);
	$hsv(0, :) .= $hues->transpose;
	$speed_colors = $hsv->hsv_to_rgb->rgb_to_color;
}

#######################
# K (coupling) Slider #
#######################

my $K_label = $main_window->insert(Label =>
	text => "Coupling (K): $K",
	place => {
		anchor => 'sw',
		x => 220, width => 150,
		y => -40, rely => 1,
	},
);

$main_window->insert(Slider =>
	value => $K * 100,
	max => 500,
	min => 1,
	ticks => undef,
	onChange => sub {
		my $self = shift;
		$K = $self->value / 100;
		$K_label->text(sprintf("Coupling (K): %1.2f", $K));
	},
	place => {
		anchor => 'sw',
		x => 375, relwidth => 1, width => -485,
		y => -45, rely => 1,
	},
);

###############
# Help Button #
###############

use File::Spec;
use FindBin;
my $app_filename = File::Spec->catfile($FindBin::Bin, $FindBin::Script);
$main_window->insert(Button =>
	text => 'Help',
	place => {
		anchor => 'sw',
		x => -110, relx => 1, width => 105,
		y => -45, rely => 1,
	},
	onClick => sub {
		$::application->open_help($app_filename);
		$::application->get_active_window->bring_to_front
			if $::application->get_active_window;
		
	}
);

#####################
# Simulator Drawing #
#####################

$sim = $main_window->insert(Widget =>
	onSize => sub {
		my $self = shift;
		# Calculate the coordinates of the center and the size of the radius
		($x_max, $y_max) = $self->size;
		$radius = 0.4 * $x_max;
		$radius = 0.4* $y_max if $y_max < $x_max;
	},
	onPaint => sub {
		my $self = shift;
		# Compute the theta positions:
		my $xs = cos($thetas) * $radius + $x_max/2;
		my $ys = sin($thetas) * $radius + $y_max/2;

		# Update the canvas:
		$self->backColor(cl::White);
		$self->clear;
		
		# Draw a circular track:
		$self->color(cl::Black);
		$self->ellipse($x_max/2, $y_max/2, 2*$radius, 2*$radius);
		
		# Draw all the oscillators:
		$self->pdl_fill_ellipses($xs, $ys, 10, 10, colors => $speed_colors
											, backColors => $speed_colors);
	},
	place => {
		anchor => 'sw',
		x => 0, relwidth => 1,
		y => 0, relheight => 1, height => -50,
	},
	buffered => 1,
);

###################
# Simulator Timer #
###################

$timer = Prima::Timer-> create(
	timeout => 30, # milliseconds
	onTick  => sub {
		# Compute r:
		my $rx = $thetas->cos->average;
		my $ry = $thetas->sin->average;
		my $r = sqrt($rx*$rx + $ry*$ry);
		my $psi = atan2($ry, $rx);
		
		# Compute the next time step:
		$thetas += $dt * ($omegas + $r * $K * sin($psi - $thetas));
		$sim->notify('Paint');
	},
);

run Prima;

=head1 NAME

Kuramoto.pl - a simple simulation of the Kuramoto model

=head1 SYNOPSIS

If you have not yet installed L<PDL::Drawing::Prima> but you have compiled
it, you can run this example program from the root directory with the
following:

 perl -Mblib examples/Kuramoto.pl

If you have installed L<PDL::Drawing::Prima>, you can run it simply with

 perl examples/Kuramoto.pl

The script optionally takes the desired number of oscillators to simulate as
an argument, so the following will simulate 200 oscillators:

 perl examples/Kuramoto.pl 200

=head1 DESCRIPTION

This covers a description of the actual application and the science that
underlies it. To understand how the code functions, you should look directly
at the (hopefully well-documented) code.

The Kuramoto model is a simple model for spontaneous collective
synchronization. The model is significant because the underlying
single-particle interaction dynamics are very simple, yet in the limit of
large system size, the Kuramoto model exhibits a second-order phase
transition in the coupling strength.

If you are not a physicist (or if it's been a while since you've thought
about phase transitions), you probably do not know what a second-order
phase transition is. Before I can define what a phase transition is, though,
I must first define an order parameter, because the difference between a
first order and a second order phase transition is what happens to the order
parameter at the phase transition. An I<order parameter> is some measure of
the system which is zero on one side of the transition and nonzero on the
other side of the transition.

Clear as mud, right? Stick with me, it'll make sense. :-)

Let's think about the most familiar phase transition: water freezing into
ice. A good order parameter for this phase
transition is the shear modulus, that is, how hard you have to press to get
your finger through the thing. Above the transition temperature, you can
easily insert your hand into the liquid water, so the shear modulus is
essentially zero. Below the transition temperature, you can't insert your
finger into the block of ice, but you can shear it with a finite force. So,
the force necessary to shear the material has gone from zero (for liquid
water) to nonzero (for solid ice) at the phase transition. In fact, as a
function of temperature, the shear modulus jumps discontinuously from zero
to a finite value. This is the hallmark of a first order transition:
the order parameter jumps discontinuously at the transition.

Second order phase transitions exhibit a continuous change in their order
parameter. The transition in magnets at the Currie point is an example of a
continuous or second-order phase transition. The Kuramoto model is another.

working here

In the Kuramoto model, the order parameter is taken as the length of the 
vector average position of the oscillators divided by the radius of the
circle. In other words, if all the oscillators are sitting on top of each
other, their vector average position 

You can find a full write-up on the Kuramoto model at wikipedia. To see a
simple real-world example of synchronization that behaves in a
similar fashion, search on YouTube for "synchronizing metronomes".



=head1 AUTHOR

David Mertens

=cut
