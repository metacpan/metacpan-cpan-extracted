package Term::Fabulous::Event::Activate;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Activate :isa(Clay::UI::Events::Event) :strict(params) {
	method event_name :common { 'Activate' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Activate - The user activated a button

=head1 SYNOPSIS

	$save_button->on( Activate => sub ($event) {
		save_document();
		return;
	} );

=head1 DESCRIPTION

A L<Term::Fabulous::Widget::Button> fires C<Activate> on itself when
the user activates it, whichever way: a click (the left mouse button
pressed and released over the button), or C<Enter> (also the keypad's
Enter) or C<Space> without modifiers while the button has the keyboard
focus. C<< $button->activate >> fires it from code. Listen for it instead of
C<OnRelease> and C<KeyPress> when the action is the same for the mouse
and the keyboard, which it nearly always is.

The event has no fields of its own; C<< $event->target >> is the
button. It is a L<Clay::UI::Events::Event> whose name is C<Activate>,
so it bubbles up to the ancestors like every other event.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Activate->new;

Unknown parameters die. The C<name> and C<bubble_mode> parameters of
L<Clay::UI::Events::Event> are accepted.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Button>, L<Term::Fabulous::Manual::Events/Clicks, hover and press>,
L<Clay::UI::Events::Event>,
L<Term::Fabulous::Cookbook::KeyboardAndMouse/Add buttons for the mouse and the keyboard (Button)>.

=cut
