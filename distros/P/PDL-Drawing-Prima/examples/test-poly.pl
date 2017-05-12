use strict;
use warnings;
;
use PDL;
use PDL::NiceSlice;
use Prima qw(Application);
use PDL::Drawing::Prima;

die "You must supply pairs of points\n" unless @ARGV > 2 and @ARGV % 2 == 0;
my $coords = pdl(join(' ', @ARGV));
my $xs = $coords(0:-1:2);
my $ys = $coords(1:-1:2);

my $wDisplay = Prima::MainWindow-> create(
	text    => 'PrimaPoly Test',
	backColor => cl::White,
	color => cl::Black,
	clipRect => [40, 40, 40, 40],
	onPaint => sub {
		my ($self) = @_;
		$self->clear;
		$self->pdl_polylines($xs, $ys);
	},
	onMouseDown => sub {
		my ($self, $down_button, undef, $x, $y) = @_;
		$self->{mouse_prev} = [$x, $y];
	},

	onMouseMove => sub {
		my ($self, $drag_button, $x_stop, $y_stop) = @_;
		
		return unless $drag_button;
		
		if (not defined $self->{mouse_prev}) {
			$self->{mouse_prev} = [$x_stop, $y_stop];
			return 1;
		}
		
		my ($x_start, $y_start) = @{$self->{mouse_prev}};

		my $dx = $x_stop - $x_start;
		$xs += $dx;
		my $dy = $y_stop - $y_start;
		$ys += $dy;
	
		# Store the intermediate locations:
		$self->{mouse_prev} = [$x_stop, $y_stop];
		
		$self->repaint;
	},
	
	onMouseUp => sub {
		delete $_[0]->{mouse_down};
		delete $_[0]->{mouse_move};
	},
);


run Prima;

