package Reaction::UI::Widget::Object::Mutable;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Object';

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::UI::Widget::Object::Mutable - A widget base representing mutable objects

=head1 DESCRIPTION

This is an empty subclass of L<Reaction::UI::Widget::Object>.

=head1 FRAGMENTS

No fragments were implemented in this widget.

=head1 SEE ALSO

=over 4

=item * L<Reaction::UI::Widget::Object>

=item * L<Reaction::UI::Widget::Action>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut

