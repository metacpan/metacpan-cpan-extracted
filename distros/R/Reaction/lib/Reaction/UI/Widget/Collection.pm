package Reaction::UI::Widget::Collection;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];

implements fragment members {
  render member => over $_{viewport}->members;
};

implements fragment member {
  render 'viewport';
};

implements fragment actions {
  render action => over $_{viewport}->actions;
};

implements fragment action {
  render 'viewport';
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::Collection - Render the current viewport's member viewports

=head1 DESCRIPTION

This widget will allow you to render the viewports stored in the current viewports
C<members> attribute.

=head1 FRAGMENTS

=head2 members

Renders the C<member> fragment for every entry in the viewports C<members> attribute.

=head2 member

Renders the C<viewport> fragment, which will in turn render the C<_> argument. That
will be one of the viewports in the current viewport's C<members> attribute when
called from C<members>.

=head1 LAYOUT SETS

  share/skin/base/layout/collection.tt

The following layouts are provided:

=over 4

=item widget

Renders a C<div> element with a class attribute of C<collection_members> and the
C<members> fragment as the content.

=back

=head1 SEE ALSO

=over 4

=item * L<Reaction::UI::Widget::Collection::Grid>

=item * L<Reaction::UI::ViewPort::Collection>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
