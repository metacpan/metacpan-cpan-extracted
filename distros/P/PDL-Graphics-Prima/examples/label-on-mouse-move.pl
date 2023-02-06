use strict;
use warnings;
use PDL;

use Prima qw(Label);
use PDL::Graphics::Prima::Simple;

use Time::Piece;
plot(
	-data => ds::Pair(
		pdl(1, 50), pdl(0,0),
		plotType => ppair::Blobs(radius => pdl(5, 100))
		),
	pack => { fill => 'both', expand => 1},
	onMouseMove => sub {
		my ($self, $has_buttons, $x_pixel, $y_pixel) = @_;
		return if $has_buttons;
		
		# Build the mouse widget if it doesn't already exist
		my $label = $self->{mouse_label} ||= $self->insert(Label =>
			autoHeight => 1,
			autoWidth => 1,
			ownerBackColor => 1,
			color => cl::Red,
			onMouseEnter => sub {},
			onMouseMove => sub {},
		);
		
		my $x_time = gmtime($self->x->pixels_to_reals($x_pixel))->hms;
		my $y_real = $self->y->pixels_to_reals($y_pixel);

		# Offset the origin by one pixel so the scroll wheel works
		$label->origin($x_pixel+1, $y_pixel+1);
		$label->text(sprintf("$x_time, %1.2f", $y_real));
	},
);
