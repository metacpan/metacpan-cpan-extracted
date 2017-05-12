package Reaction::UI::Widget::Collection::Grid;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Collection';

implements fragment header_cells {
  arg 'labels' => $_{viewport}->field_labels;
  render header_cell => over $_{viewport}->computed_field_order;
  if ($_{viewport}->member_action_count) {
    render 'header_action_cell';
  }
};

implements fragment header_cell {
  arg label => localized $_{labels}->{$_};
};

implements fragment header_action_cell {
  arg col_count => $_{viewport}->member_action_count;
};

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::UI::Widget::Collection::Grid - A collection with header and footer

=head1 DESCRIPTION

This widget is a subclass of L<Reaction::UI::Widget::Collection>. Additionally
to its superclass, it provides abstract means of a header and a footer.

=head1 FRAGMENTS

=head2 header_cells

Will set the C<labels> argument to the viewport's C<field_labels> attribute
value.

Afterwards, the C<header_cell> fragment will be rendered once for every entry
in the viewport's C<computed_field_order>.

Additionally, the C<header_action_cell> will be rendered when the current
viewport's C<member_action_count> is larger than 0.

=head2 header_cell

Populates the C<label> argument with a localised value of the C<labels>
hash reference argument. The used key is extracted from the C<_> topic
argument.

=head2 header_action_cell

Populates the C<col_count> argument with the viewports C<member_action_count>
attribute value.

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/collection/grid.tt

The base grid layout set does not provide an markup, just abstract layouting.

The following layouts are provided:

=over 4

=item widget

Renders, in sequence, the C<header>, C<body> and C<footer> fragments.

=item header

Renders the C<header_row> fragment.

=item header_row

Renders the C<header_cells> fragment.

=item header_cell

Renders the C<header_cell_contents> fragment.

=item header_cell_contents

Renders the value of the C<label> argument.

=item header_action_cell

Renders the string C<Actions>.

=item body

Renders the C<members> fragment implemented in L<Reaction::UI::Widget::Collection>.

=back

=head2 default

  share/skin/default/layout/collection/grid.tt

This layout set extends the C<NEXT> in the skin inheritance hierarchy.

It is meant to extend upon the layout set with the same name in the C<base> skin and
provides the same abstract structure but with a table based markup.

The following layouts are provided:

=over 4

=item widget

Renders the next skin's C<widget> fragment surrounded by a C<table> element with the
class attribute C<grid>.

=item header

Renders the next skin's C<header> fragment surrounded by a C<thead> element.

=item header_row

Wrap's the next skin's C<header_row> fragment in a C<tr> element.

=item header_cell

Wrap's the next skin's C<header_cell> fragment in a C<th> element.

=item header_action_cell

Wrap's the next skin's C<header_action_cell> fragment in a C<th> element with a C<colspan>
attribute set to the number of actions found in the C<col_count> attribute

=item body

Wrap's the next skin's C<body> fragment in a C<tbody> element.

=back

=head1 SEE ALSO

=over 4

=item * L<Reaction::UI::Widget::Collection>

=item * L<Reaction::UI::Widget::Collection::Grid::Member>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
