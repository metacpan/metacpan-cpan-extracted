package Reaction::UI::Widget::Field::Mutable::HiddenArray;

use Reaction::UI::WidgetClass;

#move this to a normal list and let the hidden part be decided by the template..
use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field::Mutable';

implements fragment hidden_list {
  render hidden_field => over $_{viewport}->value;
};

implements fragment hidden_field {
  # this needs to go here in order to override the field_name from
  # Widget::Field::Mutable::Simple which defaults to value_string and does not
  # make sense for HiddenArray
  arg field_name => event_id 'value';
  arg field_value => $_;
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Mutable::HiddenArray

=head1 DESCRIPTION

See L<Reaction::UI::Widget::Field::Mutable>. This renders a list of values
as a series of hidden fields to transport them across forms.

=head1 FRAGMENTS

=head2 hidden_list

Renders C<hidden_field> over the array reference stored in the viewpoint's
C<value>.

=head2 hidden_field

Sets the C<field_value> argument to the current topic argument C<_>.

=head2 field

renders fragment C<item> over the values of 'value' arrayref

=head2 item

C<content> is $_{_} / $_ (current item in the 'value' array)

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/field/mutable/hidden_array.tt

Provides a C<hidden_field> layout that renders a hidden input element.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
