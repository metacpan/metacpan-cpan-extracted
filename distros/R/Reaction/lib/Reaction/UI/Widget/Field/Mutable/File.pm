package Reaction::UI::Widget::Field::Mutable::File;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field::Mutable';



after fragment widget {
  arg field_type => 'file';
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Mutable::File - A file input field

=head1 DESCRIPTION

See L<Reaction::UI::Widget::Field::Mutable>

=head1 FRAGMENTS

=head2 widget

The C<field_type> argument will be set to C<file>.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
