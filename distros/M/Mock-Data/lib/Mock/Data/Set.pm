package Mock::Data::Set;
use strict;
use warnings;
require Mock::Data::Generator;
our @ISA= qw( Mock::Data::Generator );

# ABSTRACT: Generator which returns one item from a set
our $VERSION = '0.04'; # VERSION


sub new {
	my $class= shift;
	my %args= @_ == 1 && ref $_[0] eq 'HASH'? %{$_[0]}
		: @_ == 1 && ref $_[0] eq 'ARRAY'? ( items => $_[0] )
		: @_;
	bless \%args, $class;
}

sub new_weighted {
	my $class= shift;
	@_ & 1 and Carp::croak("Odd number of elements given to new_weighted, need (value => weight) pairs");
	my (@items, @weights);
	while (@_) {
		push @items, shift;
		push @weights, shift;
	}
	$class->new(items => \@items, weights => \@weights);
}


sub items {
	my $self= shift;
	return $self->{items} unless @_;
	my $val= shift;
	delete $self->{_odds_table} if $#{$self->{items}} != $#$val;
	return $self->{items}= $val;
}

sub weights {
	my $self= shift;
	return $self->{weights} unless @_;
	delete $self->{_odds_table};
	return $self->{weights}= shift;
}


sub generate {
	my $self= shift;
	my $items= $self->items;
	my $pick;
	if (!$self->weights) {
		$pick= rand( scalar @$items );
	} else {
		# binary search for the random number
		my $tbl= $self->_odds_table;
		my ($min, $max, $r)= (0, $#$items, rand);
		while ($min+1 < $max) {
			my $mid= int(($max+$min)/2);
			if ($r < $tbl->[$mid]) { $max= $mid-1; }
			else { $min= $mid; }
		}
		$pick= ($max > $min && $tbl->[$max] <= $r)? $max : $min;
	}
	my $cmp_item= $items->[$pick];
	return $cmp_item unless ref $cmp_item && ref($cmp_item)->can('generate');
	$cmp_item->generate(@_);
}

sub _odds_table {
	$_[0]{_odds_table} ||= $_[0]->_build__odds_table;
}

sub _build__odds_table {
	my $self= shift;
	my $items= $self->items;
	my $weights= $self->weights;
	my $total= 0;
	$total += ($weights->[$_] ||= 1)
		for 0..$#$items;
	my $sum= 0;
	return [ map { my $x= $sum; $sum += $_; $x/$total } @$weights ]
}


sub compile {
	my $self= shift;
	my $items= $self->items;
	my @compiled;
	for (@$items) {
		if (ref && ref->can('generate')) {
			# Some items are generators.  Compile a list of them, but only the generators.
			@compiled= map +(ref && ref->can('generate')? $_->compile : undef), @$items;
			last;
		}
	}
	
	if (!$self->weights) {
		return !@compiled
			? sub { $items->[int rand scalar @$items] }
			: sub {
				my $pick= int rand scalar @$items;
				$compiled[$pick]? $compiled[$pick]->(@_) : $items->[$pick];
			};
	}
	else {
		my $odds_table= $self->_odds_table;
		return sub {
			# binary search for the random number
			my ($min, $max, $r)= (0, $#$items, rand);
			while ($min+1 < $max) {
				my $mid= int(($max+$min)/2);
				if ($r < $odds_table->[$mid]) { $max= $mid-1; }
				else { $min= $mid; }
			}
			my $pick= ($max > $min && $odds_table->[$max] <= $r)? $max : $min;
			$compiled[$pick]? $compiled[$pick]->(@_) : $items->[$pick];
		}
	}
}


sub combine_generator {
	my ($self, $peer)= @_;
	my @items= @{$self->items};
	my $weights= $self->weights;
	if ($peer->isa('Mock::Data::Set')) {
		my $peer_items= $peer->items;
		my $peer_weights= $peer->weights;
		if ($weights || $peer_weights) {
			$weights= [
				$weights?      @$weights      : (map 1, @items),
				$peer_weights? @$peer_weights : (map 1, @$peer_items),
			];
		}
		push @items, @$peer_items;
	} else {
		push @items, $peer;
		$weights= $weights && @$weights? [ @$weights, List::Util::sum0(@$weights)/@$weights ] : undef;
	}
	return Mock::Data::Set->new(
		items => \@items,
		weights => $weights,
	);
}

require Mock::Data::Util;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::Set - Generator which returns one item from a set

=head1 SYNOPSIS

  $generator= Mock::Data::Set->new(items => [ 1, 2, 3, 4 ]);
  $value= $generator->generate($mock);   # 25% chance of each of the items
  
  $generator= Mock::Data::Set->new(items => [ 1, 2 ], weights => [ 1, 9 ]);
  $value= $generator->generate($mock);   # 10% chance of '1', 90% chance of '2'

  use Mock::Data::Util qw( weighted_set uniform_set coerce_generator );
  $generator= uniform_set(1, 2, 3, 4);  # same as above
  $generator= weighted_set( 1 => 1, 2 => 9 ); # same as above
  
  $generator= coerce_generator([ 1, 2, 3, 4 ]);
  $generator= coerce_generator({ 1 => 1, 2 => 9 });
  
  # coerce_generator is recursive, Set constructor is not
  uniform_set([1, [2, 3]])->generate;       # 50% chance of returning arrayref [2,3]
  uniform_set("{a}")->generate;             # 100% chance of returning string '{a}'
  coerce_generator([1, [2, 3]])->generate;  # 25% chance of returning 2
  coerce_generator(["{a}"])->generate;      # 100% chance of calling generator named 'a'

=head1 DESCRIPTION

This object selects a random element from a list.  All items are equal probability
unless C<weights> are specified to change the probability.  The items of the list
may be values or L<generator objects|Mock::Data::Generator>.  Plain coderefs are also
considered values, not generators.  (If you want automatic coercion, see
L<Mock::Data::Util/coerce_generator>).

=head1 CONSTRUCTORS

=head2 new

  $set= Mock::Data::Set->new(%attrs);
                    ...->new(\%attrs);
                    ...->new(\@items);

Takes a list or hashref of attributes and returns them as an object.  If you pass an
arrayref as the only parameter, it is assumed to be the L</items> attribute.

=head2 new_weighted

  $set= Mock::Data::Set->new_weighted($item => $weight, ...);

Construct a C<Set> from a list of pairs of C<< ($item, $weight) >>.  This constructor
takes a I<list>, not a hashref or arrayref.

=head1 ATTRIBUTES

=head2 items

The arrayref of items which can be returned by this generator.  Do not modify this array.
If you need to change the list of items, assign a new array to this attribute.

=head2 weights

An optional arrayref of values, one value per element of C<items>.  The weight values are on
an arbitrary scale chosen by the user, such that the sum of them is considered to be 100%.

=head1 METHODS

=head2 generate

  $val= $set->generate($mock, \%params);
  $val= $set->generate;

Return one random item from the set.  This should normally be called with the reference to a
L<Mock::Data> instance and optional named parameters, but this module doesn't actually use
them.  (though a subclass or future version could)

=head2 compile

  my $sub= $set->compile

Return a coderef that calls this generator.

=head2 combine_generator

  my $merged= $self->combine_generator($peer);

If the C<$peer> is an instance of C<Mock::Data::Set>, this will take the items and weights
of the peer, combine with the items and weights of the current object, and create a new set.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.04

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
