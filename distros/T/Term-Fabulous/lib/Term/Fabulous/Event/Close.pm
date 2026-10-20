package Term::Fabulous::Event::Close;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Close :isa(Clay::UI::Events::Event) :strict(params) {
	method event_name :common { 'Close' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Close - A dialog, a toast or a popup menu went away

=head1 SYNOPSIS

	$dialog->on( Close => sub ($event) {
		$status->text('dialog closed');
		return;
	} );

=head1 DESCRIPTION

A L<Term::Fabulous::Widget::Dialog> (a Prompt, a FileDialog, a
KeyReference included) fires C<Close> on itself whenever it closes: when
a button or the C<answer> method answers it, when the user presses
C<Escape>, or when the program calls C<< $dialog->close >>. C<Answer>
(L<Term::Fabulous::Event::Answer>) follows right after. When the
listeners run, the dialog is no longer part of the widget tree, and the
keyboard focus has gone back to the widget that had it before the dialog
opened, if that widget can still take the focus.

A L<Term::Fabulous::Widget::Toast> fires it on itself when it goes
away: when its timeout runs out, when the user clicks its close mark,
or when the program calls C<< $toast->hide >>.

A L<Term::Fabulous::Widget::Menu> that was opened as a popup fires it on
itself when it closes: when the user chooses an item, presses C<Escape>
or moves the focus elsewhere, or when the program calls
C<< $menu->close >>.

The event has no fields of its own; C<< $event->target >> is the
dialog, the toast or the menu. It is a L<Clay::UI::Events::Event>
whose name is C<Close>. The widget has no parent any more when it
fires, so the event does not bubble anywhere. Listen on the dialog,
the toast or the menu itself.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Close->new;

Unknown parameters die. The C<name> and C<bubble_mode> parameters of
L<Clay::UI::Events::Event> are accepted.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Dialog>, L<Term::Fabulous::Widget::Toast>,
L<Term::Fabulous::Widget::Menu>, L<Clay::UI::Events::Event>,
L<Term::Fabulous::Cookbook::Forms/Ask a question in a dialog (Dialog widget)>.

=cut
