package Reaction::UI::Widget::Field::Mutable::DateTime;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field::Mutable';



after fragment widget {
   arg 'field_name' => event_id 'value_string';
 };

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Mutable::DateTime

=head1 DESCRIPTION

See L<Reaction::UI::Widget::Field::Mutable.>

=head1 FRAGMENTS

=head2 widget

Sets C<field_name> to the C<value_string> event id of the viewport.

=head2 field

C<content> contains viewport's C<value_string>.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
