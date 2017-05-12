package PEF::CacheLRU;
use strict;
use warnings;
use constant {
	NEXT    => 0,
	PREV    => 1,
	KEY     => 2,
	VALUE   => 3,
	HEAD    => 0,
	TAIL    => 1,
	NODES   => 2,
	SIZE    => 3,
	MAXSIZE => 4,
};

our $VERSION = "0.02";

sub new {
	my ($class, $max_size) = @_;
	my $self = bless [[undef, undef], undef, {}, 0, $max_size,], $class;
	$self->[TAIL] = $self->[HEAD];
	$self;
}

sub max_size {
	$_[0]->[MAXSIZE];
}

sub size {
	$_[0]->[SIZE];
}

sub _promote {
	my ($self, $node) = @_;
	my $pre = $node->[PREV];
	$node->[PREV]             = undef;
	$pre->[NEXT]              = $node->[NEXT];
	$pre->[NEXT][PREV]        = $pre;
	$node->[NEXT]             = $self->[HEAD];
	$self->[HEAD]             = $node;
	$self->[HEAD][NEXT][PREV] = $self->[HEAD];
}

sub remove {
	my ($self, $key) = @_;
	return if not exists $self->[NODES]{$key};
	my $node = $self->[NODES]{$key};
	--$self->[SIZE];
	if ($node == $self->[HEAD]) {
		$self->[HEAD] = $node->[NEXT];
		$self->[HEAD][PREV] = undef;
	} else {
		my $pre = $node->[PREV];
		$pre->[NEXT] = $node->[NEXT];
		$node->[NEXT][PREV] = $pre;
	}
	delete $self->[NODES]{$node->[KEY]};
	$node->[NEXT] = undef;
	$node->[PREV] = undef;
	$node->[VALUE];
}

sub set {
	my ($self, $key, $value) = @_;
	if (my $node = $self->[NODES]{$key}) {
		$node->[VALUE] = $value;
		$self->_promote($node) if $node != $self->[HEAD];
	} else {
		$self->[HEAD] = [$self->[HEAD], undef, $key, $value];
		$self->[HEAD][NEXT][PREV] = $self->[HEAD];
		$self->[NODES]{$key} = $self->[HEAD];
		if (++$self->[SIZE] > $self->[MAXSIZE]) {
			my $pre_least = $self->[TAIL][PREV];
			if (my $pre = $pre_least->[PREV]) {
				delete $self->[NODES]{$pre_least->[KEY]};
				$pre->[NEXT]        = $self->[TAIL];
				$self->[TAIL][PREV] = $pre;
				$pre_least->[NEXT]  = undef;
				$pre_least->[PREV]  = undef;
				--$self->[SIZE];
			}
		}
	}
	$value;
}

sub get {
	my ($self, $key) = @_;
	if (my $node = $self->[NODES]{$key}) {
		$self->_promote($node) if $node != $self->[HEAD];
		$node->[VALUE];
	} else {
		return;
	}
}

1;

__END__

=encoding utf8

=head1 NAME
 
PEF::CacheLRU - a simple, fast implementation of LRU cache in pure perl
 
=head1 SYNOPSIS
 
    use PEF::CacheLRU;
 
    my $cache = PEF::CacheLRU->new($max_num_of_entries);
 
    $cache->set($key => $value);
 
    $value = $cache->get($key);
 
    $removed_value = $cache->remove($key);
 
=head1 DESCRIPTION
 
PEF::CacheLRU is a simple, fast implementation of an in-memory LRU cache in pure perl. It is inspired by L<Cache::LRU> but works faster.
 
=head1 METHODS
 
=head2 PEF::CacheLRU->new($max_num_of_entries)
 
Creates a new cache object.  The only parameter is the maximum number of entries to be stored within the cache object.
 
=head2 $cache->get($key)
 
Returns the cached object if exists, or undef otherwise.
 
=head2 $cache->set($key => $value)
 
Stores the given key-value pair.
 
=head2 $cache->remove($key)
 
Removes data associated to the given key and returns the old value, if any.
 
=head2 $cache->size
 
Returns used cache size.
 
=head2 $cache->max_size
 
Returns cache capacity.
 
=head1 Authors

This module was written and is maintained by:

=over

=item * PEF Developer <pef-secure@yandex.ru>

=back

=head1 Speed

What is the difference between L<Cache::LRU> and this module?

Using slightly modified benchmark from L<Cache::LRU> I get:

  cache_hit:
                  Rate    Cache::LRU PEF::CacheLRU
  Cache::LRU     872/s            --          -52%
  PEF::CacheLRU 1815/s          108%            --
  
  cache_set:
                  Rate    Cache::LRU PEF::CacheLRU
  Cache::LRU    5.81/s            --          -22%
  PEF::CacheLRU 7.44/s           28%            --
  
  cache_set_hit:
                 Rate    Cache::LRU PEF::CacheLRU
  Cache::LRU    155/s            --          -35%
  PEF::CacheLRU 238/s           54%            --

Devel::NYTProf measures following speed:

  spent 9.61s (8.97+637ms) within PEF::CacheLRU::get which was called 7500000 times, avg 1µs/call: 
  5000000 times (5.36s+0s) by main::cache_hit at line 18 of simple_bench.pl, avg 1µs/call 
  2500000 times (3.61s+637ms) by main::cache_set_hit at line 31 of simple_bench.pl, avg 2µs/call

  spent 25.3s (17.8+7.48) within Cache::LRU::get which was called 7500000 times, avg 3µs/call: 
  5000000 times (11.7s+4.91s) by main::cache_hit at line 18 of simple_bench.pl, avg 3µs/call 
  2500000 times (6.16s+2.57s) by main::cache_set_hit at line 31 of simple_bench.pl, avg 3µs/call

  spent 4.23s (4.23+2.36ms) within PEF::CacheLRU::set which was called 1320720 times, avg 3µs/call: 
  1310720 times (4.21s+2.36ms) by main::cache_set at line 56 of simple_bench.pl, avg 3µs/call 
     5000 times (13.0ms+0s) by main::cache_hit at line 16 of simple_bench.pl, avg 3µs/call 
     5000 times (10.6ms+0s) by main::cache_set_hit at line 25 of simple_bench.pl, avg 2µs/call

	
  spent 9.46s (7.38+2.08) within Cache::LRU::set which was called 1320720 times, avg 7µs/call:
  1310720 times (7.32s+2.06s) by main::cache_set at line 56 of simple_bench.pl, avg 7µs/call
     5000 times (28.5ms+11.2ms) by main::cache_hit at line 16 of simple_bench.pl, avg 8µs/call
     5000 times (24.9ms+9.10ms) by main::cache_set_hit at line 25 of simple_bench.pl, avg 7µs/call

=head1 SEE ALSO
 
L<Cache::LRU>
 
=head1 LICENSE
 
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
 
See L<Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>
 
=cut
