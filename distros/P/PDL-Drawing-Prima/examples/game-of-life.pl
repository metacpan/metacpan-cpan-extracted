=head1 NAME

game-of-life.pl - visualizing the game of life

=head1 DESCRIPTION

This example script demonstrates the dynamics of Conway's Game of Life.

=head1 AUTHOR

David Mertens

=cut

use strict;
use warnings;
use PDL;
use Prima qw(Application);
use PDL::Drawing::Prima;

# Set up the grid of cells:
my $L = 20;
my $living = floor(random($L, $L) * 2);

my ($timer, $width, $height, $xs, $ys, $size);

my $main_window = Prima::MainWindow-> create(
	text    => 'Game of Life',
	accelItems => [
		 ['', '', 'q', sub {$_[0]->close}]
	],
	color => cl::Black,
	backColor => cl::White,
	buffered => 1, # for smoother drawing, to avoid flicker
	onSize => sub {
		# Recompute the grid positions:
		my $self = shift;
		$width = $self->width / $L;
		$xs = sequence($L) * $width + $width / 2;
		$height = $self->height / $L;
		$ys = sequence(1,$L) * $height + $height / 2;
		$size = pdl([$width, $height])->min;
	},
	onPaint => sub {
		my $self = shift;
		
		# Update the canvas:
		#$self->backColor(cl::White);
		$self->color(cl::Black);
		$self->clear;
		$self->pdl_symbols($xs, $ys, 4, 45, ($living == 1), $size/1.5, 1);
	},
);

$timer = Prima::Timer-> create(
	timeout => 10, # milliseconds
	onTick  => sub {
		# Calculate the number of neighbours per cell.
		my $n = $living->range(ndcoords($living)-1,3,"periodic")->reorder(2,3,0,1);
		$n = $n->sumover->sumover - $living;

		# Calculate the next generation.
		$living = ((($n == 2) + ($n == 3))* $living) + (($n==3) * !$living);
		$main_window->notify('Paint');
	},
);

$timer-> start;

run Prima;

