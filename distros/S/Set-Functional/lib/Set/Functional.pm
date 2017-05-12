package Set::Functional;

use 5.006;

use Exporter qw{import};

=head1 NAME

Set::Functional - set operations for functional programming

=head1 VERSION

Version 1.04

=cut

our $VERSION = '1.04';

our @EXPORT_OK  = qw{
	setify setify_by
	cartesian
	difference difference_by
	disjoint disjoint_by
	distinct distinct_by
	intersection intersection_by
	symmetric_difference symmetric_difference_by
	union union_by
	is_disjoint is_disjoint_by
	is_equal is_equal_by
	is_equivalent is_equivalent_by
	is_pairwise_disjoint is_pairwise_disjoint_by
	is_proper_subset is_proper_subset_by
	is_proper_superset is_proper_superset_by
	is_subset is_subset_by
	is_superset is_superset_by
};
our %EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 SYNOPSIS

This module provides basic set operations for native lists.  The primary goal
is to take advantage of Perl's native functional programming capabilities
while relying solely on Pure Perl constructs to perform the set operations as
fast as possible.  All of these techniques have been benchmarked against other
common Perl idioms to determine the optimal solution.  These benchmarks can
be found in this package (shortly).

Each function is provided in two forms.  The first form always expects simple
flat data structures of defined elements.  The second form expects a BLOCK
(refered to as a choice function) to evaluate each member of the list to a
defined value to determine how the element is a set member.  These can be
identified by the suffix "_by".  None of these functions check definedness
inline so as to eliminate the costly O(n) operation.  All functions have been
prototyped to give them a native Perl-ish look and feel.

Example usage:

	use Set::Functional ':all';

	# Set Creation
	my @deduped_numbers = setify(1 .. 10, 2 .. 11);
	my @deduped_objects_by_name = setify_by { $_->{name} } ({name => 'fred'}, {name => 'bob'}, {name => 'fred'});

	# Set Operation
	my @all_permutations = cartesian \@arr1, \@arr2, \@arr3, \@arr4;

	my @only_arr1_elements = difference \@arr1, \@arr2, \@arr3, \@arr4;
	my @only_arr1_elements_by_name = difference_by { $_->{name} } \@arr1, \@arr2, \@arr3, \@arr4;

	my @unique_per_set = disjoint \@arr1, \@arr2, \@arr3, \@arr4;
	my @unique_per_set_by_name = disjoint_by { $_->{name} } \@arr1, \@arr2, \@arr3, \@arr4;

	my @unique_elements = distinct \@arr1, \@arr2, \@arr3, \@arr4;
	my @unique_elements_by_name = distinct_by { $_->{name} } \@arr1, \@arr2, \@arr3, \@arr4;

	my @shared_elements = intersection \@arr1, \@arr2, \@arr3, \@arr4;
	my @shared_elements_by_name = intersection_by { $_->{name} } \@arr1, \@arr2, \@arr3, \@arr4;

	my @odd_occuring_elements = symmetric_difference \@arr1, \@arr2, \@arr3, \@arr4;
	my @odd_occuring_elements_by_name = symmetric_difference_by { $_->{name} } \@arr1, \@arr2, \@arr3, \@arr4;

	my @all_elements = union \@arr1, \@arr2, \@arr3, \@arr4;
	my @all_elements_by_name = union_by { $_->{name} } \@arr1, \@arr2, \@arr3, \@arr4;

	# Set Predicates
	my $is_all_of_arr1_distinct_from_arr2 = is_disjoint \@arr1, \@arr2;
	my $is_all_of_arr1_distinct_from_arr2_by_name = is_disjoint_by { $_->{name} } \@arr1, \@arr2;

	my $is_arr1_the_same_as_arr2 = is_equal \@arr1, \@arr2;
	my $is_arr1_the_same_as_arr2_by_name = is_equal_by { $_->{name} } \@arr1, \@arr2;

	my $are_all_sets_mutually_unique = is_pairwise_disjoint \@arr1, \@arr2, \@arr3, \@arr4;
	my $are_all_sets_mutually_unique_by_name = is_pairwise_disjoint_by { $_->{name} } \@arr1, \@arr2, \@arr3, \@arr4;

	my $is_all_of_arr1_in_arr2_but_not_the_same_as_arr2 = is_proper_subset \@arr1, \@arr2;
	my $is_all_of_arr1_in_arr2_but_not_the_same_as_arr2_by_name = is_proper_subset_by { $_->{name} } \@arr1, \@arr2;

	my $is_all_of_arr1_in_arr2 = is_subset \@arr1, \@arr2;
	my $is_all_of_arr1_in_arr2_by_name = is_subset_by { $_->{name} } \@arr1, \@arr2;

	my $is_all_of_arr2_in_arr1_but_not_the_same_as_arr1 = is_proper_superset \@arr1, \@arr2;
	my $is_all_of_arr2_in_arr1_but_not_the_same_as_arr1_by_name = is_proper_superset_by { $_->{name} } \@arr1, \@arr2;

	my $is_all_of_arr2_in_arr1 = is_superset \@arr1, \@arr2;
	my $is_all_of_arr2_in_arr1_by_name = is_superset_by { $_->{name} } \@arr1, \@arr2;

=head1 CONSTRUCTORS

=cut

=head2 setify(@)

Given a list, return a new set.  Order is not guaranteed.

	setify 1 .. 10, 6 .. 15 => 1 .. 15

=cut

sub setify(@) {
	my %set;

	undef @set{@_} if @_;

	return keys %set;
}

=head2 setify_by(&@)

Given a choice function and a list, return a new set defined by the choice
function. Order is not guaranteed.

=cut

sub setify_by(&@){
	my $func = shift;

	my %set;

	@set{ map { $func->($_) } @_ } = @_ if @_;

	return values %set;
}

=head1 OPERATORS

=cut

=head2 cartesian(@)

Given multiple set references, return multiple sets containing all permutations
of one element from each set.  If the empty set is provided, no sets are
returned since the number of sets generated should be the product of the input
sets' cardinalities.  If no sets are provided then none are returned.

	cartesian [1 .. 3], [1 .. 2] => [1,1],[1,2],[2,1],[2,2],[3,1],[3,2]
	cartesin => ()
	cartesin [1 .. 3], [] => ()

=cut

sub cartesian(@) {
	return unless @_;

	my @results;
	my $repetitions = 1;

	($repetitions *= @$_) || return for @_;
	$#results = $repetitions - 1;

	for my $idx (0 .. $#results) {
		$repetitions = @results;
		$results[$idx] = [map { $_->[int($idx/($repetitions /= @$_)) % @$_] } @_];
	}

	return @results;
}

=head2 difference(@)

Given multiple set references, return a new set with all the elements in the first set
that don't exist in subsequent sets.

	difference [1 .. 10], [6 .. 15] => 1 .. 5

=cut

sub difference(@) {
	my $first = shift;

	return unless $first && @$first;

	my %set;

	undef @set{@$first};

	do { delete @set{@$_} if @$_ } for @_;

	return keys %set;
}

=head2 difference_by(&@)

Given a choice function and multiple set references, return a new set with all the elements
in the first set that don't exist in subsequent sets according to the choice function.

=cut

sub difference_by(&@) {
	my $func = shift;
	my $first = shift;

	return unless $first && @$first;

	my %set;

	@set{ map { $func->($_) } @$first } = @$first;

	do { delete @set{ map { $func->($_) } @$_ } if @$_ } for @_;

	return values %set;
}

=head2 disjoint(@)

Given multiple set references, return corresponding sets containing all the elements from
the original set that exist in any set exactly once.

	disjoint [1 .. 10], [6 .. 15] => [1 .. 5], [11 .. 15]

=cut

sub disjoint(@) {
	my %element_to_count;

	do { ++$element_to_count{$_} for @$_ } for @_;

	return map { [grep { $element_to_count{$_} == 1 } @$_] } @_;
}

=head2 disjoint_by(&@)

Given a choice function and multiple set references, return corresponding sets containing
all the elements from the original set that exist in any set exactly once
according to the choice function.

=cut

sub disjoint_by(&@) {
	my $func = shift;

	my %key_to_count;

	do { ++$key_to_count{$func->($_)} for @$_ } for @_;

	return map { [grep { $key_to_count{$func->($_)} == 1 } @$_] } @_;
}

=head2 distinct(@)

Given multiple set references, return a new set containing all the elements that exist
in any set exactly once.

	distinct [1 .. 10], [6 .. 15] => 1 .. 5, 11 .. 15

=cut

sub distinct(@) {
	my %element_to_count;

	do { ++$element_to_count{$_} for @$_ } for @_;

	return grep { $element_to_count{$_} == 1 } keys %element_to_count;
}

=head2 distinct_by(&@)

Given a choice function and multiple set references, return a new set containing all the
elements that exist in any set exactly once according to the choice function.

=cut

sub distinct_by(&@) {
	my $func = shift;

	my %key_to_count;

	for (@_) {
		for (@$_) {
			my $key = $func->($_);
			$key_to_count{$key} = exists $key_to_count{$key} ? undef : $_;
		}
	}

	return grep { defined } values %key_to_count;
}

=head2 intersection(@)

Given multiple set references, return a new set containing all the elements that exist
in all sets.

	intersection [1 .. 10], [6 .. 15] => 6 .. 10

=cut

sub intersection(@) {
	my $first = shift;

	return unless $first && @$first;

	my %set;

	undef @set{@$first};

	for (@_) {
		my @int = grep { exists $set{$_} } @$_;
		return unless @int;
		%set = ();
		undef @set{@int};
	}

	return keys %set;
}

=head2 intersection_by(&@)

Given a choice function and multiple set references, return a new set containing all the
elements that exist in all sets according to the choice function.

=cut

sub intersection_by(&@) {
	my $func = shift;
	my $first = shift;

	return unless $first && @$first;

	my %set;

	@set{ map { $func->($_) } @$first } = @$first;

	for (@_) {
		my @int = grep { exists $set{$func->($_)} } @$_;
		return unless @int;
		%set = ();
		@set{ map { $func->($_) } @int } = @int;
	}

	return values %set;
}

=head2 symmetric_difference(@)

Given multiple set references, return a new set containing all the elements that
exist an odd number of times across all sets.

	symmetric_difference [1 .. 10], [6 .. 15], [4, 8, 12] => 1 .. 5, 8, 11 .. 15

=cut

sub symmetric_difference(@) {
	my $count;
	my %element_to_count;

	do { ++$element_to_count{$_} for @$_ } for @_;

	return grep { $element_to_count{$_} % 2 } keys %element_to_count;
}

=head2 symmetric_difference_by(&@)

Given a choice function and multiple set references, return a new set containing
all the elements that exist an odd number of times across all sets according to
the choice function.

=cut

sub symmetric_difference_by(&@) {
	my $func = shift;

	my $count;
	my %key_to_count;

	do { ++$key_to_count{$func->($_)} for @$_ } for @_;

	return map {
		grep {
			$count = delete $key_to_count{$func->($_)};
			defined($count) && $count % 2
		} @$_
	} @_;
}

=head2 union(@)

Given multiple set references, return a new set containing all the elements that exist
in any set.

	union [1 .. 10], [6 .. 15] => 1 .. 15

=cut

sub union(@) {
	my %set;

	do { undef @set{@$_} if @$_ } for @_;

	return keys %set;
}

=head2 union_by(&@)

Given a choice function and multiple set references, return a new set containing all the
elements that exist in any set according to the choice function.

=cut

sub union_by(&@) {
	my $func = shift;

	my %set;

	do { @set{ map { $func->($_) } @$_ } = @$_ if @$_ } for @_;

	return values %set;
}

=head1 PREDICATES

=cut

=head2 is_disjoint($$)

Given two set references, return true if both sets contain none of the same values.

	is_disjoint [1 .. 5], [6 .. 10] => true
	is_disjoint [1 .. 6], [4 .. 10] => false

=cut

sub is_disjoint($$) {
	my @set = &intersection(@_[0,1]);
	return ! @set;
}

=head2 is_disjoint_by(&$$)

Given a choice function and two sets references, return true if both sets
contain none of the same values according to the choice function.

=cut

sub is_disjoint_by(&$$) {
	my @set = &intersection_by(@_[0,1,2]);
	return ! @set;
}

=head2 is_equal($$)

Given two set references, return true if both sets contain all the same values.
Aliased by is_equivalent.

	is_equal [1 .. 5], [1 .. 5] => true
	is_equal [1 .. 10], [6 .. 15] => false

=cut

sub is_equal($$) {
	my @set = &intersection(@_[0,1]);
	return @set == @{$_[0]} && @set == @{$_[1]};
}
*is_equivalent = \&is_equal;

=head2 is_equal_by(&$$)

Given a choice function and two sets references, return true if both sets
contain all the same values according to the choice function.
Aliased by is_equivalent_by.

=cut

sub is_equal_by(&$$) {
	my @set = &intersection_by(@_[0,1,2]);
	return @set == @{$_[1]} && @set == @{$_[2]};
}
*is_equivalent_by = \&is_equal_by;

=head2 is_pairwise_disjoint(@)

Given multiple set references, return true if every set is disjoint from every
other set.

	is_pairwise_disjoint [1 .. 5], [6 .. 10], [11 .. 15] => true
	is_pairwise_disjoint [1 .. 5], [6 .. 10], [11 .. 15], [3 .. 8] => false

=cut

sub is_pairwise_disjoint(@) {
	my @sets = &disjoint(@_);
	do { return 0 if @{$sets[$_]} != @{$_[$_]} } for 0 .. $#sets;
	return 1;
}

=head2 is_pairwise_disjoint_by(&@)

Given a choice function and multiple set references, return true if every set
is disjoint from every other set according to the choice function.

=cut

sub is_pairwise_disjoint_by(&@) {
	my @sets = &disjoint_by((shift), @_);
	do { return 0 if @{$sets[$_]} != @{$_[$_]} } for 0 .. $#sets;
	return 1;
}

=head2 is_proper_subset($$)

Given two set references, return true if the first set is fully contained by
but is not equivalent to the second.

	is_proper_subset [1 .. 5], [1 .. 10] => true
	is_proper_subset [1 .. 5], [1 .. 5] => false

=cut

sub is_proper_subset($$) {
	my @set = &intersection(@_[0,1]);
	return @set == @{$_[0]} && @set != @{$_[1]};
}

=head2 is_proper_subset_by(&$$)

Given a choice function and two set references, return true if the first set
is fully contained by but is not equivalent to the second according to the
choice function.

=cut

sub is_proper_subset_by(&$$) {
	my @set = &intersection_by(@_[0,1,2]);
	return @set == @{$_[1]} && @set != @{$_[2]};
}

=head2 is_proper_superset($$)

Given two set references, return true if the first set fully contains but is
not equivalent to the second.

	is_proper_superset [1 .. 10], [1 .. 5] => true
	is_proper_superset [1 .. 5], [1 .. 5] => false

=cut

sub is_proper_superset($$) {
	my @set = &intersection(@_[0,1]);
	return @set != @{$_[0]} && @set == @{$_[1]};
}

=head2 is_proper_superset_by(&$$)

Given a choice function and two set references, return true if the first set
fully contains but is not equivalent to the second according to the choice
function.

=cut

sub is_proper_superset_by(&$$) {
	my @set = &intersection_by(@_[0,1,2]);
	return @set != @{$_[1]} && @set == @{$_[2]};
}

=head2 is_subset($$)

Given two set references, return true if the first set is fully contained by
the second.

	is_subset [1 .. 5], [1 .. 10] => true
	is_subset [1 .. 5], [1 .. 5] => true
	is_subset [1 .. 5], [2 .. 11] => false

=cut

sub is_subset($$) {
	my @set = &intersection(@_[0,1]);
	return @set == @{$_[0]};
}

=head2 is_subset_by(&$$)

Given a choice function and two set references, return true if the first set
is fully contained by the second according to the choice function.

=cut

sub is_subset_by(&$$) {
	my @set = &intersection_by(@_[0,1,2]);
	return @set == @{$_[1]};
}

=head2 is_superset($$)

Given two set references, return true if the first set fully contains the
second.

	is_superset [1 .. 10], [1 .. 5] => true
	is_superset [1 .. 5], [1 .. 5] => true
	is_subset [1 .. 5], [2 .. 11] => false

=cut

sub is_superset($$) {
	my @set = &intersection(@_[0,1]);
	return @set == @{$_[1]};
}

=head2 is_superset_by(&$$)

Given a choice function and two set references, return true if the first set
fully contains the second according to the choice function.

=cut

sub is_superset_by(&$$) {
	my @set = &intersection_by(@_[0,1,2]);
	return @set == @{$_[2]};
}

=head1 AUTHOR

Aaron Cohen, C<< <aarondcohen at gmail.com> >>

Special thanks to:
L<Logan Bell|http://metacpan.org/author/logie>
L<Thomas Whaples|https://github.com/twhaples>
L<Dibin Pookombil|https://github.com/dibinp>

=head1 BUGS

Please report any bugs or feature requests to C<bug-set-functional at rt.cpan.org>, or through
the web interface at L<https://github.com/aarondcohen/Set-Functional/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 TODO

=over 4

=item * Add SEE ALSO section

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Set::Functional

You can also look for information at:

=over 4

=item * Official GitHub Repo

L<https://github.com/aarondcohen/Set-Functional>

=item * GitHub's Issue Tracker (report bugs here)

L<https://github.com/aarondcohen/Set-Functional/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Set-Functional>

=item * Official CPAN Page

L<http://search.cpan.org/dist/Set-Functional/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2014 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Set::Functional
