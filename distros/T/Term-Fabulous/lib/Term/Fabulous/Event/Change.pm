package Term::Fabulous::Event::Change;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Change :isa(Clay::UI::Events::Event) :strict(params) {
	field $value :param :reader;

	method event_name :common { 'Change' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Change - The user changed the value of an input widget

=head1 SYNOPSIS

	use Clay::UI::Enum::Result;

	# On one input:
	$name_field->on( Change => sub ($event) {
		say 'The name is now: ', $event->value;
		return Clay::UI::Enum::Result->CONTINUE;    # let ancestors see it too
	} );

	# Once for a whole form: Change bubbles up from every input inside it.
	$form_box->on( Change => sub ($event) {
		my $input = $event->target;                 # the input that changed
		printf "%s = %s\n", $input->id, $event->value // 'nothing';
		return;
	} );

=head1 DESCRIPTION

A C<Change> event tells you that the user changed the value of an input
widget: by typing into a L<Term::Fabulous::Widget::TextField> or
L<Term::Fabulous::Widget::TextArea>, toggling a
L<Term::Fabulous::Widget::Checkbox>, selecting a radio button of a
L<Term::Fabulous::Widget::RadioGroup>, choosing an option of a
L<Term::Fabulous::Widget::Dropdown>, moving a
L<Term::Fabulous::Widget::Slider>, choosing the stars of a
L<Term::Fabulous::Widget::StarRating> or a segment of a
L<Term::Fabulous::Widget::SegmentedControl>.

It is a L<Clay::UI::Events::Event> whose name is C<Change>; listen for
it with C<< $widget->on( Change => sub ($event) { ... } ) >>.

=over

=item *

C<Change> is fired only for changes the user makes with the keyboard
or the mouse, and for the methods that act "as the user does"
(C<< $checkbox->toggle >>, C<< $group->choose($button) >>,
C<< $dropdown->choose($index) >>). Setting a value from your program
(C<< $field->value('x') >>, C<< $checkbox->checked(1) >>, ...) never
fires it.

=item *

It is fired on the input whose value changed (for radio buttons: on the
radio group). C<< $event->target >> is that widget.

=item *

It bubbles to the ancestors of that widget, so a container can listen
once for all the inputs inside it. Bubbling continues past a widget only
if that widget has no C<Change> listeners, or if every one of its
C<Change> listeners returned C<< Clay::UI::Enum::Result->CONTINUE >>. A
listener that returns anything else, including a plain C<return;> or the
value of its last statement, stops the event at that widget. See
L<Term::Fabulous::Manual::Events/Return values and bubbling>.

=back

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Change->new( value => $new_value );

You only need the constructor when you write your own input widget; the
built-in widgets fire their own events (see
L<Term::Fabulous::Widget::Input/fire_change>).

=over

=item C<value>

Required. The new value, in the form the widget's C<value> reader
returns it. May be C<undef>.

=back

Unknown parameters die. Like every L<Clay::UI::Events::Event>, an event
object can be fired only once.

=head1 METHODS

=head2 value

	my $new_value = $event->value;

The new value of the input, in the form its C<value> reader returns it:

=over

=item *

L<Term::Fabulous::Widget::TextField> and
L<Term::Fabulous::Widget::TextArea>: the whole text, a character string
(lines joined with C<"\n"> in a text area).

=item *

L<Term::Fabulous::Widget::Checkbox>: C<1> (checked) or C<0>
(unchecked).

=item *

L<Term::Fabulous::Widget::RadioGroup>: the C<value> of the selected
L<Term::Fabulous::Widget::RadioButton>.

=item *

L<Term::Fabulous::Widget::Dropdown>: the C<value> of the chosen option.

=item *

L<Term::Fabulous::Widget::Slider>: the new number.

=item *

L<Term::Fabulous::Widget::StarRating>: the new number of stars.

=item *

L<Term::Fabulous::Widget::SegmentedControl>: the C<value> of the
selected option.

=back

=head2 target

	my $input = $event->target;

The widget the event was fired on, inherited from
L<Clay::UI::Events::Event>. It stays the same while the event bubbles;
C<< $event->current_target >> is the widget whose listeners run right
now.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Input>, L<Term::Fabulous::Event::Submit>,
L<Term::Fabulous::Manual::Forms/FORMS AND INPUT WIDGETS>,
L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::Forms/Read all values of a form>,
L<Term::Fabulous::Cookbook::Forms/Choose from options in Perl (Dropdown, RadioGroup, Slider)>.

=cut
