package Reaction::UI::Widget::Field::Mutable;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field';



 before fragment widget {
   arg 'field_id' => event_id 'value_string';
   arg 'field_name' => event_id 'value_string' unless defined $_{field_name};
   arg 'field_type' => 'text';
   arg 'field_class' => "action-field " . $_{viewport}->name;

   # these two are to fire force_events in viewports
   # where you can end up without an event for e.g.
   # HTML checkbox fields

   arg 'exists_event' => event_id 'exists';
   arg 'exists_value' => 1;
 };

 implements fragment message_fragment {
   my $vp = $_{viewport};
   return unless $vp->has_message;
   my $message = $vp->message;
   if ($message) {
     arg message => localized $message;
     render 'message';
   }
 };

 implements fragment field_is_required {
   my $vp = $_{viewport};
   if ( $vp->value_is_required && !$vp->value_string ) {
       render 'field_is_required_yes';
   } else {
       render 'field_is_required_no';
   }
 };

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Mutable - Mutable fields

=head1 DESCRIPTION

An extension of L<Reaction::UI::Widget::Field> representing fields
whose values can be mutated.

=head1 FRAGMENTS

=head2 widget

The following additional arguments are provided:

=over 4

=item field_id

Contains the viewport's event id for C<value_string>.

=item field_name

Defaults to the C<field_id> argument unless already defined

=item field_type

Defaults to C<text>.

=item field_class

A string containing the joined class attribute. Defaults to
C<action-field> and the current viewport's C<name>.

=item exists_event

Contains the event id for C<exists>.

=item exists_value

Defaults to C<1>.

=back

=head2 message_fragment

Renders nothing if the viewport doesn't have a message.

Otherwise, the C<message> argument will be set to the localised string contained
in the viewport's C<message> attribute and the C<message> fragment will be rendered.

=head2 field_is_required

Will render either C<field_is_required_yes> or C<field_is_required_no> depending on
if C<value_is_required> on the viewport returns true and the viewports C<value_string>
is empty.

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/field/mutable.tt

The following layouts are provided:

=over 4

=item widget

Builds a C<span> element with a class attribute set to the C<field_class> argument.
The element contents will be the C<label_fragment>, C<field> and C<message_fragment>
fragments.

=item label

Builds a C<label> element with the C<for> attribute set to the value of C<field_id> and
the other attributes used from the C<field_is_required> argument. The content will be
the C<label> argument.

=item field_is_required_yes

Sets the class attribute to C<required_field>.

=item field_is_required_no

Empty.

=item message

Renders a C<span> element with the C<message> as content.

=item field

Renders the input field. The C<field_body> fragment is used to set the value.

=item field_body

Creates the C<value> attribute for the input element.

=back

=head2 default

  share/skin/default/layout/field/mutable.tt

The following layouts are provided:

=over 4

=item message

Will render the original C<message> fragment followed by a C<br> element.

=back

=head1 SUBCLASSES

=over 4

=item L<Reaction::UI::Widget::Field::Mutable::Boolean>

A widget allowing the manipulation of boolean values.

=item L<Reaction::UI::Widget::Field::Mutable::ChooseMany>

Allows the user to choose many items from a list of available values.

=item L<Reaction::UI::Widget::Field::Mutable::ChooseOne>

Allows the user to choose a single item from a list of available values.

=item L<Reaction::UI::Widget::Field::Mutable::DateTime>

A simple DateTime L<Reaction::UI::Widget::Field::Mutable> subclass.

=item L<Reaction::UI::Widget::Field::Mutable::File>

A simple file input field.

=item L<Reaction::UI::Widget::Field::Mutable::HiddenArray>

Renders an array reference value as a series of hidden fields.

=item L<Reaction::UI::Widget::Field::Mutable::Integer>

A simple integer L<Reaction::UI::Widget::Field::Mutable>.

=item L<Reaction::UI::Widget::Field::Mutable::MatchingPasswords>

Password input requiring that the password be entered twice, e.g. to input a new
password.

=item L<Reaction::UI::Widget::Field::Mutable::Password>

A password input L<Reaction::UI::Widget::Field::Mutable>.

=item L<Reaction::UI::Widget::Field::Mutable::Number>

A simple number L<Reaction::UI::Widget::Field::Mutable> input field.

=item L<Reaction::UI::Widget::Field::Mutable::String>

A simple string L<Reaction::UI::Widget::Field::Mutable> input field.

=item L<Reaction::UI::Widget::Field::Mutable::Text>

A multiline input L<Reaction::UI::Widget::Field::Mutable>.

=back

=head1 SEE ALSO

=over 4

=item * L<Reaction::UI::Widget::Field>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
