package Reaction::UI::Widget::ListView;

use Reaction::UI::WidgetClass;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::Widget::Collection::Grid';

after fragment widget {
  arg pager_obj => $_{viewport}->pager;
};

implements fragment pager_fragment {
  my $pager = $_{pager_obj};
  if( $pager->last_page > $pager->first_page ) {
    render 'pager';
  }
};

implements fragment maybe_sortable_header_cell {
  my $vp = $_{viewport};
  if( $_{viewport}->can_order_by($_) ){
    my $current = $vp->order_by;
    my $desc = ( $vp->order_by_desc || ( $current || '') ne $_) ? 0 : 1;
    arg order_uri => event_uri { order_by => $_, order_by_desc => $desc };
    render 'sortable_header_cell';
  } else {
    render 'header_cell_contents';
  }
};

implements fragment page_list {
  render numbered_page_fragment
    => over [ $_{pager_obj}->first_page .. $_{pager_obj}->last_page ];
};

implements fragment numbered_page_fragment {
  arg page_uri => event_uri { page => $_ };
  arg page_number => $_;
  if ($_{pager_obj}->current_page == $_) {
    render 'numbered_page_this_page';
  } else {
    render 'numbered_page';
  }
};

implements fragment first_page {
  arg page_uri => event_uri { page => $_{pager_obj}->first_page };
  arg page_name => 'First';
  render 'named_page';
};

implements fragment last_page {
  arg page_uri => event_uri { page => $_{pager_obj}->last_page };
  arg page_name => localized 'Last';
  render 'named_page';
};

implements fragment next_page {
  arg page_name => localized 'Next';
  if (my $page = $_{pager_obj}->next_page) {
    arg page_uri => event_uri { page => $page };
    render 'named_page';
  } else {
    render 'named_page_no_page';
  }
};

implements fragment previous_page {
  arg page_name => localized 'Previous';
  if (my $page = $_{pager_obj}->previous_page) {
    arg page_uri => event_uri { page => $page };
    render 'named_page';
  } else {
    render 'named_page_no_page';
  }
};

__PACKAGE__->meta->make_immutable;


1;

__END__;

=head1 NAME

Reaction::UI::Widget::ListView - Extends Grid to a full list interface

=head1 DESCRIPTION

This class is a subclass of L<Reaction::UI::ViewPort::Collection::Grid>. It additionally
provides means of paging and actions.

=head1 FRAGMENTS

=head2 widget

Additional arguments available:

=over 4

=item B<pager_obj> - The C<pager> object of the viewport

=back

=head2 actions

Render the C<action> fragment for every action in the viewport.

=head2 action

Renders the C<action> viewport passed

=head2 header_cells

Adds a modifier to render the actions column after the data columns

=head2 header_cell

Modify the header_cell fragment to add support for ordering

Additional arguments available:

=over 4

=item B<order_uri> - A URI to the collection view which will order the members
using this field. Will toggle ascending / descending order.

=back

=head2 header_action_cell

Additional arguments available:

=over 4

=item B<col_count> - Column width to span

=back

=head2 page_list

Will sequentially render a C<numbered_page_fragment> for every page available in
 the pager object

=head2 numbered_page_fragment

Renders a link pointing to the different pages in the pager object. If the current
page number is equal to the page number for the page being rendered then the
template block C<numbered_page_this_page> is called instead of C<numbered_page>

Additional arguments available:

=over 4

=item B<page_uri> - The URI to the page

=item B<page_number> - The number of the page

=back

=head2 first_page

=head2 last_page

=head2 next_page

=head2 previous_page

Render links to the first, last, next and previous pages, respectively. All four will
render as the C<named_page> template fragment, unless the current page is the last
and/or first page, in which case the first and last fragments will render as
C<named_page_no_page>

Additional arguments available:

=over 4

=item B<page_uri> - The URI to the page

=item B<page_number> - The label of the page (First / Last / Next / Previous)

=back


=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
