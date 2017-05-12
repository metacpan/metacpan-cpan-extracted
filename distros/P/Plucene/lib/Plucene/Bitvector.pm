package Plucene::Bitvector;

=head1 NAME 

Plucene::Bitvector - a vector of bits

=head1 SYNOPSIS

	# isa Bit::Vector::Minimal;

	my $bitvector = Plucene::Bitvector->read($stream);

	$bitvector->write($stream);
	
	my $count = $bitvector->count;

=head1 DESCRIPTION

A serialisable implementation of a vector of bits.

This subclass of Bit::Vector::Minimal allows the writing (and reading) of 
vectors to (and from) a Plucene stream.

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Bit::Vector::Minimal';

use List::Util qw(sum);

my @magic = (
	0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4, 1, 2, 2, 3, 2, 3, 3, 4,
	2, 3, 3, 4, 3, 4, 4, 5, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 1, 2, 2, 3, 2, 3, 3, 4,
	2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
	2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6,
	4, 5, 5, 6, 5, 6, 6, 7, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
	2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6,
	4, 5, 5, 6, 5, 6, 6, 7, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
	4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
);

=head2 count

	my $count = $bitvector->count;

Compute the number of one-bits.

=cut

sub count {
	sum map $magic[ ord $_ ], split //, shift->{pattern};
}

=head2 write

	$bitvector->write($stream);

Write this vector to the passed in stream.

=cut

sub write {
	my ($self, $stream) = @_;
	$stream->write_int($self->{size});
	$stream->write_int($self->count);    # Backwards compat.
	$stream->print($self->{pattern});
}

=head2 read

	my $bitvector = Plucene::Bitvector->read($stream);

Read from the passed in stream.

=cut

sub read {
	my ($class, $stream) = @_;
	my $size = $stream->read_int;
	my $self = $class->new(size => $size, width => 1);
	$stream->read_int;
	$stream->read($self->{pattern}, 1 + $self->{size} / 8);
	return $self;
}

1;
