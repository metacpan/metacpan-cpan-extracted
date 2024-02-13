package Set::CrossProduct;
use strict;

use warnings;
use warnings::register;

our $VERSION = '2.009';

=encoding utf8

=head1 NAME

Set::CrossProduct - work with the cross product of two or more sets

=head1 SYNOPSIS

	# unlabeled sets
	my $iterator = Set::CrossProduct->new( ARRAY_OF_ARRAYS );

	# or labeled sets where hash keys are the set names
	my $iterator = Set::CrossProduct->new( HASH_OF_ARRAYS );

	# get the number of tuples
	my $number_of_tuples = $iterator->cardinality;

	# get the next tuple
	my $tuple            = $iterator->get;

	# move back one position
	my $tuple            = $iterator->unget;

	# get the next tuple without resetting
	# the cursor (peek at it)
	my $next_tuple       = $iterator->next;

	# get the previous tuple without resetting
	# the cursor
	my $last_tuple       = $iterator->previous;

	# get a random tuple
	my $tuple            = $iterator->random;

	# in list context returns a list of all tuples
	my @tuples           = $iterator->combinations;

	# in scalar context returns an array reference to all tuples
	my $tuples           = $iterator->combinations;


=head1 DESCRIPTION

Given sets S(1), S(2), ..., S(k), each of cardinality n(1), n(2), ..., n(k)
respectively, the cross product of the sets is the set CP of ordered
tuples such that { <s1, s2, ..., sk> | s1 => S(1), s2 => S(2), ....
sk => S(k). }

If you do not like that description, how about:

Create a list by taking one item from each array, and do that for all
possible ways that can be done, so that the first item in the list is
always from the first array, the second item from the second array,
and so on.

If you need to see it:

	A => ( a, b, c )
	B => ( 1, 2, 3 )
	C => ( foo, bar )

The cross product of A and B and C, A x B x C, is the set of
tuples shown:

	( a, 1, foo )
	( a, 1, bar )
	( a, 2, foo )
	( a, 2, bar )
	( a, 3, foo )
	( a, 3, bar )
	( b, 1, foo )
	( b, 1, bar )
	( b, 2, foo )
	( b, 2, bar )
	( b, 3, foo )
	( b, 3, bar )
	( c, 1, foo )
	( c, 1, bar )
	( c, 2, foo )
	( c, 2, bar )
	( c, 3, foo )
	( c, 3, bar )

In code, it looks like this:

	use v5.26;
	use Set::CrossProduct;

	my $cross = Set::CrossProduct->new( {
		A => [ qw( a b c ) ],
		B => [ qw( 1 2 3 ) ],
		C => [ qw( foo bar ) ],
		} );

	while( my $t = $cross->get ) {
		printf "( %s, %s, %s )\n", $t->@{qw(A B C)};
		}

If one of the sets happens to be empty, the cross product is empty
too.

	A => ( a, b, c )
	B => ( )

In this case, A x B is the empty set, so you'll get no tuples.

This module combines the arrays that give to it to create this
cross product, then allows you to access the elements of the
cross product in sequence, or to get all of the elements at
once. Be warned! The cardinality of the cross product, that is,
the number of elements in the cross product, is the product of
the cardinality of all of the sets.

The constructor, C<new>, gives you an iterator that you can
use to move around the cross product. You can get the next
tuple, peek at the previous or next tuples, or get a random
tuple. If you were inclined, you could even get all of the
tuples at once, but that might be a very large list. This module
lets you handle the tuples one at a time.

I have found this module very useful for creating regression
tests. I identify all of the boundary conditions for all of
the code branches, then choose bracketing values for each of them.
With this module I take all of the values for each test and
create every possibility in the hopes of exercising all of the
code. Of course, your use is probably more interesting. :)

=head2 Class Methods

=over 4

=item * new( [ [ ... ], [ ... ] ])

=item * new( { LABEL => [ ... ], LABEL2 => [ ... ] } )

Given arrays that represent some sets, return a C<Set::CrossProduct>
instance that represents the cross product of those sets. If you don't
provide at least two sets, C<new> returns undef and will emit a warning
if warnings are enabled.

You can create the sets in two different ways: unlabeled and labeled sets.

For unlabeled sets, you don't give them names. You rely on position. To
create this, pass an array of arrays:

	my $unlabeled = Set::CrossProduct->new( [
		[ qw(1 2 3) ],
		[ qw(a b c) ],
		[ qw(! @ $) ],
		] );

When you call C<next>, you get an array ref where the positions in the
tuple correspond to the position of the sets you gave C<new>:

	my $tuple = $unlabeled->next;   #  [ qw(1 a !) ]

For labeled sets, you want to give each set a name. When you ask for a tuple,
you get a hash reference with the labels you choose:

	my $labeled = Set::CrossProduct->new( {
		number => [ qw(1 2 3) ],
		letter => [ qw(a b c) ],
		symbol => [ qw(! @ $) ],
		} );

	my $tuple = $labeled->next;   #  { number => 1, letter => 'a', symbol => '!' }

=cut

# The iterator object is a hash with these keys
#
#	arrays   - holds an array ref of array refs for each list
#   labels   - the names of the set, if applicable
#   labeled  - boolean to note if the sets are labeled or not
#	counters - the current position in each array for generating
#		combinations
#	lengths  - the precomputed lengths of the lists in arrays
#	done     - true if the last combination has been fetched
#	previous - the previous value of counters in case we want
#		to unget something and roll back the counters
#	ungot    - true if we just ungot something--to prevent
#		attempts at multiple ungets which we don't support

sub new {
	my( $class, $constructor_ref ) = @_;

	my $ref_type = ref $constructor_ref;

	my $self = {};

	if( $ref_type eq ref {} ) {
		$self->{labeled} = 1;
		$self->{labels}  = [ sort keys %$constructor_ref ];
		$self->{arrays}  = [ @$constructor_ref{ sort keys %$constructor_ref } ];
		}
	elsif( $ref_type eq ref [] ) {
		$self->{labeled} = 0;
		$self->{arrays}  = $constructor_ref;
		}
	else {
		warnings::warn( "Set::Crossproduct->new takes an array or hash reference" ) if warnings::enabled();
		return;
		}

	my $array_ref = $self->{arrays};
	unless( @$array_ref > 1 ) {
		warnings::warn( "You need at least two sets for Set::CrossProduct to work" ) if warnings::enabled();
		return;
		}

	foreach my $array ( @$array_ref ) {
		unless( ref $array eq ref [] ) {
			warnings::warn( "Each array element or hash value needs to be an array reference" ) if warnings::enabled();
			return;
			}
		}

	$self->{counters} = [ map { 0 }      @$array_ref ];
	$self->{lengths}  = [ map { $#{$_} } @$array_ref ];
	$self->{previous} = [];
	$self->{ungot}    = 1;

	$self->{done}     = grep( $_ == -1, @{ $self->{lengths} } )
		? 1 : 0;

	bless $self, $class;

	return $self;
	}

=back

=head2 Instance methods

=over 4

=cut


sub _decrement {
	my $self = shift;

	my $tail = $#{ $self->{counters} };

	$self->{counters} = $self->_previous( $self->{counters} );
	$self->{previous} = $self->_previous( $self->{counters} );

	return 1;
	}

sub _find_ref {
	my ($self, $which) = @_;

	my $place_func =
		  ($which eq 'next') ? sub { $self->{counters}[shift] }
		: ($which eq 'prev') ? sub { $self->{previous}[shift] }
		: ($which eq 'rand') ? sub { rand(1 + $self->{lengths}[shift]) }
		:                      undef;

	return unless $place_func;

	my @indices = (0 .. $#{ $self->{arrays} });

	if ($self->{labels}) {
		 return +{ map {  $self->{labels}[$_] => ${ $self->{arrays}[$_] }[ $place_func->($_) ]  } @indices } }
	else {
		return [ map {  ${ $self->{arrays}[$_] }[ $place_func->($_) ]  } @indices ]
		}
	}

sub _increment {
	my $self = shift;

	$self->{previous} = [ @{$self->{counters}} ]; # need a deep copy

	my $tail = $#{ $self->{counters} };

	COUNTERS: {
		if( $self->{counters}[$tail] == $self->{lengths}[$tail] ) {
			$self->{counters}[$tail] = 0;
			$tail--;

			if( $tail == 0
				and $self->{counters}[$tail] == $self->{lengths}[$tail] ) {
				$self->done(1);
				return;
				}

			redo COUNTERS;
			}

		$self->{counters}[$tail]++;
		}

	return 1;
	}

sub _previous {
	my $self = shift;

	my $counters = $self->{counters};

	my $tail = $#{ $counters };

	return [] unless grep { $_ } @$counters;

	COUNTERS: {
		if( $counters->[$tail] == 0 ) {
			$counters->[$tail] = $self->{lengths}[$tail];
			$tail--;

			if( $tail == 0 and $counters->[$tail] == 0) {
				$counters = [ map { 0 } 0 .. $tail ];
				last COUNTERS;
				}

			redo COUNTERS;
			}

		$counters->[$tail]--;
		}

	return $counters;
	}

=item * cardinality()

Return the carnality of the cross product.  This is the number
of tuples, which is the product of the number of elements in
each set.

Strict set theorists will realize that this isn't necessarily
the real cardinality since some tuples may be identical, making
the actual cardinality smaller.

=cut

sub cardinality {
	my $self = shift;

	my $product = 1;

	foreach my $length ( @{ $self->{lengths} } ) {
		$product *= ( $length + 1 );
		}

	return $product;
	}

=item * combinations()

In scalar context, returns a reference to an array that contains all
of the tuples of the cross product. In list context, it returns the
list of all tuples. You should probably always use this in scalar
context except for very low cardinalities to avoid huge return values.

This can be quite large, so you might want to check the cardinality
first. The array elements are the return values for C<get>.

=cut

sub combinations {
	my $self = shift;

	my @array = ();

	while( my $ref = $self->get ) {
		push @array, $ref;
		}

	if( wantarray ) { return  @array }
	else            { return \@array }
	}

=item * done()

Without an argument, C<done> returns true if there are no more
combinations to fetch with C<get> and returns false otherwise.

With an argument, it acts as if there are no more arguments to fetch, no
matter the value. If you want to start over, use C<reset_cursor> instead.

=cut

sub done { $_[0]->{done} = 1 if @_ > 1; $_[0]->{done} }

=item * get()

Return the next tuple from the cross product, and move the position
to the tuple after it. If you have already gotten the last tuple in
the cross product, then C<get> returns undef in scalar context and
the empty list in list context.

What you get back depends on how you made the constructor.

For unlabeled sets, you get back an array reference in scalar context
or a list in list context:

For labeled sets, you get back a hash reference in scalar context or a
list of key-value pairs in list context.

=cut

sub get {
	my $self = shift;

	return if $self->done;

	my $next_ref = $self->_find_ref('next');

	$self->_increment;
	$self->{ungot} = 0;

	if( wantarray ) { return (ref $next_ref eq ref []) ? @$next_ref : %$next_ref }
	else            { return $next_ref }
	}

=item * labeled()

Return true if the sets are labeled (i.e. you made the object from
a hash ref). Returns false otherwise. You might use this to figure out
what sort of value C<get> will return.

=cut

sub labeled { !! $_[0]->{labeled} }

=item * next()

Like C<get>, but does not move the pointer.  This way you can look at
the next tuple without affecting your position in the cross product.

=cut

sub next {
	my $self = shift;

	return if $self->done;

	my $next_ref = $self->_find_ref('next');

	if( wantarray ) { return (ref $next_ref eq ref []) ? @$next_ref : %$next_ref }
	else            { return $next_ref }
	}

=item * previous()

Like C<get>, but does not move the pointer.  This way you can look at
the previous tuple without affecting your position in the cross product.

=cut

sub previous {
	my $self = shift;

	my $prev_ref = $self->_find_ref('prev');

	if( wantarray ) { return (ref $prev_ref eq ref []) ? @$prev_ref : %$prev_ref }
	else            { return $prev_ref }
	}

=item * random()

Return a random tuple from the cross product. The return value is the
same as C<get>.

=cut

sub random {
	my $self = shift;

	my $rand_ref = $self->_find_ref('rand');

	if( wantarray ) { return (ref $rand_ref eq ref []) ? @$rand_ref : %$rand_ref }
	else            { return $rand_ref }
	}

=item * reset_cursor()

Return the pointer to the first element of the cross product.

=cut

sub reset_cursor {
	my $self = shift;

	$self->{counters} = [ map { 0 } @{ $self->{counters} } ];
	$self->{previous} = [];
	$self->{ungot}    = 1;
	$self->{done}     = 0;

	return 1;
	}

=item * unget()

Pretend we did not get the tuple we just got.  The next time we get a
tuple, we will get the same thing.  You can use this to peek at the
next value and put it back if you do not like it.

You can only do this for the previous tuple.  C<unget> does not do
multiple levels of unget.

=cut

sub unget {
	my $self = shift;

	return if $self->{ungot};

	$self->{counters} = $self->{previous};

	$self->{ungot} = 1;

	# if we just got the last element, we had set the done flag,
	# so unset it.
	$self->{done}  = 0;

	return 1;
	}

=back

=head1 TO DO

* I need to fix the cardinality method. it returns the total number
of possibly non-unique tuples.

* I'd also like to do something like this:

	use Set::CrossProduct qw(setmap);

	# use setmap with an existing Set::CrossProduct object
	my @array = setmap { ... code ... } $iterator;

	# use setmap with unnamed arrays
	my @array = setmap { [ $_[0], $_[1] ] }
		key => ARRAYREF, key2 => ARRAYREF;

	# use setmap with named arrays
	my @array = setmap { [ $key1, $key2 ] }
		key => ARRAYREF, key2 => ARRAYREF;

	# call apply() with a coderef. If the object had labels
	# (constructed with a hash), you can use those labels in
	# the coderef.
	$set->apply( CODEREF );

=head1 BUGS

* none that I know about (yet)

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/set-crossproduct

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

Matt Miller implemented the named sets feature.

=head1 COPYRIGHT AND LICENSE

Copyright © 2001-2024, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;
