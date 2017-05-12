package Reaction::UI::Widget::URI;

use Reaction::UI::WidgetClass;
use namespace::clean -except => [ qw(meta) ];

before fragment widget {
  arg uri => $_{viewport}->uri;
};

implements fragment display_fragment {
  my $vp = $_{viewport};
  return unless $vp->has_display;
  my $display = $vp->display;
  if( blessed($display) && $display->isa('Reaction::UI::ViewPort')){
    arg '_' => $display;
    render 'viewport';
  } else {
    arg string_value => $display;
    render 'display_string';
  }
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::URI - A hyperlink reference by URI value

=head1 DESCRIPTION

This widget allows a layout template to render a hyperlink with either a
simple string or another viewport as the contents of the link.

=head1 FRAGMENTS

=head2 widget

Before the C<widget> fragment is rendered, the C<uri> argument will be set
to the return value of the C<uri> method on the viewport. The layout
will render a hyperlink with the C<uri> as value of the C<href> attribute and
the C<display_fragment> fragment as content of the element.

=head2 display_fragment

This will render nothing if the viewport doesn't return true when C<has_display>
is called on it. If it has a C<display> defined and it is a viewport, the C<_>
argument will be set to it and the C<viewport> fragment (inherited from
L<Reaction::UI::Widget> will be rendered. If the C<display> is not a viewport,
the C<string_value> argument will be set and the C<display_string> layout
will be rendered.

C<display_fragment> is only implemented in the widget class.

=head2 display_string

Only implemented in the layout set. This will simply output the value of the
C<string_value> argument as content of the hyperlink element.

=head1 LAYOUT SET

  share/skin/base/layout/uri.tt

This layout set will look for a widget called C<URI> in the 
C<widget_search_path>.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
