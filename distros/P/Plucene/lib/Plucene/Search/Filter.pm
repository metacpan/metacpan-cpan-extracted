package Plucene::Search::Filter;

=head1 NAME 

Plucene::Search::Filter - A search filter base class

=head1 DESCRIPTION

This doesn't seem to be being used just yet. But here is some info 
on filters:

Filtering means imposing additional restriction on the hit list to 
eliminate hits that otherwise would be included in the search results. 

There are two ways to filter hits:

=over 4

=item * Search Query - in this approach, provide your custom filter object 
to the when you call the search() method. This filter will be called exactly 
once to evaluate every document that resulted in non zero score.

=item * Selective Collection - in this approach you perform the regular 
search and when you get back the hit list, collect only those that matches 
your filtering criteria. In this approach, your filter is called only for 
hits that returned by the search method which may be only a subset of the 
non zero matches (useful when evaluating your search filter is expensive). 

=back 

=cut

use strict;
use warnings;

=head1 METHODS

=head2 bits

This must be defined in a subclass

=cut

sub bits { die "bits must be defined in a subclass" }

1;
