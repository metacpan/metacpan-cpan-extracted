package Set::CrossProduct;
use strict;

use warnings;
use warnings::register;

use Carp qw(carp);
use List::Util qw( reduce );

our $VERSION = '3.001';

=encoding utf8

=head1 NAME

Set::CrossProduct - work with the cross product of two or more sets

=head1 SYNOPSIS

	# unlabeled sets
	my $cross = Set::CrossProduct->new( ARRAY_OF_ARRAYS );

	# or labeled sets where hash keys are the set names
	my $cross = Set::CrossProduct->new( HASH_OF_ARRAYS );

	# get the number of tuples
	my $number_of_tuples = $cross->cardinality;

	# get the next tuple
	my $tuple            = $cross->get;

	# move back one position
	my $tuple            = $cross->unget;

	# get the next tuple without resetting
	# the cursor (peek at it)
	my $next_tuple       = $cross->next;

	# get the previous tuple without resetting
	# the cursor
	my $last_tuple       = $cross->previous;

	# get a particular tuple with affecting the cursor
	# this is zero based
	my $nth_tuple        = $cross->nth($n);

	# get a random tuple
	my $random_tuple     = $cross->random;

	# in list context returns a list of all tuples
	my @tuples           = $cross->combinations;

	# in scalar context returns an array reference to all tuples
	my $tuples           = $cross->combinations;


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

This module combines the arrays that you give to it to create this
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

	my $self = bless {}, $class;

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

	$self->_init;

	my $len_last = $#{ $self->{lengths} };
	for( my $i  = 0; $i < $#{ $self->{counters} }; $i++ ) {
		my @lengths = map { $_+1 } @{ $self->{lengths} }[$i+1 .. $len_last];
		$self->{factors}[$i] += reduce { $a * $b } @lengths;
		}
	push @{ $self->{factors} }, 1;

	return $self;
	}

=back

=head2 Instance methods

=over 4

=cut


sub _factors { @{ $_[0]{factors} } }

sub _increment {
	my $self = shift;

	# print STDERR "_increment: counters at start: @{$self->{counters}}\n";
	# print STDERR "_increment: previous at start: @{$self->{previous}}\n";
	$self->{previous} = [ @{$self->{counters}} ]; # need a deep copy
	# print STDERR "_increment: previous after: @{$self->{previous}}\n";

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

sub _init {
	my( $self ) = @_;

	$self->{counters} = [ map { 0 } @{ $self->{arrays} } ];
    $self->{lengths}  = [ map { $#{$_} } @{ $self->{arrays} } ];
	$self->{ungot}    = 1;
	$self->{done}     = grep( $_ == -1, @{ $self->{lengths} } );

	# stolen from Set::CartesianProduct::Lazy by Stephen R. Scaffidi
	# https://github.com/hercynium/Set-CartesianProduct-Lazy
	$self->{info} = [
		map {
			[ $_, (scalar @{${ $self->{arrays} }[$_]}), reduce { $a * @$b } 1, @{ $self->{arrays} }[$_ + 1 .. $#{ $self->{arrays} }] ];
			} 0 .. $#{ $self->{arrays} }
		];

	return $self;
	}

sub _label_tuple {
	my( $self, $tuple ) = @_;

	unless( $self->{labeled} ) {
		return wantarray ? @$tuple : $tuple;
		}

	my %hash;
	@hash{ @{ $self->{labels} } } = @$tuple;

	return wantarray ? %hash : \%hash;
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

This works by exhausting the iterator. After calling this, there will
be no more tuples to C<get>. You can use C<reset_cursor> to start over.

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

	my $next_ref = $self->next;
	$self->_increment;
	$self->{ungot} = 0;

	$next_ref;
	}

=item * jump_to(N)

(new in 3.0)

Moves the cursor such that the next call to C<get> will fetch tuple
C<N>, which should be a positive whole number less than the cardinality.
Remember that everything is zero-based.

Invalid arguments return the empty list and warn.

This works by doing the math to reset the cursor rather than iterating
through the cursor to get to the right position. You can jump to any
position, including ones before the current cursor. After calling
C<jump_to($n)>, C<$position> should return the value of C<$n>.

This returns the object itself to allow you to chain methods. In previous
versions this returned C<1> (true). It still returns true, but just
a different value for it.

=cut

sub jump_to {
	my($self, $n) = @_;

	my $message = do {
		my $guidance = 'It should be a positive whole number up to one less than the cardinality.';
		if( @_ > 2 ) {
			"too many arguments for jump_to(). $guidance";
			}
		elsif( ! defined $n ) {
			"no or undefined argument for jump_to(). $guidance";
			}
		elsif( $n >= $self->cardinality ) {
			sprintf "argument ($n) for jump_to() is too large for cardinality (%d). $guidance",
				$self->cardinality;
			}
		elsif( $n =~ m/\D/ ) {
			"argument ($n) for jump_to() is inappropriate. $guidance";
			}
		};
	if( $message ) {
		carp $message;
		return;
		}

	my $max = $self->cardinality;
	my @positions = ();
	my $working_n = $n;
	foreach my $factor ( $self->_factors ) {
		if( $factor > $working_n ) {
			push @positions, 0;
			next;
			}

		my $int = int( $working_n / $factor );
		$working_n -= $int * $factor;
		push @positions, $int;
		}

	$self->{counters} = [@positions];

	$self;
	}

=item * labeled()

Return true if the sets are labeled (i.e. you made the object from a
hash ref). Returns false otherwise.

You might use this to figure out what sort of value C<get> will
return. When the tuple is labeled, you get hash refs. Otherwise, you
get array refs.

=cut

sub labeled { !! $_[0]->{labeled} }

=item * next()

Like C<get>, but does not move the cursor. This way you can look at
the next tuple without affecting your position in the cross product.

Since this does not move the cursor, repeated calls to C<next> will
return the same tuple.

=cut

sub next {
	my $self = shift;

	# At end position returns undef
	return unless defined $self->position;

	$self->nth( $self->position );
	}

=item * nth(n)

(new in 3.0)

Get the tuple at position C<n> in the set (zero based). This does not
advance or affect the cursor. C<n> must be a positive whole number
less than the cardinality. Anything else warns and returns undef.

This was largely stolen from L<Set::CartesianProduct::Lazy> by
Stephen R. Scaffidi.

=cut

# stolen from Set::CartesianProduct::Lazy by Stephen R. Scaffidi
# https://github.com/hercynium/Set-CartesianProduct-Lazy
sub nth {
	my($self, $n) = @_;

	my $message = do {
		my $guidance = 'It should be a positive whole number up to one less than the cardinality.';
		if( @_ > 2 ) {
			"too many arguments for nth(). $guidance";
			}
		elsif( ! defined $n ) {
			"no or undefined argument for nth(). $guidance";
			}
		elsif( $n >= $self->cardinality ) {
			sprintf "argument ($n) for nth() is too large for cardinality (%d). $guidance",
				$self->cardinality;
			}
		elsif( $n =~ m/\D/ ) {
			"argument ($n) for nth() is inappropriate. $guidance";
			}
		};
	if( $message ) {
		carp $message;
		return;
		}

	my @tuple = map {
		my ($set_num, $set_size, $factor) = @$_;
		${ $self->{arrays} }[ $set_num ][ int( $n / $factor ) % $set_size ];
		} @{ $self->{info} };

	my $tuple = $self->_label_tuple(\@tuple);

	return wantarray ? @$tuple : $tuple;
	}

=item * position()

(new in 3.0)

Returns the zero-based position of the cursor. This is the same as the
position for the next tuple that C<get> will fetch. Before you fetch
any tuple, the position is 0. After you have fetched all the tuples,
C<position> returns undef.

=cut

sub position {
	my( $self ) = $_[0];
	return if $self->{done};

	my $len_last = $#{ $self->{lengths} };

	my $sum = 0;
	for( my $i  = 0; $i <= $#{ $self->{counters} }; $i++ ) {
		$sum += $self->{counters}[$i] * $self->{factors}[$i];
		}

	return $sum;
	}

=item * previous()

Like C<get>, but does not move the cursor.  This way you can look at
the previous tuple without affecting your position in the cross product.

=cut

sub previous {
	my $self = shift;

	if( $self->position == 0 ) {
		carp "Can't call previous at the first tuple of the cross product";
		return;
		}

	$self->nth( $self->done ? $self->cardinality - 1 : $self->position - 1 );
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

Return the cursor to the first element of the cross product. The next
call to C<get> will fetch the first tuple.

This returns the object itself to allow you to chain methods. In previous
versions this returned C<1> (true). It still returns true, but just
a different value for it.

=cut

sub reset_cursor {
	my( $self, $position ) = @_;
	$position = 0 unless defined $position;

	$self->_init;

	return $self;
	}

=item * unget()

Pretend we did not get the tuple we just got.  The next time we get a
tuple, we will get the same thing.  You can use this to peek at the
next value and put it back if you do not like it.

You can only do this for the previous tuple.  C<unget> does not do
multiple levels of unget.

This returns the object itself to allow you to chain methods. In previous
versions this returned C<1> (true). It still returns true, but just
a different value for it.

=cut

sub unget {
	my $self = shift;

	return if $self->{ungot};

	$self->{counters} = $self->{previous};

	$self->{ungot} = 1;

	# if we just got the last element, we had set the done flag,
	# so unset it.
	$self->{done}  = 0;

	return $self;
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

=head1 ISSUES

Report an problems to L<http://github.com/briandfoy/set-crossproduct/issues>.

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/set-crossproduct

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

Matt Miller implemented the named sets feature.

Stephen R. Scaffidi implemented the code for C<nth> in his
L<Set::CartesianProduct::Lazy>, and I adapted it for this module.

=head1 COPYRIGHT AND LICENSE

Copyright © 2001-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;
