package Reaction::UI::Widget::Field::Mutable::Text;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field::Mutable';



__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Mutable::Text - A multiline text input field

=head1 DESCRIPTION

See L<Reaction::UI::Widget::Field::Mutable>

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/field/mutable/text.tt

This layout set renders a C<textarea> element to allow the input
of multiline texts.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
