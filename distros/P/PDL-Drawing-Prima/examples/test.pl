use strict;
use warnings;
;
use PDL;
use PDL::NiceSlice;
use Prima qw(Application);
use PDL::Drawing::Prima;

my $wDisplay = Prima::MainWindow-> create(
	text    => 'PrimaPoly Test',
	onPaint => sub {
		my ( $self, $canvas) = @_;
		my $c = $canvas-> color;
		$canvas-> color( cl::White);
		$canvas-> bar( 0, 0, $canvas-> size);
		$canvas-> color( $c);
		paint( $canvas);
	},
);

sub paint
{
	my $p = $_[0];
	my @size = $p-> size;

	# Draw three sin curves with 10 nan values
	my $x = sequence(200, 3) + 100;
	my $bad_data = pdl(-1)->log;
	$x(30:40) .= $bad_data;
	my $y = sin($x / 20) * 100 + 100;
	my $infty = -pdl(0)->log;
	# Set the 50th point to infinity:
	$y(50) .= $infty;
	$y(:,1) += 50;
	$y(:,2) += 100;
	# Set the 51st point to bad:
	$x(51) .= -100;
	$x = $x->setbadif($x < 0);
	
	# with different colors:
	my $colors = pdl(cl::Black, cl::Blue, cl::Green);

# my $patterns = byte q[ 1; 9 3; 3 3 ];

	my $patterns = PDL::Drawing::Prima::piddle_of_patterns_for(lp::Solid, lp::Dash, lp::DashDot);
	print "Patterns are $patterns\n";
	$p->pdl_polylines($x, $y, colors => $colors, linePatterns => $patterns
			, lineWidths => sequence(3)*2);
	# Reset to a solid line style:
	$p->linePattern(lp::Solid);
	
	# Make a rainbow:
	my $deg = sequence(360);
	my $hsv = ones(3, 360);
	$hsv(0, :) .= $deg->transpose;
	$x = $deg + 50;
	$y = $deg + 100;
	$colors = $hsv->hsv_to_rgb->rgb_to_color;
	$p->pdl_lines($x, $y, $x, $y + 50, colors => $colors);

=pod
	
	# Draw random arcs:
	my $xs = random(30) * $size[0];
	my $ys = random(30) * $size[1];
	my $dxs = random(30) * 100;
	my $dys = random(30) * 100;
	my $start_angle = random(30) * 360;
	my $stop_angle = random(30) * 360;
	$p->pdl_arcs($xs, $ys, $dxs, $dys, $start_angle, $stop_angle,
		colors => random(30) * 2**24);
	
	# and random bars:
	$xs = random(30) * $size[0];
	$ys = random(30) * $size[1];
	$dxs = random(30) * 100;
	$dys = random(30) * 100;
	$p->pdl_bars($xs, $ys, $xs + $dxs, $ys + $dys,
		colors => random(30) * 2**24);
	
	# and random chords:
	$xs = random(30) * $size[0];
	$ys = random(30) * $size[1];
	$dxs = random(30) * 100;
	$dys = random(30) * 100;
	$start_angle = random(30) * 360;
	$stop_angle = random(30) * 360;
	$p->pdl_chords($xs, $ys, $dxs, $dys, $start_angle, $stop_angle,
		colors => random(30) * 2**24);
	
	# and random ellipses:
	$xs = random(30) * $size[0];
	$ys = random(30) * $size[1];
	$dxs = random(30) * 100;
	$dys = random(30) * 100;
	$p->pdl_ellipses($xs, $ys, $dxs, $dys,
		colors => random(30) * 2**24);
	
=cut
	
}

run Prima;

