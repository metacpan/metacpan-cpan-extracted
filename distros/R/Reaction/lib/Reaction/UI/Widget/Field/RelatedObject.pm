package Reaction::UI::Widget::Field::RelatedObject;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field';



__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::DisplayField::RelatedObject

=head1 DESCRIPTION

See L<Reaction::UI::Widget::DisplayField>

=head1 FRAGMENTS

=head2 value

C<content> contains the viewport's value_string

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
