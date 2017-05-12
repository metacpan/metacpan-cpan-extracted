package Reaction::UI::Widget::SiteLayout;

use Reaction::UI::WidgetClass;
use aliased 'Reaction::UI::Widget::Container';
use MooseX::Types::Moose 'HashRef';

use namespace::clean -except => [ qw(meta) ];
extends Container;

after fragment widget {
  arg static_base => $_{viewport}->static_base_uri;
  arg title => $_{viewport}->title;
};

implements fragment meta_info {
  my $self = shift;
  if ( $_{viewport}->meta_info->{'http_header'} ) {
    my $http_header = delete $_{viewport}->meta_info->{'http_header'};
    arg 'http_header' => $http_header;
    render 'meta_http_header' => over [keys %$http_header];
  }
  render 'meta_member' => over [keys %{$_{viewport}->meta_info}];
};

implements fragment meta_http_header {
  arg 'meta_name' => $_;
  arg 'meta_value' => $_{'http_header'}->{$_};
};

implements fragment meta_member {
  arg 'meta_name' => $_;
  arg 'meta_value' => $_{viewport}->meta_info->{$_};
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Reaction::UI::Widget::SiteLayout - The layout of the site as a whole

=head1 DESCRIPTION

This is a subclass of L<Reaction::UI::Widget::Container>. It is generally
used as the widget surrounding the site's content.

=head1 FRAGMENTS

=head2 widget

Additionally provides these arguments after the parent widget fragment
has been rendered:

=over 4

=item static_base

The C<static_base_uri> of the viewport.

=item title

The C<title> attribute value of the viewport.

=back

=head2 meta_info

If the viewports C<meta_info> contains a value for C<http_header>, It will
be removed and set as C<http_header> argument. Next, the C<meta_http_header>
fragment will be rendered for each key of the C<http_header> hash reference.

After the C<http_header> processing, the remaining keys of the viewports
C<meta_info> attribute hash reference will be rendered via the C<meta_member>
fragment.

=head2 meta_http_header

Additionally provides these arguments:

=over 4

=item meta_name

The current value of the C<_> argument, which will be set to the key of
the C<http_header> argument hash reference when rendered by the
C<meta_info> fragment.

=item meta_value

The value of the C<meta_name> key in the C<http_header> argument hash
reference.

=back

=head2 meta_member

Additionally provides these arguments:

=over 4

=item meta_name

The current value of the C<_> argument, which will be set to the key of
the viewport's C<meta_info> attribte value when rendered by the
C<meta_info> fragment.

=item meta_value

The value of the C<meta_name> key in the viewport's C<meta_info> attribute
hash reference.

=back

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/site_layout.tt

The base layout set will provide the following layouts:

=over 4

=item widget

This layout will render the C<doctype> fragment at the top of the page. Then
the traditional HTML layout with a C<html> element containing C<head> (rendering
the C<head> fragment and C<body> (rendering the C<body> fragment) elements.

=item head

Will render the C<title> argument in a C<title> element. After that it will render
the C<head_meta>, C<head_scripts> and C<head_style> fragments.

=item head_meta

Renders the C<meta_info> fragment.

=item meta_http_header

Renders a C<meta> element where the value of the C<http-equiv> attribute is set to
the C<meta_name> argument and the C<content> attribute is set to the C<meta_value>
argument.

=item meta_member

Renders a C<meta> element where the C<name> attribute is set to the C<meta_name>
argument and the C<content> attribute is set to the C<meta_value> argument.

=item head_scripts

Is empty by default.

=item head_style

Is empty by default.

=item doctype

By default this renders an C<XHTML 1.0 Transitional> doctype.

=item body

This will render the C<inner> viewports in the focus stack.

=back

=head2 default

  share/skin/default/layout/site_layout.tt

The C<site_layout> layout set in the C<default> skin extends the one in the
C<base> skin documented above.

The following layouts are provided:

=over 4

=item widget

This layout is mostly the same as the one in the C<base> skin, except that
the C<html> element has C<xmlns> and C<xml:lang> attributes set.

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
