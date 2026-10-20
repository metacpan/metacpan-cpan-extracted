package Term::Fabulous::Event::Answer;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Answer :isa(Clay::UI::Events::Event) :strict(params) {
	use Term::Fabulous::Check qw(boolean describe string);

	field $button    :param :reader;
	field $values    :param = {};
	field $dismissed :param :reader = 0;

	ADJUST {
		$button    = string( $self, button => $button );
		$dismissed = boolean( $self, dismissed => $dismissed );
		die "Term::Fabulous::Event::Answer: values must be a hash reference, got " . describe($values) unless ref $values eq 'HASH';
		$values = {%$values};
	}

	method event_name :common { 'Answer' }

	method values () {
		return {%$values};
	}

	method value ($name) {
		return $values->{$name};
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Answer - The user answered a dialog

=head1 SYNOPSIS

	$prompt->on( Answer => sub ($event) {
		return if $event->button ne 'save';
		save_as( $event->value('name') );
		return;
	} );

=head1 DESCRIPTION

Every L<Term::Fabulous::Widget::Dialog> fires C<Answer> on itself once
each time it closes, right after C<Close>: when the user presses one of
its buttons or C<Escape>, or when the program calls C<answer> or
C<close>. When the listeners run, the dialog is already closed and the
keyboard focus is back on the widget that had it before the dialog
opened, so a listener can open the next dialog right away.

The event says which button answered the dialog and what values it
carries. One rule holds for every dialog: an answer carries the
dialog's C<values> (see L<Term::Fabulous::Widget::Dialog/values>) and
what the answer adds to them, and a dialog closed without a button (by
C<Escape> or by C<close>) answers with the button C<cancel>, carries
its C<values> as well and is I<dismissed>. So a program that names its
cancel button C<cancel> handles both in the same way, and one that
needs to tell them apart asks L</dismissed>.

=over

=item *

A L<Term::Fabulous::Widget::Prompt> reports the values of its fields,
by field name, in every answer, also when it is dismissed.

=item *

A L<Term::Fabulous::Widget::FileDialog> has no values of its own. Its
choice answers C<open>, C<save> or C<choose> after its mode with
C<< { path => $path } >>, the absolute path chosen, in bytes as the
file system has it (see
L<Term::Fabulous::Widget::FileDialog/File names>). Its C<Cancel>
button answers C<cancel>, and C<Escape> or C<close> answer C<cancel>
as dismissed, both with empty values:

	$dialog->on( Answer => sub ($event) {
		open_file( $event->value('path') ) if $event->button eq 'open';
		return;
	} );

=item *

A L<Term::Fabulous::Widget::KeyReference> answers C<close> from its
Close button.

=back

It is a L<Clay::UI::Events::Event> whose name is C<Answer>. The dialog
has no parent any more when it fires, so the event does not bubble
anywhere: listen on the dialog itself.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Answer->new(
		button    => 'save',
		values    => { name => 'notes.txt' },
		dismissed => 0,
	);

C<button> is required, and the others are optional. Unknown parameters
die. The C<name> and C<bubble_mode> parameters of
L<Clay::UI::Events::Event> are accepted.

=head1 METHODS

=head2 button

	if ( $event->button eq 'delete' ) { ... }

The id of the button that answered the dialog, or C<cancel> when the
dialog was dismissed. For a file dialog: C<open>, C<save>, C<choose> or
C<cancel>.

=head2 values

	my %values = %{ $event->values };

The values the answer carries, as a new hash reference: a prompt's
fields by field name (an empty hash without fields), a file dialog's
C<< { path => $path } >> for a choice and an empty hash when it was
cancelled, an empty hash for a plain dialog.

=head2 value

	my $name = $event->value('name');

One of the values, or C<undef> for a name the answer has no value of.

=head2 dismissed

	return if $event->dismissed;

1 when the dialog was closed without a button, by C<Escape> or by the
program calling C<close>, and 0 when a button (or C<answer>) answered
it.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Dialog/Answers>, L<Term::Fabulous::Widget::Prompt>, L<Term::Fabulous::Widget::FileDialog>,
L<Term::Fabulous::Widget::KeyReference>, L<Clay::UI::Events::Event>,
L<Term::Fabulous::Manual::CustomWidgets/A dialog of your own>,
L<Term::Fabulous::Cookbook::Forms/Ask for a number and check it (Prompt, validator)>.

=cut
