package Reaction::UI::Widget::Value::Image;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];


implements fragment image {
    if($_{viewport}->value_string) {
    arg uri => $_{viewport}->uri;
    render 'has_image';
  } else {
    render 'no_image';
  }
};

__PACKAGE__->meta->make_immutable;

=head1 NAME

Reaction::UI::Widget::Value::Image - An image tag or non-image alternative

=head1 DESCRIPTION

This widget allows you to render an image container that uses different
fragments for available and non-available images.

=head1 FRAGMENTS AND LAYOUTS

=head2 widget

Has only layout implementation. The widget fragment is inherited from
L<Reaction::UI::Widget>. The layout will simply render the
C<image> fragment. This fragment can be overwritten by your own layout to
render, for example, a frame around the image.

=head2 image

Is only implemented in the widget. If the viewport has a true value in
C<value_string>, the C<uri> argument will be set to the value of the C<uri>
attribute or method return value of the viewport, and the C<has_image>
fragment will be rendered. 

If C<value_string> is false, the C<no_image> fragment will be rendered.

=head2 has_image

This is only implemented in the layout file. It contains just an image
tag and will be rendered when the viewport has a true C<value_string>.

=head2 no_image

This has only an empty implementation in the layout file. It will output
nothing and is called when then viewport has a false C<value_string>.

=head1 LAYOUT TEMPLATE

  share/skin/base/layout/value/image.tt

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut


1;
