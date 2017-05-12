package Reaction::UI::Widget::Value;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];


before fragment widget {
  if ($_{viewport}->can('value_string')) {
    arg value => $_{viewport}->value_string;
  } elsif($_{viewport}->can('value')) {
    arg value => $_{viewport}->value;
  }
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Value

=head1 DESCRIPTION

This widget provides the return value of the C<vlues_string> or C<value>
method on the viewport (depending on which is available first) via the
C<value> argument to widget.

=head1 INCLUDED SUBCLASSES

=over

=item L<Reaction::UI::Widget::Value::Boolean>

Will simply display the C<value>.

=item L<Reaction::UI::Widget::Value::Collection>

This widget iterates over a collection of values provided by the viewport
and renders an unordered list out of them.

=item L<Reaction::UI::Widget::Value::DateTime>

A simple subclass of L<Reaction::UI::Widget::Value>, currently not doing
much.

=item L<Reaction::UI::Widget::Value::Image>

Provides C<has_image> and C<no_image> blocks that will be rendered depending
on the viewports C<value_string> attribute. The defaults are to either render
an image tag, or to output nothing at all.

=item L<Reaction::UI::Widget::Value::Number>

A simple subclass of C<Reaction::UI::Widget::Value> that doesn't do much yet.

=item L<Reaction::UI::Widget::Value::RelatedObject>

A simple subclass of C<Reaction::UI::Widget::Value> that doesn't do much yet.

=item L<Reaction::UI::Widget::Value::String>

A simple subclass of C<Reaction::UI::Widget::Value> that doesn't do much yet.

=item L<Reaction::UI::Widget::Value::Text>

A simple subclass of C<Reaction::UI::Widget::Value> that doesn't do much yet.

=back

=head1 FRAGMENTS

=head2 widget

Additional available arguments

=over 4

=item B<value> - The C<value_string> or C<value> of the viewport

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
