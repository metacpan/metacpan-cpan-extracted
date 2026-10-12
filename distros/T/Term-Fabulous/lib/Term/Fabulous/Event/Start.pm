package Term::Fabulous::Event::Start;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Start :isa(Clay::UI::Events::Event) :strict(params) {
	field $width  :param :reader;
	field $height :param :reader;

	method event_name :common { 'Start' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Start - The terminal is open and its size is known

=head1 SYNOPSIS

	$root->on( Start => sub ($event) {
		$status->text( sprintf '%d x %d', $event->width, $event->height );
		return;
	} );

=head1 DESCRIPTION

L<C<< $ui->run >>|Term::Fabulous/run> fires one C<Start> event on the root widget after
it has opened the terminal and replaced the C<width> and C<height>
given to C<new> with the terminal's size (in inline mode, the height is
the rows of the region; see L<Term::Fabulous/INLINE MODE>), and before
the first frame is drawn. It fires from inside the running event loop, before any input
is read: C<< $ui->width >> and C<< $ui->height >> already hold the
terminal size, and C<< $ui->loop >> is the running loop, so a listener
can add timers to it or stop it. Timers and other work the program
queued on the loop before C<run> may run before it. Later size changes fire
C<Resize> (L<Term::Fabulous::Event::Resize>) instead; a program that
lays itself out by the terminal size usually listens to both.

The event is fired at every call of C<run>. A program that drives the
UI with L<Term::Fabulous/step> instead gets it from the C<step> that
opens the terminal; a C<run> on a terminal that C<step> has opened
already does not fire it again.

The class is a subclass of L<Clay::UI::Events::Event>, so C<target>,
C<current_target>, C<name> (C<'Start'> unless given to the constructor)
and C<bubble_mode> are available as well. Since the event is fired on
the root, it has no ancestors to bubble to.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Start->new( width => 120, height => 40 );

Unknown parameters die. The C<name> and C<bubble_mode> parameters of
L<Clay::UI::Events::Event> are accepted as well.

=over

=item C<width>

Required. The terminal width in columns.

=item C<height>

Required. The terminal height in rows.

=back

=head1 METHODS

=head2 width

	my $columns = $event->width;

The terminal width in columns.

=head2 height

	my $rows = $event->height;

The terminal height in rows.

=head1 SEE ALSO

L<Term::Fabulous>, L<Term::Fabulous::Event::Resize>,
L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::Layout/Change the layout with the terminal size (Start and Resize events)>.

=cut
