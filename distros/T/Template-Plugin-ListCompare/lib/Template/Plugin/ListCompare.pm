package Template::Plugin::ListCompare;

use strict;
use warnings;
use base qw/Template::Plugin List::Compare/;
use List::Compare;

use 5.008_008;

our $VERSION = 0.05;

sub new {
    my @params  = @_;
    my $class   = shift @params;
    my $context = shift @params;

    my ( $unsorted, $accelerated );

    if ( $params[0] eq '-u' or $params[0] eq '--unsorted' ) {
        $unsorted = shift @params;
    }

    if ( $params[0] eq '-a' or $params[0] eq '--accelerated' ) {
        $accelerated = shift @params;
    }

    #Create arrayrefs from the scalar parameters:
    @params = map { ref($_) eq q{} ? [$_] : $_ } @params;

    if ($accelerated) {
        unshift @params, $accelerated;
    }

    if ($unsorted) {
        unshift @params, $unsorted;
    }

    my $self = List::Compare->new(@params);
    return bless $self, $class;
}

sub get_version { return $VERSION; }

1;

__END__

=head1 NAME

Template::Plugin::ListCompare - Compare the elements of 2 or more lists in a TT template

=head1 VERSION

This is the POD documentation for the version 0.05 of Template::Plugin::ListCompare, written in January 2011.

=head1 SYNOPSIS

The bare essentials:

 [% Llist = ['abel', 'abel', 'baker', 'camera', 'delta', 'edward', 'fargo', 'golfer'] %]
 [% Rlist = ['baker', 'camera', 'delta', 'delta', 'edward', 'fargo', 'golfer', 'hilton'] %]

 [% USE lc = ListCompare(Llist, Rlist) %]

 [% intersection = lc.get_intersection %]
 [% union = lc.get_union %]

... and so forth.

=head1 DESCRIPTION

=head2 Regular Case:  Compare Two Lists

=over 4

=item * Constructor

Create a ListCompare object.  Put the two lists into arrays (named or 
anonymous) and pass references to the arrays to the constructor.

 [% Llist = ['abel', 'abel', 'baker', 'camera', 'delta', 'edward', 'fargo', 'golfer'] %]
 [% Rlist = ['baker', 'camera', 'delta', 'delta', 'edward', 'fargo', 'golfer', 'hilton'] %]

 [% USE lc = ListCompare(Llist, Rlist) %]

By default, ListCompare's methods return lists which are sorted using 
Perl's default C<sort> mode:  ASCII-betical sorting.  Should you
not need to have these lists sorted, you may achieve a speed boost 
by constructing the ListCompare object with the unsorted option:

 [% USE lc = ListCompare('-u', Llist, Rlist) %]

or
 [% USE lc = ListCompare('--unsorted', Llist, Rlist) %]

=item * Alternative Constructor

If you prefer a more explicit delineation of the types of arguments passed 
to a function, you may use this 'single hashref' kind of constructor to build a 
ListCompare object:

 [% USE lc = ListCompare({lists => [Llist, Rlist]}) %]

or

 [% USE lc = ListCompare({
   lists => [Llist, Rlist],
   unsorted => 1,
 }) %]

=item * C<get_intersection()>

Get those items which appear at least once in both lists (their intersection).

 [% intersection = lc.get_intersection %]

=item * C<get_union()>

Get those items which appear at least once in either list (their union).

 [% union = lc.get_union %]

=item * C<get_unique()>

Get those items which appear (at least once) only in the first list.

 [% Lonly = lc.get_unique %]
 [% Lonly = lc.get_Lonly # alias %]

=item * C<get_complement()>

Get those items which appear (at least once) only in the second list.

 [% Ronly = lc.get_complement %]
 [% Ronly = lc.get_Ronly # alias %]

=item * C<get_symmetric_difference()>

Get those items which appear at least once in either the first or the second 
list, but not both.

 [% LorRonly = lc.get_symmetric_difference %]
 [% LorRonly = lc.get_symdiff # alias %]
 [% LorRonly = lc.get_LorRonly # alias %]

=item * C<get_bag()>

Make a bag of all those items in both lists.  The bag differs from the 
union of the two lists in that it holds as many copies of individual 
elements as appear in the original lists.

 [% bag = lc.get_bag %]

=item * Return references rather than lists

These methods are kept in C<Template::Plugin::ListCompare> for symetry with C<List::Compare> but they are not useful.

An alternative approach to the above methods:  If you do not immediately 
require an array as the return value of the method call, but simply need 
a I<reference> to an (anonymous) array, use one of the following 
parallel methods:

 [% intersection_ref = lc.get_intersection_ref %]
[% union_ref = lc.get_union_ref %]
[% Lonly_ref = lc.get_unique_ref %]
[% Lonly_ref = lc.get_Lonly_ref # alias %]
[% Ronly_ref = lc.get_complement_ref %]
[% Ronly_ref = lc.get_Ronly_ref # alias %]
[% LorRonly_ref = lc.get_symmetric_difference_ref %]
[% LorRonly_ref = lc.get_symdiff_ref # alias %]
[% LorRonly_ref = lc.get_LorRonly_ref # alias %]
[% bag_ref = lc.get_bag_ref %]

=item * C<is_LsubsetR()>

Return a true value if the first argument passed to the constructor 
('L' for 'left') is a subset of the second argument passed to the 
constructor ('R' for 'right').

 [% LR = lc.is_LsubsetR %]

Return a true value if R is a subset of L.

 [% RL = lc.is_RsubsetL %]

=item * C<is_LequivalentR()>

Return a true value if the two lists passed to the constructor are 
equivalent, I<i.e.> if every element in the left-hand list ('L') appears 
at least once in the right-hand list ('R') and I<vice versa>.

 [% eqv = lc.is_LequivalentR %]
 [% eqv = lc.is_LeqvlntR # alias %]

=item * C<is_LdisjointR()>

Return a true value if the two lists passed to the constructor are 
disjoint, I<i.e.> if the two lists have zero elements in common (or, what 
is the same thing, if their intersection is an empty set).

 [% disj = lc.is_LdisjointR %]

=item * C<print_subset_chart()>

Pretty-print a chart showing whether one list is a subset of the other.

 [% c.print_subset_chart %]

=item * C<print_equivalence_chart()>

Pretty-print a chart showing whether the two lists are equivalent (same 
elements found at least once in both).

 [% lc.print_equivalence_chart %]

=item * C<is_member_which()>

Determine in I<which> (if any) of the lists passed to the constructor a given 
string can be found. In list context, return a list of those indices in the 
constructor's argument list corresponding to lists holding the string being 
tested.

 [% memb_arr = lc.is_member_which('abel') %]

In the example above, C<@memb_arr> will be:

 ( 0 )

because C<'abel'> is found only in C<@Al> which holds position C<0> in the 
list of arguments passed to C<new()>.

In scalar context, the return value is the number of lists passed to the 
constructor in which a given string is found.

As with other ListCompare methods which return a list, you may wish the 
above method returned a (scalar) reference to an array holding the list:

 [% memb_arr_ref = lc.is_member_which_ref('baker') %]

In the example above, C<$memb_arr_ref> will be:

 [ 0, 1 ]

because C<'baker'> is found in C<@Llist> and C<@Rlist>, which hold positions 
C<0> and C<1>, respectively, in the list of arguments passed to C<new()>.

B<Note:> methods C<is_member_which()> and C<is_member_which_ref> test
only one string at a time and hence take only one argument. To test more 
than one string at a time see the next method, C<are_members_which()>.

=item * C<are_members_which()>

Determine in I<which> (if any) of the lists passed to the constructor one or 
more given strings can be found. The strings to be tested are placed in an 
array (named or anonymous); a reference to that array is passed to the method.

 [% memb_hash_ref = lc.are_members_which(['abel', 'baker', 'fargo', 'hilton', 'zebra']) %]

The return value is a reference to a hash of arrays. The 
key for each element in this hash is the string being tested. Each element's 
value is a reference to an anonymous array whose elements are those indices in 
the constructor's argument list corresponding to lists holding the strings 
being tested. In the examples above, C<$memb_hash_ref> will be:

 {
  abel => [0],
  baker => [0, 1],
  fargo => [0, 1],
  hilton => [1],
  zebra => [],
 }

B<Note:> C<are_members_which()> can take more than one argument; 
C<is_member_which()> and C<is_member_which_ref()> each take only one argument. 
Unlike those two methods, C<are_members_which()> returns a hash reference.

=item * C<is_member_any()>

Determine whether a given string can be found in I<any> of the lists passed as 
arguments to the constructor. Return 1 if a specified string can be found in 
any of the lists and 0 if not.

 [% found = lc.is_member_any('abel') %]

In the example above, C<$found> will be C<1> because C<'abel'> is found in one 
or more of the lists passed as arguments to C<new()>.

=item * C<are_members_any()>

Determine whether a specified string or strings can be found in I<any> of the 
lists passed as arguments to the constructor. The strings to be tested are 
placed in an array (named or anonymous); a reference to that array is passed to 
C<are_members_any>.

 [% memb_hash_ref = lc.are_members_any(['abel', 'baker', 'fargo', 'hilton', 'zebra']) %]

The return value is a reference to a hash where an element's key is the 
string being tested and the element's value is 1 if the string can be 
found in I<any> of the lists and 0 if not. In the examples above, 
C<$memb_hash_ref> will be:

 {
  abel => 1,
  baker => 1,
  fargo => 1,
  hilton => 1,
  zebra => 0,
 }

C<zebra>'s value is C<0> because C<zebra> is not found in either of the lists 
passed as arguments to C<new()>.

=item * C<get_version()>

Return current Template::Plugin::ListCompare version number.

 [% vers = lc.get_version %]

=back

=head2 Accelerated Case: When User Only Wants a Single Comparison

=over 4

=item * Constructor

If you are certain that you will only want the results of a I<single> 
comparison, computation may be accelerated by passing C<'-a'> or 
C<'--accelerated> as the first argument to the constructor.

 [% Llist = ['abel', 'abel', 'baker', 'camera', 'delta', 'edward', 'fargo', 'golfer'] %]
 [% Rlist = ['baker', 'camera', 'delta', 'delta', 'edward', 'fargo', 'golfer', 'hilton'] %]

 [% USE lca = ListCompare('-a', Llist, Rlist) %]

or

 [% USE lca = ListCompare('--accelerated', Llist, Rlist) %]

As with ListCompare's Regular case, should you not need to have 
a sorted list returned by an accelerated ListCompare method, you may 
achieve a speed boost by constructing the accelerated ListCompare object 
with the unsorted option:

 [% USE lca = ListCompare('-u', '-a', Llist, Rlist) %]

or

 [% USE lca = ListCompare('--unsorted', '--accelerated', Llist, Rlist) %]

=item * Alternative Constructor

You may use the 'single hashref' constructor format to build a ListCompare 
object calling for the Accelerated mode:

 [% USE lca = ListCompare({
   lists => [Llist, Rlist],
   accelerated => 1,
 }) %]

or

 [% USE lca = ListCompare({
   lists => [Llist, Rlist],
   accelerated => 1,
   unsorted => 1,
 }) %]

=item * Methods 

All the comparison methods available in the Regular case are available to 
you in the Accelerated case as well.

 [% intersection = lca.get_intersection %]
 [% union = lca.get_union %]
 [% Lonly = lca.get_unique %]
 [% Ronly = lca.get_complement %]
 [% LorRonly = lca.get_symmetric_difference %]
 [% bag = lca.get_bag %]
 [% intersection_ref = lca.get_intersection_ref %]
 [% union_ref = lca.get_union_ref %]
 [% Lonly_ref = lca.get_unique_ref %]
 [% Ronly_ref = lca.get_complement_ref %]
 [% LorRonly_ref = lca.get_symmetric_difference_ref %]
 [% bag_ref = lca.get_bag_ref %]
 [% LR = lca.is_LsubsetR %]
 [% RL = lca.is_RsubsetL %]
 [% eqv = lca.is_LequivalentR %]
 [% disj = lca.is_LdisjointR %]
 [% lca.print_subset_chart %]
 [% lca.print_equivalence_chart %]
 [% memb_arr = lca.is_member_which('abel') %]
 [% memb_arr_ref = lca.is_member_which_ref('baker') %]
 [% memb_hash_ref = lca.are_members_which(['abel', 'baker', 'fargo', 'hilton', 'zebra']) %]
 [% found = lca.is_member_any('abel') %]
[% memb_hash_ref = lca.are_members_any(['abel', 'baker', 'fargo', 'hilton', 'zebra']) %]
 [% vers = lca.get_version %]

All the aliases for methods available in the Regular case are available to 
you in the Accelerated case as well.

=back

=head2 Multiple Case: Compare Three or More Lists

=over 4

=item * Constructor

Create a ListCompare object. Put each list into an array and pass
references to the arrays to the constructor.

 [% Al = ['abel', 'abel', 'baker', 'camera', 'delta', 'edward', 'fargo', 'golfer'] %]
 [% Bob = ['baker', 'camera', 'delta', 'delta', 'edward', 'fargo', 'golfer', 'hilton'] %]
 [% Carmen = ['fargo', 'golfer', 'hilton', 'icon', 'icon', 'jerky', 'kappa'] %]
 [% Don = ['fargo', 'icon', 'jerky'] %]
 [% Ed = ['fargo', 'icon', 'icon', 'jerky'] %]

 [% USE lcm = ListCompare(Al, Bob, Carmen, Don, Ed) %]

As with ListCompare's Regular case, should you not need to have 
a sorted list returned by a List::Compare method, you may achieve a 
speed boost by constructing the object with the unsorted option:

 [% USE lcm = ListCompare('-u', Al, Bob, Carmen, Don, Ed) %]

or

 [% USE lcm = ListCompare('--unsorted', Al, Bob, Carmen, Don, Ed) %]

=item * Alternative Constructor

You may use the 'single hashref' constructor format to build a ListCompare 
object to process three or more lists at once:

 [% USE lcm = ListCompare({
   lists => [Al, Bob, Carmen, Don, Ed],
 }) %]

or

 [% USE lcm = ListCompare({
   lists => [Al, Bob, Carmen, Don, Ed],
   unsorted => 1,
 }) %]

=item * Multiple Mode Methods Analogous to Regular and Accelerated Mode Methods

Each ListCompare method available in the Regular and Accelerated cases 
has an analogue in the Multiple case. However, the results produced 
usually require more careful specification.

B<Note:> Certain of the following methods available in ListCompare's 
Multiple mode take optional numerical arguments where those numbers 
represent the index position of a particular list in the list of arguments 
passed to the constructor. To specify this index position correctly,

=over 4

=item *

start the count at C<0> (as is customary with Perl array indices); and 

=item *

do I<not> count any unsorted option (C<'-u'> or C<'--unsorted'>) preceding 
the array references in the constructor's own argument list.

=back

Example:

 [% USE lcmex = ListCompare('--unsorted', alpha, beta, gamma) %]

For the purpose of supplying a numerical argument to a method which 
optionally takes such an argument, C<'--unsorted'> is skipped, C<@alpha> 
is C<0>, C<@beta> is C<1>, and so forth.

=over 4

=item * C<get_intersection()>

Get those items found in I<each> of the lists passed to the constructor 
(their intersection):

 [% intersection = lcm.get_intersection %]

=item * C<get_union()>

Get those items found in I<any> of the lists passed to the constructor 
(their union):

 [% union = lcm.get_union %]

=item * C<get_unique()>

To get those items which appear only in I<one particular list,> provide 
C<get_unique()> with that list's index position in the list of arguments 
passed to the constructor (not counting any C<'-u'> or C<'--unsorted'> 
option).

Example: C<@Carmen> has index position C<2> in the constructor's C<@_>. 
To get elements unique to C<@Carmen>: 

 [% Lonly = lcm.get_unique(2) %]

If no index position is passed to C<get_unique()> it will default to 0 
and report items unique to the first list passed to the constructor.

=item * C<get_complement()>

To get those items which appear in any list I<other than one particular 
list,> provide C<get_complement()> with that list's index position in 
the list of arguments passed to the constructor (not counting any 
C<'-u'> or C<'--unsorted'> option).

Example: C<@Don> has index position C<3> in the constructor's C<@_>. 
To get elements not found in C<@Don>: 

 [% Ronly = lcm.get_complement(3) %]

If no index position is passed to C<get_complement()> it will default to 
0 and report items found in any list other than the first list passed 
to the constructor.

=item * C<get_symmetric_difference()>

Get those items each of which appears in I<only one> of the lists 
passed to the constructor (their symmetric_difference);

 [% LorRonly = lcm.get_symmetric_difference %]

=item * C<get_bag()>

Make a bag of all items found in any list. The bag differs from the 
lists' union in that it holds as many copies of individual elements 
as appear in the original lists.

 [% bag = lcm.get_bag %]

=item * Return reference instead of list

These methods are kept in C<Template::Plugin::ListCompare> for symetry with C<List::Compare> but they are not useful.

An alternative approach to the above methods: If you do not immediately 
require an array as the return value of the method call, but simply need 
a I<reference> to an array, use one of the following parallel methods:

 [% intersection_ref = lcm.get_intersection_ref %]
 [% union_ref = lcm.get_union_ref %]
 [% Lonly_ref = lcm.get_unique_ref(2) %]
 [% Ronly_ref = lcm.get_complement_ref(3) %]
 [% LorRonly_ref = lcm.get_symmetric_difference_ref %]
 [% bag_ref = lcm.get_bag_ref %]

=item * C<is_LsubsetR()>

To determine whether one particular list is a subset of another list 
passed to the constructor, provide C<is_LsubsetR()> with the index 
position of the presumed subset (ignoring any unsorted option), followed 
by the index position of the presumed superset. 

Example: To determine whether C<@Ed> is a subset of C<@Carmen>, call:

 [% LR = lcm.is_LsubsetR(4,2) %]

A true value (C<1>) is returned if the left-hand list is a subset of the 
right-hand list; a false value (C<0>) is returned otherwise.

If no arguments are passed, C<is_LsubsetR()> defaults to C<(0,1)> and 
compares the first two lists passed to the constructor.

=item * C<is_LequivalentR()>

To determine whether any two particular lists are equivalent to each 
other, provide C<is_LequivalentR> with their index positions in the 
list of arguments passed to the constructor (ignoring any unsorted option).

Example: To determine whether C<@Don> and C<@Ed> are equivalent, call:

 [% eqv = lcm.is_LequivalentR(3,4) %]

A true value (C<1>) is returned if the lists are equivalent; a false value 
(C<0>) otherwise. 

If no arguments are passed, C<is_LequivalentR> defaults to C<(0,1)> and 
compares the first two lists passed to the constructor.

=item * C<is_LdisjointR()>

To determine whether any two particular lists are disjoint from each other 
(I<i.e.,> have no members in common), provide C<is_LdisjointR> with their 
index positions in the list of arguments passed to the constructor 
(ignoring any unsorted option).

Example: To determine whether C<@Don> and C<@Ed> are disjoint, call:

 [% disj = lcm.is_LdisjointR(3,4) %]

A true value (C<1>) is returned if the lists are equivalent; a false value 
(C<0>) otherwise. 

If no arguments are passed, C<is_LdisjointR> defaults to C<(0,1)> and 
compares the first two lists passed to the constructor.

=item * C<print_subset_chart()>

Pretty-print a chart showing the subset relationships among the various 
source lists:

 [% lcm.print_subset_chart %]

=item * C<print_equivalence_chart()>

Pretty-print a chart showing the equivalence relationships among the 
various source lists:

 [% lcm.print_equivalence_chart %]

=item * C<is_member_which()>

Determine in I<which> (if any) of the lists passed to the constructor a given 
string can be found. In list context, return a list of those indices in the 
constructor's argument list (ignoring any unsorted option) corresponding to i
lists holding the string being tested.

 [% memb_arr = lcm.is_member_which('abel') %]

In the example above, C<@memb_arr> will be:

 (0)

because C<'abel'> is found only in C<@Al> which holds position C<0> in the 
list of arguments passed to C<new()>.

=item * C<is_member_which_ref()>

As with other ListCompare methods which return a list, you may wish the 
above method returned a (scalar) reference to an array holding the list:

 [% memb_arr_ref = lcm.is_member_which_ref('jerky') %]

In the example above, C<$memb_arr_ref> will be:

 [3, 4]

because C<'jerky'> is found in C<@Don> and C<@Ed>, which hold positions 
C<3> and C<4>, respectively, in the list of arguments passed to C<new()>.

B<Note:> methods C<is_member_which()> and C<is_member_which_ref> test
only one string at a time and hence take only one argument. To test more 
than one string at a time see the next method, C<are_members_which()>.

=item * C<are_members_which()>

Determine in C<which> (if any) of the lists passed to the constructor one or 
more given strings can be found. The strings to be tested are placed in an 
anonymous array, a reference to which is passed to the method.

 [% memb_hash_ref = lcm.are_members_which(['abel', 'baker', 'fargo', 'hilton', 'zebra']) %]

The return value is a reference to a hash of arrays. The 
key for each element in this hash is the string being tested. Each element's 
value is a reference to an anonymous array whose elements are those indices in 
the constructor's argument list corresponding to lists holding the strings 
being tested. 

In the two examples above, C<$memb_hash_ref> will be:

 {
   abel => [0],
   baker => [0, 1],
   fargo => [0, 1, 2, 3, 4],
   hilton => [1, 2],
   zebra => [],
 }

B<Note:> C<are_members_which()> can take more than one argument; 
C<is_member_which()> and C<is_member_which_ref()> each take only one argument. 
C<are_members_which()> returns a hash reference; the other methods return 
either a list or a reference to an array holding that list, depending on 
context.

=item * C<is_member_any()>

Determine whether a given string can be found in I<any> of the lists passed as 
arguments to the constructor.

 [% found = lcm.is_member_any('abel') %]

Return C<1> if a specified string can be found in I<any> of the lists 
and C<0> if not.

In the example above, C<$found> will be C<1> because C<'abel'> is found in one 
or more of the lists passed as arguments to C<new()>.

=item * C<are_members_any()>

Determine whether a specified string or strings can be found in I<any> of the 
lists passed as arguments to the constructor. The strings to be tested are 
placed in an array (anonymous or named), a reference to which is passed to 
the method.

 [% memb_hash_ref = lcm.are_members_any(['abel', 'baker', 'fargo', 'hilton', 'zebra']) %]

The return value is a reference to a hash where an element's key is the 
string being tested and the element's value is 1 if the string can be 
found in C<any> of the lists and 0 if not. 
In the two examples above, C<$memb_hash_ref> will be:

 {
   abel => 1,
   baker => 1,
   fargo => 1,
   hilton => 1,
   zebra => 0,
 }

C<zebra>'s value will be C<0> because C<zebra> is not found in any of the 
lists passed as arguments to C<new()>.

=item * C<get_version()>

Return current ListCompare version number:

 [% vers = lcm.get_version %]

=back

=item * Multiple Mode Methods Not Analogous to Regular and Accelerated Mode Methods

=over 4

=item * C<get_nonintersection()>

Get those items found in I<any> of the lists passed to the constructor which 
do I<not> appear in I<all> of the lists (I<i.e.,> all items except those found 
in the intersection of the lists):

 [% nonintersection = lcm.get_nonintersection %]

=item * C<get_shared()>

Get those items which appear in more than one of the lists passed to the 
constructor (I<i.e.,> all items except those found in their symmetric 
difference);

 [% shared = lcm.get_shared %]

=item * C<get_nonintersection_ref()>

If you only need a reference to an array as a return value rather than a 
full array, use the following alternative methods:

 [% nonintersection_ref = lcm.get_nonintersection_ref %]
 [% shared_ref = lcm.get_shared_ref %]

=item * C<get_unique_all()>

Get a reference to an array of array references where each of the interior 
arrays holds the list of those items I<unique> to the list passed to the 
constructor with the same index position.

 [% unique_all_ref = lcm.get_unique_all %]

In the example above, C<$unique_all_ref> will hold:

 [
   ['abel'],
   [],
   ['jerky'],
   [],
   [],
 ]

=item * C<get_complement_all()>

Get a reference to an array of array references where each of the interior 
arrays holds the list of those items in the I<complement> to the list 
passed to the constructor with the same index position.

 [% complement_all_ref = lcm.get_complement_all %]

In the example above, C<$complement_all_ref> will hold:

 [
   ['hilton', 'icon', 'jerky'],
   ['abel', 'icon', 'jerky'],
   ['abel', 'baker', 'camera', 'delta', 'edward'],
   ['abel', 'baker', 'camera', 'delta', 'edward', 'jerky'],
   ['abel', 'baker', 'camera', 'delta', 'edward', 'jerky'],
 ]

=back

=back

=head2 Multiple Accelerated Case: Compare Three or More Lists but Request Only a Single Comparison among the Lists

=over 4

=item * Constructor

If you are certain that you will only want the results of a single 
comparison among three or more lists, computation may be accelerated 
by passing C<'-a'> or C<'--accelerated> as the first argument to 
the constructor.

 [% Al = ['abel', 'abel', 'baker', 'camera', 'delta', 'edward', 'fargo', 'golfer'] %]
 [% Bob = ['baker', 'camera', 'delta', 'delta', 'edward', 'fargo', 'golfer', 'hilton'] %]
 [% Carmen = ['fargo', 'golfer', 'hilton', 'icon', 'icon', 'jerky', 'kappa'] %]
 [% Don = ['fargo', 'icon', 'jerky'] %]
 [% Ed = ['fargo', 'icon', 'icon', 'jerky'] %]

 [% USE lcma = ListCompare('-a', Al, Bob, Carmen, Don, Ed) %]

As with ListCompare's other cases, should you not need to have 
a sorted list returned by a ListCompare method, you may achieve a 
speed boost by constructing the object with the unsorted option:

 [% USE lcma = ListCompare('-u', '-a', Al, Bob, Carmen, Don, Ed) %]

or

 [% USE lcma = ListCompare('--unsorted', '--accelerated', Al, Bob, Carmen, Don, Ed) %]

As was the case with ListCompare's Multiple mode, do not count the 
unsorted option (C<'-u'> or C<'--unsorted'>) or the accelerated option 
(C<'-a'> or C<'--accelerated'>) when determining the index position of 
a particular list in the list of array references passed to the constructor.

Example:

 [% USE lcmaex = ListCompare('--unsorted', '--accelerated', alpha, beta, gamma) %]

=item * Alternative Constructor

The 'single hashref' format may be used to construct a ListCompare 
object which calls for accelerated processing of three or more lists at once:

 [% USE lcmaex = ListCompare({
   accelerated => 1,
   lists => [alpha, beta, gamma],
 }) %]

or

 [% USE lcmaex = ListCompare({
   unsorted => 1,
   accelerated => 1,
   lists => [alpha, beta, gamma],
 }) %]

=item * Methods

For the purpose of supplying a numerical argument to a method which 
optionally takes such an argument, C<'--unsorted'> and C<'--accelerated> 
are skipped, C<@alpha> is C<0>, C<@beta> is C<1>, and so forth. To get a 
list of those items unique to C<@gamma>, you would call:

 [% gamma_only = lcmaex.get_unique(2) %]

=back

=head2 Passing Seen-hashes to the Constructor Instead of Arrays

=over 4

=item * When Seen-Hashes Are Already Available to You

Suppose that in a particular Perl program, you had to do extensive munging of 
data from an external source and that, once you had correctly parsed a line 
of data, it was easier to assign that datum to a hash than to an array. 
More specifically, suppose that you used each datum as the key to an element 
of a lookup table in the form of a I<seen-hash>:

 [% Llist = ( #array
   abel => 2,
   baker => 1,
   camera => 1,
   delta => 1,
   edward => 1,
   fargo => 1,
   golfer => 1,
 ) %]

 [% Rlist = ( #hash
   baker => 1,
   camera => 1,
   delta => 2,
   edward => 1,
   fargo => 1,
   golfer => 1,
   hilton => 1,
 ) %]

In other words, suppose it was more convenient to compute a lookup table 
I<implying> a list than to compute that list explicitly.

Since in almost all cases ListCompare takes the elements in the arrays 
passed to its constructor and I<internally> assigns them to elements in a 
seen-hash, why shouldn't you be able to pass (references to) seen-hashes 
I<directly> to the constructor and avoid unnecessary array 
assignments before the constructor is called?

=item * Constructor

You can now do so:

[% USE lcsh = ListCompare(Llist, Rlist);

=item * Methods

I<All> of ListCompare's output methods are supported I<without further 
modification> when references to seen-hashes are passed to the constructor.

 [% intersection = lcsh.get_intersection %]
 [% union = lcsh.get_union %]
 [% Lonly = lcsh.get_unique %]
 [% Ronly = lcsh.get_complement %]
 [% LorRonly = lcsh.get_symmetric_difference %]
 [% bag = lcsh.get_bag %]
 [% intersection_ref = lcsh.get_intersection_ref %]
 [% union_ref = lcsh.get_union_ref %]
 [% Lonly_ref = lcsh.get_unique_ref %]
 [% Ronly_ref = lcsh.get_complement_ref %]
 [% LorRonly_ref = lcsh.get_symmetric_difference_ref %]
 [% bag_ref = lcsh.get_bag_ref %]
 [% LR = lcsh.is_LsubsetR %]
 [% RL = lcsh.is_RsubsetL %]
 [% eqv = lcsh.is_LequivalentR %]
 [% disj = lcsh.is_LdisjointR %]
 [% lcsh.print_subset_chart %]
 [% lcsh.print_equivalence_chart %]
 [% memb_arr = lsch.is_member_which('abel') %]
 [% memb_arr_ref = lsch.is_member_which_ref('baker') %]
 [% memb_hash_ref = lsch.are_members_which(['abel', 'baker', 'fargo', 'hilton', 'zebra']) %]
 [% found = lsch.is_member_any('abel') %]
 [% memb_hash_ref = lsch.are_members_any(['abel', 'baker', 'fargo', 'hilton', 'zebra']) %]
 [% vers = lcsh.get_version %]
 [% unique_all_ref = lcsh.get_unique_all() %]
 [% complement_all_ref = lcsh.get_complement_all() %]

=item * Accelerated Mode and Seen-Hashes

To accelerate processing when you want only a single comparison among two or 
more lists, you can pass C<'-a'> or C<'--accelerated> to the constructor 
before passing references to seen-hashes.

 [% USE lcsha = ListCompare('-a', Llist, Rlist) #2 hashes %]

To compare three or more lists simultaneously, pass three or more references 
to seen-hashes. Thus,

 [% USE lcshm = ListCompare(Alpha, Beta, Gamma) # 3 hashes %]

will generate meaningful comparisons of three or more lists simultaneously.

=item * Unsorted Results and Seen-Hashes

If you do not need sorted lists returned, pass C<'-u'> or C<--unsorted> to the 
constructor before passing references to seen-hashes.

 [% USE lcshu = ListCompare('-u', Llist, Rlist) %]
 [% USE lcshau = ListCompare('-u', '-a', Llist, Rlist) %]
 [% USE lcshmu = ListCompare('--unsorted', Alpha, Beta, Gamma) %]

As was true when we were using ListCompare's Multiple and Multiple Accelerated 
modes, do not count any unsorted or accelerated option when determining the 
array index of a particular seen-hash reference passed to the constructor.

=item * Alternative Constructor

The 'single hashref' form of constructor is also available to build 
ListCompare objects where seen-hashes are used as arguments:

 [% USE lcshu = ListCompare({
   unsorted => 1,
   lists => [Llist, Rlist],
 }) %]

 [% USE lcshau = ListCompare({
   unsorted => 1,
   accelerated => 1,
   lists => [Llist, Rlist],
 }) %]

 [% USE lcshmu = ListCompare({
   unsorted => 1,
   lists => [Alpha, Beta, Gamma],
 }) %]

=back

=head1 PRINCIPLES

ListCompare is a Template-Toolkit plugin that offers access to L<List::Compare|List::Compare> module. Even this POD documentation mirrors the documentation of List::Compare. (I hope all the methods work fine when used in a TT template.)

=head1 SUBROUTINES/METHODS

=over

=item * new()

The object constructor C<new()> shouldn't be specified explicitly because it is called automaticly when using [% USE lc = ListCompare(Llist, Rlist) %].

=item * get_version()

The method get_version was overwritten for beeing able to provide the version of C<Template::Plugin::ListCompare> and not the version of underlying L<List::Compare|List::Compare>.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

No configuration needed.

=head1 DEPENDENCIES

L<Template::Plugin|Template::Plugin>, L<List::Compare|List::Compare>

=head1 SEE ALSO

L<List::Compare|List::Compare>, L<Array::Utils|Array::Utils>, L<Array::Compare|Array::Compare>, L<List::Util|List::Util>, L<Set::Scalar|Set::Scalar>, L<Set::Bag|Set::Bag>, L<Set::Array|Set::Array>, L<Algorithm::Diff|Algorithm::Diff>

=head1 INCOMPATIBILITIES

No known incompatibilities

=head1 AUTHOR

Octavian Rasnita, C<< <orasnita at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to 
C<bug-template-plugin-listcompare at rt.cpan.org>, or through the web interface at 

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-ListCompare>.

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::ListCompare

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-ListCompare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-ListCompare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plugin-ListCompare>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-ListCompare/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Octavian Rasnita.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
