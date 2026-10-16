package Term::Fabulous::Event::CanvasResize;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::CanvasResize :isa(Clay::UI::Events::Event) :strict(params) {
	field $columns :param :reader;
	field $rows    :param :reader;

	method event_name :common { 'CanvasResize' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::CanvasResize - A canvas got a new size

=head1 SYNOPSIS

	$canvas->on( CanvasResize => sub ($event) {
		$canvas->clear;
		$canvas->put_text( 0, 0, sprintf( '%d x %d cells', $event->columns, $event->rows ) );
		return;
	} );

=head1 DESCRIPTION

A L<Term::Fabulous::Widget::Canvas> (and every widget built on it, such
as L<Term::Fabulous::Widget::PixelCanvas>, the charts and the input
widgets) fires
C<CanvasResize> on itself when the layout gives its content box a new
size. The canvas buffer has already been resized when the event fires,
and the frame that shows the new size is painted right after the
listeners return, so a listener is the right place to draw content that
depends on the size.

A C<CanvasResize> event bubbles like other events (its bubble mode is
C<IF_CONTINUE>): a listener on an ancestor, for example on the root,
also sees the resizes of every canvas, pixel canvas and input widget
below it, as long as the listeners on the way return
C<< Clay::UI::Enum::Result->CONTINUE >> (the built-in widgets add no
C<CanvasResize> listeners of their own, so they pass it on). Check
C<< $event->target >> in such a listener:

	$root->on( CanvasResize => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless $event->target == $chart;
		redraw_chart();
		return;
	} );

The first event comes with the first frame that lays the canvas out:
before that, the buffer has 0 x 0 cells. Cells that still fit keep
their content; see L<Term::Fabulous::Widget::Canvas/Buffer size>.

The class is a subclass of L<Clay::UI::Events::Event>, so C<target>,
C<current_target>, C<name> (C<'CanvasResize'> unless given to the
constructor) and C<bubble_mode> (C<IF_CONTINUE>) are available as well.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::CanvasResize->new( columns => 40, rows => 10 );

Built by the canvas itself; there is rarely a reason to build one. Both
parameters below are required, and unknown parameters die. The C<name>
and C<bubble_mode> parameters of L<Clay::UI::Events::Event> are
accepted as well.

=over

=item C<columns>

The new width of the canvas buffer in columns.

=item C<rows>

The new height of the canvas buffer in rows.

=back

=head1 METHODS

=head2 columns

	my $width = $event->columns;

The new width of the canvas buffer in columns (the same as
C<< $canvas->columns >>).

=head2 rows

	my $height = $event->rows;

The new height of the canvas buffer in rows (the same as
C<< $canvas->rows >>).

=head1 SEE ALSO

L<Term::Fabulous::Widget::Canvas>, L<Term::Fabulous::Widget::PixelCanvas>,
L<Term::Fabulous::Manual::Charts/CANVASES>,
L<Term::Fabulous::Cookbook::Canvases/Plot data on a pixel canvas (PixelCanvas)>.

=cut
