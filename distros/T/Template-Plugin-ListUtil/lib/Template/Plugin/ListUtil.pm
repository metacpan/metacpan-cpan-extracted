package Template::Plugin::ListUtil;

use List::Util;
use Template::Plugin::Procedural;
use vars qw(@ISA $VERSION);

$VERSION = "0.02";
@ISA = qw(Template::Plugin::Procedural);

=head1 NAME

Template::Plugin::ListUtil - List::Util functions for TT

=head1 SYNOPSIS

  [% mylist = [ 1, 2, 3, 4, 4, 3, 2, 5, 2 ] %]

  [% USE ListUtil %]
  The largest value in our array is [% ListUtil.largest(mylist) %]

  [% USE ListUtilVMethods %]
  The largest value in our array is [% mylist.largest %]

=head1 DESCRIPTION

This module provides a selection of handy functions for dealing with
lists in the Template Toolkit.  Most of the functions are adapted
from those provided by or documented in L<List::Util>, though note
these have been altered in name and function to work better with
the template toolkit.

To access the functions like class methods, simply use the plugin
from within a Template Toolkit template:

  [% USE ListUtil %]

And then call the method against the ListUtil object.

  [% max = ListUtil.largest(mylist) %]

Alternatively you can load the functions as vmethods:

  [% USE ListUtilVMethods %]
  [% max = mylist.largest %]

Using the VMethods plugin as above will cause the vmethods to be in
effect for the current template and all templates called from that
template.  To allow all templates called from any instance of the
Template module load the module from Perl with the 'install'
parameter.

  use Template::Plugin::ListUtilVMethods 'install';

=head1 FUNCTIONS PROVIDED

These are the functions that you can use once you've loaded the
plugin.

=head2 Finding the largest/smallest

=over

=item largest

Return the numerically largest value of the list.

=cut

sub largest { List::Util::max(@{ $_[0] }) }

=item largeststr

Return the largest value of the list, sorted by unicode value

=cut

sub largeststr { List::Util::maxstr(@{ $_[0] }) }

=item smallest

Return the numerically smallest value of the list

=cut

sub smallest { List::Util::min(@{ $_[0] }) }

=item smalleststr

Return the smallest value of the list, sorted by unicode value

=cut

sub smalleststr { List::Util::minstr(@{ $_[0] }) }

=back

=head2 Simple Statistics

=over

=item total

The sum of adding up all the elements in the list

=cut

sub total { List::Util::reduce { $a + $b } @{ $_[0] } }

=item even

Returns true if and only if this list contains an even number
of items, or the list is empty.

=cut

sub even { int(@{ $_[0] } / 2) == (@{ $_[0] } / 2) }

=item odd

Returns true if and only if this list contains an odd number
of items.

=cut

sub odd { int(@{ $_[0] } / 2) != (@{ $_[0] } / 2) }

=item mean

The mathematical mean (numerical average) of the list

=cut

sub mean { total($_[0]) / @{ $_[0] } }

=item mode

Mode returns a list of the most frequently occurring elements
in a list.  For example, for the list:

  ["buffy", "buffy", "willow", "willow", "buffy" ]

The list

  ["buffy"]

Would be returned because "Buffy" occurs more times in the list
than any other element.  However, for some lists have more than
one element that could be consider the most frequent:

  [ 1, 2, 3, 3, 2, 2, 3, 4, 5, 5 ]

In which case C<mode> returns them all:

  [ 2, 3 ]

You can use the virtual method C<first> on the resulting list from
C<mode> to pick an arbitrary value, or the C<mean> function (see above)
to to take an average of the values.

=cut

sub mode
{
  my %hash;
  $hash{ $_ }++ foreach (@{ $_[0] });

  my $list = [];
  my $value = (values %hash)[0];
  foreach my $key (keys %hash)
  {
    if ($hash{ $key } eq $value)
      { push @{$list}, $key }
    elsif ($hash{ $key } > $value )
      { $list = [ $key ]; $value = $hash{ $key }}
  }

  return $list;
}

=item median

Returns a list containing either the middle element of the list (if
the list is odd in length) or the middle two elements of the list (if
the list is even in length.)  To get a mathematical median you should
presort the list (probably with the C<nsort> virtual method) before
you pass it to C<median>.  Like with C<mode> you can use the virtual
method C<first> on the resulting list from C<median> to pick an
arbitrary value, or the C<mean> function (see above) to to take an
average of the values.

=cut

sub median
{
  my $list = shift;
  my $mid  = int(@{ $list } / 2);

  ( even($list) ) ? [ $list->[ $mid - 1], $list->[ $mid ] ]
                  : [ $list->[ $mid ] ]
}

=back

=head2 Randomisation Functions

=over

=item shuffle

Return a new list made up from randomly shuffled elements of the
list passed.

=cut

sub shuffle { [ List::Util::shuffle(@{ $_[0] }) ] }

=item random

Return a random item from the passed list.

=cut

sub random { (@{ $_[0] })[rand(@{ $_[0] })] }

=back

=head2 Truth Functions

=over

=item anytrue / anyfalse

Is at least one item in the list true / false?

=cut

# this function copyright Graham Barr
sub anytrue  { $_ && return 1 for @{ $_[0] }; 0 }

sub anyfalse { $_ || return 1 for @{ $_[0] }; 0 }

=item alltrue / allfalse

Are all items (i.e. every single item) in the list true / false?

=cut

# this function copyright Graham Barr
sub alltrue { $_ || return 0 for @{ $_[0] } ; 1 }

sub allfalse { $_ && return 0 for @{ $_[0] } ; 1 }

=item nonetrue / nonefalse

Is no element in the list true / false?

=cut

# this function copyright Graham Barr
sub nonetrue { $_ && return 0 for @{ $_[0] } ; 1 }

sub nonefalse { $_ || return 0 for @{ $_[0] } ; 1 }

=item notalltrue / notallfalse

Is at least one element in the list false?

=cut

# this function copyright Graham Barr
sub notalltrue { $_ || return 1 for @{ $_[0] } ; 0 }

sub notallfalse { $_ && return 1 for @{ $_[0] } ; 0 }

=item true

How many items are true?

=cut

# this function copyright Graham Barr
sub true { scalar grep { $_ } @{ $_[0] } }

=item false

How many items are false?

=cut

# this function copyright Graham Barr
sub false { scalar grep { !$_ } @{ $_[0] } }

=back

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Uses the List::Util module, by Graham Barr <gbarr@pobox.com>.

Except as indicated in comments in the code, Copyright Mark Fowler
2003; All Rights Reserved.  As indicated by comments in code some code
Copyright Graham Barr (1997-2001).

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-ListUtil>.

=head1 SEE ALSO

L<List::Util> (for doing this in Perl)

L<Template::Plugin::VMethods> (details on how the vmethods are installed)

=cut

1;
