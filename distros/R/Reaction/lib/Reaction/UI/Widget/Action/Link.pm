package Reaction::UI::Widget::Action::Link;

use Reaction::UI::WidgetClass;

#I want to change this at some point.
use namespace::clean -except => [ qw(meta) ];


before fragment widget {
  arg uri => $_{viewport}->uri;
  arg label => localized $_{viewport}->label;
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Action::Link - A hyperlink representing an object mutation

=head1 DESCRIPTION

=head1 FRAGMENTS

=head2 widget

The following additional arguments are provided:

=over 4

=item uri

The viewport's C<uri>.

=item label

The localised value of the viewport's C<label>.

=back

=head1 LAYOUT SETS

=head2 base

  share/skin/base/layout/action/link.tt

The following layouts are provided:

=over 4

=item widget

Renders a hyperlink with a C<href> attribute set to the C<uri> argument and
the content set to the C<label> argument.

=back

=head2 default

  share/skin/default/layout/action/link.tt

This layout set extends the C<NEXT> layout set with the same name in the parent
skin.

The following layouts are provided:

=over 4

=item widget

Renders a C<br> element after the original C<widget> fragment.

=back

=head1 SEE ALSO

=over 4

=item * L<Reaction::UI::Widget::Action>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
