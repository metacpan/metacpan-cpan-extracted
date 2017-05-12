package Reaction::UI::Widget::Image;

use Reaction::UI::WidgetClass;
use namespace::clean -except => [ qw(meta) ];

before fragment widget {
  my $vp = $_{viewport};
  my $attrs = {
    src => $vp->uri,
    ($vp->has_width ? (width => $vp->width) : ()),
    ($vp->has_height ? (height => $vp->height) : ()),
  };
  arg img_attrs => attrs( $attrs );
};

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Reaction::UI::Widget::Image - An image with optional height and width properties

=head1 DESCRIPTION

=head1 FRAGMENTS

=head2 widget

The widget layout will be provided with an additional C<img_attrs> argument containing
a rendered string of the image's attributes containing:

=over 4

=item src

The return value of the viewports C<uri> method.

=item width

The value of the viewports C<width> attribute if one was found.

=item height

The value of the viewports C<height> attribute if one was found.

=back

=head1 LAYOUT SETS

  share/skin/base/layout/image.tt

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
