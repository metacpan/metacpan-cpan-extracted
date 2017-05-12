package Reaction::UI::Widget::Field::Container;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];

before fragment widget {
  arg name  => $_{viewport}->name;
};

implements fragment maybe_label {
  return unless $_{viewport}->has_label;
  arg label => $_{viewport}->label;
  render 'label';
};

implements fragment field_list {
  render field => over $_{viewport}->fields;
};

implements fragment field {
  render 'viewport';
};

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field::Container - A field containing multiple values

=head1 DESCRIPTION

This widget implements a field containing multiple value viewports found in
the current viewport's C<fields> attribute.

=head1 FRAGMENTS

=head2 widget

Sets the C<name> argument to the viewport's C<name> attribute.

=head2 maybe_label

Sets the C<label> argument to the viewport's C<label> attribute value and
renders the C<label> fragment when the viewport has a label defined.

=head2 field_list

Sequentially renders the C<fields> of the viewport;

=head2 field

Renders the C<field> viewport passed by C<field_list>

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/field/container.tt

The following layouts are provided:

=over 4

=item widget

Renders a C<fieldset> element containing the C<maybe_label> and C<field_list>
fragments.

=item label

Renders a C<legend> element for the C<fieldset> containing the C<label> argument.

=item field

Wraps the next C<field> fragment in a C<span> element.

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut

