package Reaction::UI::Widget::Value::Collection;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];


before fragment widget {
  arg 'label' => localized $_{viewport}->label;
};

implements fragment list {
  render 'item' => over $_{viewport}->value_names;
};

implements fragment item {
  arg 'name' => localized $_;
};

__PACKAGE__->meta->make_immutable;


1;

__END__;


=head1 NAME

Reaction::UI::Widget::Value::Collection

=head1 DESCRIPTION

This widget provides an additional C<label> argument for the C<widget>
fragment containing the localised value of the viewports C<label> attribute.

It also implements the fragments C<list> and C<item>. 

=head1 FRAGMENTS AND LAYOUTS

=head2 widget

This will set the C<label> argument to the return value of the C<label> method
on the viewport. The base layout will then render the C<list> fragment.

=head2 list

This will render the C<item> fragment once for every entry in the viewports
C<value_names>. The base layout will surround the rendered output with a unordered
list.

=head2 item

This will set the argument C<name> to the localised value of the current iteration
(stored in C<$_>). The base layout will render a list item with the value as
html escaped content of the item.

=head1 LAYOUT SETS

  share/skin/base/layout/value/collection.tt
  share/skin/base/layout/value/list.tt

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
