package Template::Plugin::Pagination;

$VERSION = '0.90';

use strict;
use Data::Paginated;
use base 'Template::Plugin';

=head1 NAME

Template::Plugin::Pagination - a plugin to help paginate pages of results

=head1 SYNOPSIS

  [% USE page = Pagination(items, current_page, entries_per_page) %]

	[% FOREACH item IN page.page_data; ...; DONE %]

  First page: [% page.first_page %]
  Prev page: [% page.previous_page %]
  Next page: [% page.next_page %]
  Last page: [% page.last_page %]

=head1 DESCRIPTION

This plugin helps you construct pages that include subsets of data from
a list, such as search results which you'll paginated in groups of 10.

It's based heavily on Template::Plugin::Page, which you should see for a
detailed example of to use this. (That module is a thin wrapper around
Data::Page, whereas this one is a wrapper around Data::Paginated, which
is Data::Page + Data::Pageset + some extras).

=head1 METHODS

=head2 new

This is the constructor. It has one mandatory arguments: the list of items
we're working with. You can also pass the page number you're currently
working with which will otherwise default to 1) and the number of entries
there will be on each page (which defaults to 10).

=cut

sub new {
  my ($proto, $context, $list, $current, $per_page) = @_;
  my $class = ref($proto) || $proto;

  ($list, $per_page, $current) = ($context, $list, $per_page)
    unless ref($context) eq 'Template::Context';

  return Data::Paginated->new({
    entries => $list,
    entries_per_page => $per_page || 10,
    current_page => $current || 1,
	});
}

=head1 Pageset Methods

You now have available all the methods from Data::Page, Data::Pageset
	and Data::Paginated, including:

=over 4

=item page_data

=item first_page

=item last_page

=item next_page

=item previous_page

=back

See their manual pages for details.

=head1 AUTHOR

Tony Bowden, <cpan@tmtm.com>

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Template-Plugin-Pagination@rt.cpan.org

=head1 SEE ALSO

L<Template::Plugin::Page>, L<Data::Page>, L<Data::Pageset>, L<Data::Paginated>

=head1 COPYRIGHT

Copyright (C) 2004-2006 Tony Bowden. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself

=cut
