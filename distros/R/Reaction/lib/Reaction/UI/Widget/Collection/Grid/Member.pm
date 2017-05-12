package Reaction::UI::Widget::Collection::Grid::Member;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Object';

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::UI::Widget::Collection::Grid::Member - A member widget of the Grid widget

=head1 DESCRIPTION

A pure subclass of L<Reaction::UI::Widget::Object> representing a member
in a L<Reaction::UI::Widget::Collection::Grid>.

=head1 FRAGMENTS

This widget defines no additional fragments.

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/collection/grid/member.tt

The following layouts are provided:

=over 4

=item widget

Renders the C<field_list> fragment provided initially by L<Reaction::UI::Widget::Object>.

=item field

Renders the next C<field> fragment in the inheritance hierarchy.

=back

=head2 default

  share/skin/default/layout/collection/grid/member.tt

This layout set extends the C<NEXT> skin in the inheritance hierarchy.

Like with L<Reaction::UI::Widget::Collection::Grid>, the C<default> layout set provides
a table based markup for the abstract view logic defined in the C<base> skin.

The following layouts are provided:

=over 4

=item widget

Renders the next C<widget> fragment surrounded by a C<tr> element.

=item field

Renders the next C<field> fragment surrounded by a C<td> element.

=back

=head1 SEE ALSO

=over 4

=item * L<Reaction::UI::Widget::Collection::Grid>

=item * L<Reaction::UI::Widget::Collection::Grid::Member>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
