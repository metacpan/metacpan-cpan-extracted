package Term::Fabulous::Render::Canvas;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

role Term::Fabulous::Render::Canvas {
	use Clay::XS qw(CLAY_RENDER_COMMAND_TYPE_CUSTOM);
	use List::Util qw(max min);
	use Scalar::Util qw(refaddr);
	use Term::Fabulous::Termbox qw(TB_DEFAULT);
	use Term::Fabulous::Color;
	use Term::Fabulous::Render::Attr qw(color_attr);
	use Term::Fabulous::Render::Geometry qw(cell_rect intersect_cell_rects rects_overlap);

	method widget_for;

	# The cell target the frame is painted into (Term::Fabulous::Render).
	method cell_target;

	# By canvas refaddr: { canvas, origin => [x, y], visible => [x0, y0, x1, y1],
	# background, covered, intact } for the frame being painted, and for the
	# last frame that was painted completely.
	field %_plan_by_canvas;
	field %_painted_by_canvas;
	field $_painted_viewport = '';

	# What the unset cells of a canvas show: the first background with an
	# alpha above 0 at or above it (its cells are then blended over that),
	# else the screen background of its UI, else the terminal's.
	sub _background_attr ($canvas) {
		my $rgba = $canvas->background_below( translucent => 1 ) // return TB_DEFAULT;
		return color_attr( Term::Fabulous::Color->new( color => $rgba ) );
	}

	sub _same_place ( $before, $now ) {
		return "@{ $before->{origin} } @{ $before->{visible} } $before->{background}" eq "@{ $now->{origin} } @{ $now->{visible} } $now->{background}";
	}

	# Sizes the canvas to its content box and lets it bring its cells up to
	# date; undef when nothing of it is visible.
	method _plan_canvas ( $command, $clip ) {
		my $canvas = $self->widget_for( $command->{userData} );
		die "Term::Fabulous::Render::Canvas: a custom render command needs a Term::Fabulous::Widget::Canvas, got " . ( ref $canvas || 'no widget' )
			unless defined $canvas && $canvas->isa('Term::Fabulous::Widget::Canvas');

		my ( $x0,   $y0,  $x1,    $y1 )     = cell_rect( $command->{boundingBox} );
		my ( $left, $top, $right, $bottom ) = $canvas->content_insets;
		my @content = ( $x0 + $left, $y0 + $top );
		push @content, max( $content[0], $x1 - $right ), max( $content[1], $y1 - $bottom );
		$canvas->set_content_origin( @content[ 0, 1 ] );
		$canvas->fit_to( $content[2] - $content[0], $content[3] - $content[1] );
		$canvas->refresh_for_frame;

		my $visible = intersect_cell_rects( \@content, $clip );
		return undef unless rects_overlap( $visible, $visible );
		return { canvas => $canvas, origin => [ @content[ 0, 1 ] ], visible => $visible, background => _background_attr($canvas) };
	}

	method plan_canvases ($frame) {
		my $viewport = join 'x', $frame->width, $frame->height;
		my %painted  = $viewport eq $_painted_viewport ? %_painted_by_canvas : ();
		%_painted_by_canvas = ();
		%_plan_by_canvas    = ();
		$_painted_viewport  = $viewport;

		my @commands = $frame->commands;
		foreach my $index ( grep { $commands[$_]{commandType} == CLAY_RENDER_COMMAND_TYPE_CUSTOM } 0 .. $#commands ) {
			my $plan   = $self->_plan_canvas( $commands[$index], $frame->clip_rect($index) ) // next;
			my $before = $painted{ refaddr $plan->{canvas} };

			$plan->{index}                              = $index;
			$plan->{covered}                            = $frame->painted_after( $index, $plan->{visible} );
			$plan->{intact}                             = !$plan->{covered} && defined $before && !$before->{covered} && _same_place( $before, $plan );
			$_plan_by_canvas{ refaddr $plan->{canvas} } = $plan;
		}
		return map { $_->{visible} } grep { $_->{intact} } values %_plan_by_canvas;
	}

	# The sixel pictures of the frame's canvases, in paint order: each
	# covers the visible cells of its canvas the target can show, and is
	# transparent where the frame paints over it.
	method sixel_placements ( $frame, $target ) {
		my @cell_size = $target->sixel_cell_size;
		return () unless @cell_size;
		my $area = $target->sixel_area( $frame->width, $frame->height );
		my @placements;
		foreach my $plan ( sort { $a->{index} <=> $b->{index} } values %_plan_by_canvas ) {
			my $shown = intersect_cell_rects( $plan->{visible}, $area );
			next unless rects_overlap( $shown, $shown );
			my $to_canvas = sub ($rect) {
				[ map { $rect->[$_] - $plan->{origin}[ $_ % 2 ] } 0 .. 3 ]
			};
			my $data = $plan->{canvas}->sixel_data(
				shown     => $to_canvas->($shown),
				covered   => [ map { $to_canvas->($_) } $frame->painted_over( $plan->{index}, $shown ) ],
				cell_size => [@cell_size],
			) // next;
			push @placements, { x => $shown->[0], y => $shown->[1], columns => $shown->[2] - $shown->[0], rows => $shown->[3] - $shown->[1], data => $data };
		}
		return @placements;
	}

	method finish_canvases () {
		%_painted_by_canvas = %_plan_by_canvas;
		%_plan_by_canvas    = ();
		return;
	}

	method invalidate_canvases () {
		%_painted_by_canvas = ();
		$_painted_viewport  = '';
		return;
	}

	method render_custom ( $command, $widget, $buffer ) {
		my $plan   = $_plan_by_canvas{ refaddr $widget } // return;
		my $target = $self->cell_target;
		$target->release_rect( $plan->{visible} ) if $plan->{intact};

		my $changed_spans = $widget->take_changed_spans;
		my ( $origin_x, $origin_y ) = @{ $plan->{origin} };
		my ( $x0, $y0, $x1, $y1 ) = @{ $plan->{visible} };
		foreach my $y ( $y0 .. $y1 - 1 ) {
			my ( $row, $from, $to ) = ( $y - $origin_y, $x0 - $origin_x, $x1 - $origin_x );
			if ( $plan->{intact} ) {
				_shade_canvas_row( $plan, $row, $from, $to, $buffer );
				my $span = $changed_spans->[$row] // next;
				( $from, $to ) = ( max( $from, $span->[0] ), min( $to, $span->[1] ) );
			}
			_paint_canvas_row( $target, $plan, $row, $from, $to, $buffer );
		}
		return;
	}

	# Records the backgrounds of the canvas columns [from, to) of one row
	# in the frame's background buffer without painting them: the cells of
	# an intact canvas stay on screen, but what is drawn later over their
	# neighbors (a border's outer half) still blends with them.
	sub _shade_canvas_row ( $plan, $row, $from, $to, $buffer ) {
		my ( undef, undef, $bgs ) = $plan->{canvas}->cell_row($row);
		my $origin_x = $plan->{origin}[0];
		my $shade    = $buffer->[ $plan->{origin}[1] + $row ] //= [];
		$shade->[ $origin_x + $_ ] = $bgs->[$_] // $plan->{background} foreach $from .. $to - 1;
		return;
	}

	# Paints the canvas columns [from, to) of one row. A glyph that would
	# cross the visible right edge is painted as spaces, like the covered
	# cells of a wide glyph whose first cell is not painted here.
	sub _paint_canvas_row ( $target, $plan, $row, $from, $to, $buffer ) {
		my ( $glyphs, $fgs, $bgs ) = $plan->{canvas}->cell_row($row);
		my ( $origin_x, $origin_y ) = @{ $plan->{origin} };
		my $y           = $origin_y + $row;
		my $limit       = $plan->{visible}[2] - $origin_x;
		my $shade       = $buffer->[$y] //= [];
		my $drawn_until = $from;

		foreach my $column ( $from .. $to - 1 ) {
			my ( $glyph, $x ) = ( $glyphs->[$column], $origin_x + $column );
			my $bg = $bgs->[$column] // $plan->{background};
			$shade->[$x] = $bg;

			if ( ref $glyph && $column + $glyph->[1] <= $limit ) {
				my ( undef, $width, $base, @extenders ) = @$glyph;
				$target->set_cell( $x, $y, $base, $fgs->[$column] // TB_DEFAULT, $bg );
				$target->extend_cell( $x, $y, $_ ) foreach @extenders;
				$drawn_until = $column + $width;
				next;
			}
			next if $column < $drawn_until;
			$target->set_cell( $x, $y, ' ', TB_DEFAULT, $bg );
		}
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Render::Canvas - Paint canvas widgets, only their
changed cells when possible

=head1 SYNOPSIS

	# What Term::Fabulous::Render::draw does with canvases:
	my @kept_rects = $ui->plan_canvases($frame);         # before begin_frame
	$ui->cell_target->begin_frame(@kept_rects);
	$ui->render_custom( $command, $canvas, $buffer );     # for each canvas command
	$ui->cell_target->show_sixels( $ui->sixel_placements( $frame, $ui->cell_target ) );
	$ui->cell_target->end_frame;
	$ui->finish_canvases;                                 # after a complete frame

=head1 DESCRIPTION

Most programs never use this module directly, and neither do widgets
of your own: a widget built on L<Term::Fabulous::Widget::Canvas> is
painted by this role without any help (see
L<Term::Fabulous::Manual::CustomWidgets/A widget that draws itself>).
Read it if you write your own UI class or want to know when a canvas is
repainted. It is one of the roles L<Term::Fabulous::Render> is made of,
and it paints
L<Term::Fabulous::Widget::Canvas> widgets (and everything built on them:
L<Term::Fabulous::Widget::PixelCanvas> and the input widgets).

A canvas asks Clay for a I<custom> render command. This role paints the
canvas's cell buffer into the canvas's content box (its box without
border and padding), clipped like every other command.

=head2 Painting only the changes

Repainting a large canvas every frame is wasteful when only a few of
its cells changed. Since termbox2 keeps the cells of the previous frame
in its back buffer, a canvas can often leave them there and paint only
the cells that changed. This is safe when all of the following hold:

=over

=item *

the canvas has the same position, the same visible part and the same
background as in the last frame that was painted completely;

=item *

no command painted after the canvas (a border, a child widget, a
floating widget such as an open dropdown list) touches its visible part,
neither in this frame nor in that previous frame;

=item *

the viewport has the same size.

=back

Such a canvas is called I<intact>. Its visible rectangle is handed to
the target's C<begin_frame> as a I<kept> rectangle, which protects it
from the background painted below it; then the canvas releases the
rectangle and paints only its changed cells. Every other canvas paints
all of its visible cells.

=head1 METHODS

=head2 plan_canvases

	my @kept_rects = $ui->plan_canvases($frame);

Called before a frame is painted, with the frame's
L<Term::Fabulous::Render::Frame>. For every canvas command it:

=over

=item *

records where the canvas's content box starts
(L<Term::Fabulous::Widget::Canvas/content_origin>) and resizes the
canvas buffer to the content box, which fires
L<Term::Fabulous::Event::CanvasResize> when the size changed;

=item *

lets the canvas bring its cells up to date
(L<Term::Fabulous::Widget::Canvas/refresh>): input widgets paint
themselves here;

=item *

decides whether the canvas is intact (see L</Painting only the changes>).

=back

Returns the visible rectangles (C<[x0, y0, x1, y1]>) of the intact
canvases, for the target's C<begin_frame>. Canvases that are not visible
at all are skipped and keep their pending changes. Dies with
C<Term::Fabulous::Render::Canvas: a custom render command needs a Term::Fabulous::Widget::Canvas>
when a custom command belongs to another kind of widget.

=head2 render_custom

	$ui->render_custom( $command, $canvas, $buffer );

The render command handler for canvases. An intact canvas releases its
kept rectangle and paints the cells that changed since it was last
painted; any other canvas paints all of its visible cells. Unset cells,
and cells without a background color, are painted as the canvas
background: the C<background_color> of the canvas, or of its nearest
ancestor that has one, or else the screen background of the frame
(L<Term::Fabulous::Render/SCREEN BACKGROUND>). A translucent
background color is used opaque here; only the widget's own background
rectangle, painted before the cells, is blended. A wide glyph that
would cross the visible right edge is painted as spaces. Every painted
cell records its background in C<$buffer>, so text drawn over the canvas
later in the frame keeps it.

=head2 sixel_placements

	my @placements = $ui->sixel_placements( $frame, $target );

Called after the frame's commands are painted, for a target that
composes L<Term::Fabulous::Render::Target::Sixel>: the sixel pictures
of the frame's canvases, in paint order, as placements for the
target's C<show_sixels>. Empty when the target's C<sixel_cell_size> is.
For every visible canvas it asks
L<Term::Fabulous::Widget::Canvas/sixel_data> for the picture of the
cells the canvas shows inside the target's C<sixel_area>, with the
cells a later command paints over them
(L<Term::Fabulous::Render::Frame/painted_over>) as covered. A canvas
without a picture (C<undef>) gets no placement.

=head2 finish_canvases

	$ui->finish_canvases;

Called after a frame was painted completely: remembers it as the frame
the next L</plan_canvases> compares with. A frame that died before this
call is never remembered, so the next frame paints every canvas in full.

=head2 invalidate_canvases

	$ui->invalidate_canvases;

Forgets the previous frame, so that the next frame paints every canvas
in full. Call it whenever the target lost its cells. L<Term::Fabulous>
calls it when it opens the terminal, because C<tb_init> starts with an
empty back buffer.

=head1 REQUIRED METHODS

The consuming class provides C<widget_for> (from L<Clay::UI>) and
C<cell_target>, which returns the cell target the canvases are painted
into (its C<set_cell>, C<extend_cell> and C<release_rect> are called;
see L<Term::Fabulous::Render/CELL TARGET>).

=head1 SEE ALSO

L<Term::Fabulous::Widget::Canvas>, L<Term::Fabulous::Render>,
L<Term::Fabulous::Render::Frame>, L<Term::Fabulous::Render::Target::Mask>.

=cut
