package Term::Fabulous::Event::Submit;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Submit :isa(Clay::UI::Events::Event) :strict(params) {
	field $value :param :reader;

	method event_name :common { 'Submit' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Submit - The user pressed Enter in a text field

=head1 SYNOPSIS

	$search_field->on( Submit => sub ($event) {
		run_search( $event->value );
		return;
	} );

=head1 DESCRIPTION

A L<Term::Fabulous::Widget::TextField> fires C<Submit> on itself when
the user presses C<Enter> in it, so you can act on the text without a
separate button. It is a L<Clay::UI::Events::Event> whose name is
C<Submit>; listen for it with
C<< $field->on( Submit => sub ($event) { ... } ) >>.

=over

=item *

It is fired on every C<Enter>, also when the text did not change, when
it is empty, and when the field is C<read_only>. A disabled field fires
nothing.

=item *

L<Term::Fabulous::Widget::TextArea> does not fire C<Submit>: there,
C<Enter> starts a new line.

=item *

Like every event, it bubbles to the field's ancestors as long as the
listeners on the way return C<< Clay::UI::Enum::Result->CONTINUE >> (a
widget without C<Submit> listeners passes it on). A form can therefore
handle C<Enter> in any of its fields with one listener; use
C<< $event->target >> to see which field it came from. See
L<Term::Fabulous::Manual::Events/Return values and bubbling>.

=back

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Submit->new( value => $text );

Needed only by widgets of your own; the text field fires its own
events.

=over

=item C<value>

Required. The text of the field, a character string.

=back

Unknown parameters die. An event object can be fired only once.

=head1 METHODS

=head2 value

	my $text = $event->value;

The text of the field when C<Enter> was pressed, a character string.

=head2 target

	my $field = $event->target;

The text field the event was fired on, inherited from
L<Clay::UI::Events::Event>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::TextField>, L<Term::Fabulous::Event::Change>,
L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Cookbook::Forms/A login form (centered dialog, masked password)>,
L<Term::Fabulous::Cookbook::Forms/Read all values of a form>.

=cut
