package Reaction::UI::Widget::Field::Collection;

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

Reaction::UI::Widget::Field::Collection - A field representing a collection

=head1 DESCRIPTION

This field class will render a collection of values found in the viewport's
C<value_names> and localised before passed to the layout.

=head1 FRAGMENTS

=head2 widget

renders C<label> and C<list> passing additional variable "viewport"

=head2 label

C<content> contains the viewport's label

=head2 list

renders fragment item over the viewport's C<value_names>

=head2 item

C<content> contains the value of the current item ($_ / $_{_})

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/field/collection.tt

The following layouts are provided:

=over 4

=item widget

Renders the C<label_box> and C<list> fragments.

=item label_box

Renders a C<span> element containing the C<label> argument.

=item list

Renders the C<item>s inside a C<div> and C<ul> element.

=item item

Renders the C<name> argument inside a C<li> element.

=back

=head2 default

  share/skin/default/layout/field/collection.tt

This layout set extends the C<NEXT> one in the parent skin.

The following layouts are provided:

=over 4

=item label_box

The same as in the C<base> skin, except the label is surrounded by
a C<strong> element.

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
