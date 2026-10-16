package Term::Fabulous::Event::Answer;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

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

Term::Fabulous::Event::Answer - The user answered a prompt or a file dialog

=head1 SYNOPSIS

	$prompt->on( Answer => sub ($event) {
		return if $event->button ne 'save';
		save_as( $event->value('name') );
		return;
	} );

=head1 DESCRIPTION

A L<Term::Fabulous::Widget::Prompt> fires C<Answer> on itself once each
time it is answered: when the user presses one of its buttons, when the
user presses C<Escape>, or when the program calls C<answer> or
C<close>. When the listeners run, the prompt is already closed and the
keyboard focus is back on the widget that had it before the prompt
opened, so a listener can open the next prompt right away.

The event says which button answered the prompt and what its fields
held at that moment. A prompt closed without a button (by C<Escape> or
by C<close>) answers with the button C<cancel> and is I<dismissed>. So
a program that names its cancel button C<cancel> handles both in the
same way, and one that needs to tell them apart asks L</dismissed>.

A L<Term::Fabulous::Widget::FileDialog> fires the same event, once each
time it is opened, when the user chose a file or a folder or cancelled.
Its button is C<open>, C<save> or C<choose> after its mode, and its
values are C<< { path => $path } >>, the absolute path chosen, in
bytes as the file system has it (see
L<Term::Fabulous::Widget::FileDialog/File names>). Its C<Cancel>
button answers C<cancel>, and C<Escape> or C<close> answer C<cancel>
as dismissed; a cancelled file dialog's values are empty:

	$dialog->on( Answer => sub ($event) {
		open_file( $event->value('path') ) if $event->button eq 'open';
		return;
	} );

It is a L<Clay::UI::Events::Event> whose name is C<Answer>. The prompt
or the file dialog has no parent any more when it fires, so the event
does not bubble anywhere: listen on the prompt or the dialog itself.

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

The id of the button that answered the prompt, or C<cancel> when the
prompt was dismissed. For a file dialog: C<open>, C<save>, C<choose> or
C<cancel>.

=head2 values

	my %values = %{ $event->values };

The values of the prompt's fields, by field name, as a new hash
reference. A prompt without fields gives an empty hash. A file dialog
gives C<< { path => $path } >>, or an empty hash when it was cancelled.

=head2 value

	my $name = $event->value('name');

The value of one field, or C<undef> for a name the prompt has no field
of.

=head2 dismissed

	return if $event->dismissed;

1 when the prompt or the file dialog was closed without a button, by
C<Escape> or by the program calling C<close>, and 0 when a button
answered it.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Prompt>, L<Term::Fabulous::Widget::FileDialog>,
L<Clay::UI::Events::Event>,
L<Term::Fabulous::Cookbook::Forms/Ask for a number and check it (Prompt, validator)>.

=cut
