package Reaction::UI::Widget::Field::Image;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Field';


 
implements fragment image {
  if($_{viewport}->value_string) {
    arg uri => $_{viewport}->uri;
    render 'has_image';
  } else {
    render 'no_image';
  }
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Reaction::UI::Widget::Field::Image - An image field

=head1 DESCRIPTION

This L<Reaction::UI::Widget::Field> widget represents an image.

=head1 FRAGMENTS

=head2 image

If the viewport's C<value_string> is true, it will render the C<has_image>
fragment after setting the C<uri> argument to the value of the viewport's
C<uri>.

If the C<value_string> is false the C<no_image> fragment will be rendered.

=head1 SEE ALSO

=over 4

=item * L<Reaction::UI::Widget::Field>

=item * L<Reaction::UI::Widget::Value::Image>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
