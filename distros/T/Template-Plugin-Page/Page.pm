package Template::Plugin::Page;

use strict;
use vars qw($VERSION);
use Data::Page;
use Template::Plugin;
use base qw(Template::Plugin);

# This is incremented every time there is a change to the API
$VERSION = '0.10';

=head1 NAME

Template::Plugin::Page - a plugin to help when paging through sets of results

=head1 SYNOPSIS

  [% USE page = Page($total_entries, $entries_per_page, $current_page) %]

           First page: [% page.first_page %]
            Last page: [% page.last_page %]
  First entry on page: [% page.first %]
   Last entry on page: [% page.last %]

=head1 DESCRIPTION

When searching through large amounts of data, it is often the case
that a result set is returned that is larger than we want to display
on one page. This results in wanting to page through various pages of
data. The maths behind this is unfortunately fiddly, hence this
module.

The main concept is that you pass in the number of total entries, the
number of entries per page, and the current page number. You can then
call methods to find out how many pages of information there are, and
what number the first and last entries on the current page really are.

It would be typically used in the following way for an HTML template:

  [% USE page = Page(134, 10, 13) %]
  Matches <b>[% page.first %] - [% page.last %]</b> of
          <b>[% page.total_entries %]</b> records.<BR>

  Page <b>[% page.current_page %]</b> of
       <b>[% page.last_page %]</b><BR>

  [% IF page.previous_page %]
   <a href="index.cgi?page=[% page.previous_page %]">Previous</a>
  [% END %]&nbsp;&nbsp;&nbsp;

  [% IF page.next_page %]
    <a href="index.cgi?page=[% page.next_page %]">Next</a>
  [% END %]

... which would output something like:

  Matches <b>121 - 130</b> of
          <b>134</b> records.<BR>

  Page <b>13</b> of
       <b>14</b><BR>

  <a href="index.cgi?page=12">Previous</a>
  &nbsp;&nbsp;&nbsp;

  <a href="index.cgi?page=14">Next</a>

Note that this module is simply a plugin to the Data::Page module.

=head1 METHODS

=head2 Page

This is the constructor. It currently takes two mandatory arguments,
the total number of entries and the number of entries per page. It
also optionally takes the current page number (which defaults to 1).

  [% USE page = Page(total_entries, entries_per_page, current_page) %]

  [%# or #%]

  [% USE page = Page(134, 10) %]

  [%# or #%]

  [% USE page = Page(134, 10, 5) %]

=cut

sub new {
  my ($proto, $context, $total_entries, $entries_per_page, $current_page) = @_;
  my $class = ref($proto) || $proto;

  ($total_entries, $entries_per_page, $current_page) = ($context, $total_entries, $entries_per_page)
    unless ref($context) eq 'Template::Context';

  my $page = Data::Page->new(
    $total_entries,
    $entries_per_page,
    $current_page);

  return $page;
}


=head2 total_entries

This method returns the total number of entries.

  Total entries: [% page.total_entries %]

=head2 entries_per_page

This method returns the total number of entries per page.

  Entries per page: [% page.entries_per_page %]

=head2 current_page

This method returns the current page number.

  Current page: [% page.current_page %]

=head2 first_page

This method returns the first page. This is put in for reasons of
symmetry with last_page, as it always returns 1.

  Pages range from: [% page.first_page %]

=head2 last_page

This method returns the total number of pages of information. 

  Pages range to: [% page.last_page %]

=head2 first

This method returns the number of the first entry on the current page.

  Showing entries from: [% $page.first %]

=head2 last

This method returns the number of the last entry on the current page.

  Showing entries to: [% page.last %]

=head2 previous_page

This method returns the previous page number, if one exists. Otherwise
it returns undefined.

  Previous page number: [% page.previous_page %]

=head2 next_page

This method returns the next page number, if one exists. Otherwise
it returns undefined.

  Previous page number: [% page.previous_page %]

=head2 splice

This method takes in an listref, and returns only the values which are
on the current page.

  [% visible_holidays = page.splice(holidays) %]

=cut

sub splice {
  my $self = shift;
  my @values = @{(shift)};

  @values = splice(@values, $self->first - 1, $self->entries_per_page);

  return @values;
}


=head1 AUTHOR

Leon Brocard, <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2000-2, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut



1;
