package Reaction::UI::Widget::Field;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];


before fragment widget {
  if ($_{viewport}->can('value_string')) {
    arg 'field_value' => $_{viewport}->value_string;
  } else {
    arg 'field_value' => ''; #$_{viewport}->value;
  }
};

implements fragment label_fragment {
  if (my $label = $_{viewport}->label) {
    arg label => localized $label;
    render 'label';
  }
};

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::UI::Widget::Field - A simple labelled text field

=head1 DESCRIPTION

This widget renders a simple labelled text field.

=head1 FRAGMENTS

=head2 widget

Sets the C<field_value> argument either to the result of the C<value_string>
method on the viewport, or to an empty string if the viewport does not support
the method.

=head2 label_fragment

Will set the C<label> argument to the localised value of the viewport's C<label>
method and render the C<label> fragment I<if> the viewport's C<label> value
is true.

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/field.tt

The following layouts are provided:

=over 4

=item widget

Renders the C<label_fragment> and C<value_layout> fragments.

=item label

Renders a C<span> element with a C<field_label> class attribute containing the
C<label> argument and a double colon.

=item value_layout

Renders a C<span> element with a C<field_value> class attribute containing the
C<field_value> argument.

=back

=head2 default

  share/skin/default/layout/field.tt

This layout set inherits from the C<NEXT> one in the skin inheritance.

The following layouts are provided:

=item label

The same as in the C<base> skin except that the C<label> argument is surrounded
by a C<strong> element.

=head1 SUBCLASSES

For mutable fields see L<Reaction::UI::Widget::Field::Mutable>.

=over 4

=item L<Reaction::UI::Field::Text>

A simple text subclass of L<Reaction::UI::Field>.

=item L<Reaction::UI::Field::String>

A simple string subclass of L<Reaction::UI::Field>.

=item L<Reaction::UI::Field::RelatedObject>

A simple subclass of L<Reaction::UI::Field>.

=item L<Reaction::UI::Field::Number>

A simple number subclass of L<Reaction::UI::Field>.

=item L<Reaction::UI::Field::Integer>

A simple integer subclass of L<Reaction::UI::Field>.

=item L<Reaction::UI::Field::Image>

A field representing an optional image.

=item L<Reaction::UI::Field::DateTime>

A simple DateTime subclass of L<Reaction::UI::Field>.

=item L<Reaction::UI::Field::Container>

A container field for multiple values.

=item L<Reaction::UI::Field::Collection>

A field containing a collection of localised values.

=item L<Reaction::UI::Field::Boolean>

A simple boolean subclass of L<Reaction::UI::Field>.

=item L<Reaction::UI::Field::Array>

A field representing an array of values, like L<Reaction::UI::Field::Collection>.

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
