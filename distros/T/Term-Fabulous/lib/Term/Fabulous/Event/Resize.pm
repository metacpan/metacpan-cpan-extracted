package Term::Fabulous::Event::Resize;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Resize :isa(Clay::UI::Events::Event) :strict(params) {
	field $width  :param :reader;
	field $height :param :reader;
	field $is_post_event :param :reader = 0;

	method is_pre_event() {
		return !$is_post_event;
	}

	method event_name :common { 'Resize' }

	method of :common ($ev, $is_post_event = 0) {
		return $class->new(
			width         => $ev->w,
			height        => $ev->h,
			is_post_event => $is_post_event,
		);
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Resize - The terminal changed size

=head1 SYNOPSIS

	$root->on( Resize => sub ($event) {
		return if $event->is_pre_event;    # react once, after the new size is set
		$status->text( sprintf '%d x %d', $event->width, $event->height );
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous> fires a C<Resize> event when the terminal window
changes size. Most programs do not need it: the layout follows the new
size automatically, because widgets sized with C<grow> or C<percent(...)>
are laid out again in the next frame. Listen for it when something that
is not part of the layout depends on the terminal size. In inline mode
(L<Term::Fabulous/INLINE MODE>) the height it reports is the rows of the
region, which changes only while the terminal has fewer rows than
C<inline> asks for.

Resizes are debounced: while the user drags the window border, nothing
is fired; one tenth of a second after the last size change, the event is
fired twice for the final size, always on the root widget. No C<Resize>
is fired when C<run> starts and replaces the C<width> and C<height>
given to C<new> with the terminal's size: that fires C<Start>
(L<Term::Fabulous::Event::Start>) instead (see
L<Term::Fabulous::Cookbook::Layout/Change the layout with the terminal size (Start and Resize events)>).
The two events of a resize:

=over

=item 1.

First with L</is_pre_event> true. At this point C<< $ui->width >> and
C<< $ui->height >> still hold the old size.

=item 2.

Then with L</is_post_event> true, after C<< $ui->width >> and
C<< $ui->height >> have been set to the new size. The new layout is
computed and shown with the next frame, at the next tick of the 1/30
second frame timer.

=back

A size with zero columns or zero rows is ignored and fires nothing. No
frames are drawn while a resize is pending.

The class is a subclass of L<Clay::UI::Events::Event>, so C<target>,
C<current_target>, C<name> (C<'Resize'> unless given to the constructor)
and C<bubble_mode> are available as well. Since the event is fired on
the root, it has no ancestors to bubble to.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Resize->new( width => 120, height => 40, is_post_event => 1 );

Unknown parameters die. The C<name> and C<bubble_mode> parameters of
L<Clay::UI::Events::Event> are accepted as well.

=over

=item C<width>

Required. The new terminal width in columns.

=item C<height>

Required. The new terminal height in rows.

=item C<is_post_event>

Optional boolean. True if the new size has already been applied.
Default: C<0>.

=back

=head2 of

	my $event = Term::Fabulous::Event::Resize->of( $termbox_event, $is_post_event );

Builds an event from a C<Term::Fabulous::Termbox::Event> of type C<TB_EVENT_RESIZE>:
C<width> and C<height> from its C<w> and C<h>. C<$is_post_event> is
optional and defaults to C<0>. Class method.

=head1 METHODS

=head2 width

	my $columns = $event->width;

The new terminal width in columns.

=head2 height

	my $rows = $event->height;

The new terminal height in rows.

=head2 is_pre_event

	return if $event->is_pre_event;

True for the first of the two events, fired before the new size is
applied. Always the opposite of L</is_post_event>.

=head2 is_post_event

	return unless $event->is_post_event;

True for the second of the two events, fired after the new size is
applied.

=head1 SEE ALSO

L<Term::Fabulous>, L<Term::Fabulous::Event::Start>,
L<Term::Fabulous::Event::CanvasResize>, L<Term::Fabulous::Manual::Events/EVENTS>.

=cut
