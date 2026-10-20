package Term::Fabulous::Event::ValidityChange;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::ValidityChange :isa(Clay::UI::Events::Event) :strict(params) {
	field $is_valid :param :reader;
	field $error :param :reader = undef;

	method event_name :common { 'ValidityChange' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::ValidityChange - The value of an input widget became valid or invalid

=head1 SYNOPSIS

	use Clay::UI::Enum::Result;

	# On one input:
	$email->on( ValidityChange => sub ($event) {
		$hint->text( $event->error // ' ' );
		return Clay::UI::Enum::Result->CONTINUE;
	} );

	# Once for a whole form: the event bubbles up from every input inside it.
	$form->on( ValidityChange => sub ($event) {
		printf "%s is now %s\n", $event->target->id, $event->is_valid ? 'fine' : $event->error;
		return;
	} );

	# Report the inputs that are invalid from the start, such as empty
	# required fields, which have fired nothing yet:
	$_->validate foreach $form->invalid_inputs;

=head1 DESCRIPTION

A C<ValidityChange> event tells you that the message an input widget
has about its value changed: the value became invalid, became valid,
or is invalid for another reason than before (see
L<Term::Fabulous::Widget::Input/required> and
L<Term::Fabulous::Widget::Input/validator>). It is a
L<Clay::UI::Events::Event> whose name is C<ValidityChange>; listen for
it with C<< $widget->on( ValidityChange => sub ($event) { ... } ) >>.

=over

=item *

It is fired by L<Term::Fabulous::Widget::Input/validate>, which the
input runs after every C<Change> event and whenever its C<required>,
C<required_message> or C<validator> is written. It fires only when the
message differs from the one the input reported last: typing a second
wrong character into an e-mail field fires nothing new.

=item *

Before its first C<ValidityChange>, an input counts as having reported
a valid value. An input that is invalid from the start (an empty
required field, a field created with a wrong C<value>) therefore fires
nothing until the user changes it or something calls C<validate>.
Setting the value from the program fires nothing either, as with
C<Change>; call C<validate> to report it.

=item *

It is fired on the input, right after the C<Change> event it follows,
and bubbles to the input's ancestors in the same way (see
L<Term::Fabulous::Event::Change>).

=back

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::ValidityChange->new( is_valid => 0, error => 'Please enter an e-mail address.' );

You only need the constructor when you write your own input widget;
the built-in widgets fire their own events.

=over

=item C<is_valid>

Required. 1 or 0.

=item C<error>

The message, or C<undef> for a valid value. Default: C<undef>.

=back

=head1 METHODS

=head2 is_valid

	if ( $event->is_valid ) { ... }

Whether the value is valid now.

=head2 error

	my $message = $event->error;

What is wrong with the value, as L<Term::Fabulous::Widget::Input/error>
reports it, or C<undef> when it is valid.

=head2 target

	my $input = $event->target;

The input the event was fired on, inherited from
L<Clay::UI::Events::Event>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Input>, L<Term::Fabulous::Validator>,
L<Term::Fabulous::Event::Change>,
L<Term::Fabulous::Manual::Forms/Checking input>,
L<Term::Fabulous::Cookbook::Forms/Check the values of a form (required, validator)>.

=cut
