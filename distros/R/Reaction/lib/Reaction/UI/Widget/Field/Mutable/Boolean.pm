package Reaction::UI::Widget::Field::Mutable::Boolean;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field::Mutable';



after fragment widget {
   arg 'field_type' => 'checkbox';
};

implements fragment is_checked {
  if ($_{viewport}->value_string) {
    render 'is_checked_yes';
  } else {
    render 'is_checked_no';
  }
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Mutable::Boolean - A mutable boolean field

=head1 DESCRIPTION

Provides a widget to manipulate a boolean value. This is a subclass of
L<Reaction::UI::Widget::Field::Mutable>.

=head1 FRAGMENTS

=head2 widget

Will set the argument C<field_type> to C<checkbox>.

=head2 is_checked

Will render the C<is_checked_yes> fragment if the viewport has a true C<value_string>
or C<is_checked_no> if it does not.

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/field/mutable/boolean.tt

This layout set extends the next C<field/mutable> layout set in the skin inheritance.

The following layouts are provided:

=over 4

=item widget

Renders the input element that will be the checkbox.

=item field_body

Sets the value element attribute to 1 and renders the C<is_checked> fragment afterwards.

=item is_checked_yes

Sets the C<checked> attribute of the input element to C<checked>.

=item is_checked_no

Empty.

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
