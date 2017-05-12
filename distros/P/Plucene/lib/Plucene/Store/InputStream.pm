package Plucene::Store::InputStream;

=head1 NAME 

Plucene::Store::InputStream - a random-access input stream

=head1 SYNOPSIS

	# isa IO::File

=head1 DESCRIPTION

A random-access input stream.Used for all Plucene index input operations.

=head1 METHODS

=cut

use strict;
use warnings;

use Encode qw(_utf8_on);    # Magic

=head2 new

	my $inputstream = Plucene::Store::InputStream->new($file);

Create a new input stream.

=cut

sub new {
	my ($self, $filename) = @_;
	$self = ref $self || $self;
	open my $fh, '<', $filename
		or die "$self cannot open $filename for reading: $!";
	binmode $fh;
	bless [ $fh, $filename ], $self;
}

sub DESTROY { CORE::close $_[0]->[0] }

=head2 fh / read / seek / tell / getc / print / eof / close

File operations

=cut

use Carp 'croak';
sub fh    { croak "InputStream fh called" }
sub read  { CORE::read $_[0]->[0], $_[1], $_[2] }
sub seek  { CORE::seek $_[0]->[0], $_[1], $_[2] }
sub tell  { CORE::tell $_[0]->[0] }
sub getc  { CORE::getc $_[0]->[0] }
sub print { croak "InputStream print called" }
sub eof   { CORE::eof $_[0]->[0] }
sub close { CORE::close $_[0]->[0] }

=head2 clone

This will return a clone of this stream.

=cut

sub clone {
	my $orig  = shift;
	my $clone = $orig->new($orig->[1]);
	CORE::seek($clone->[0], CORE::tell($orig->[0]), 0);
	return $clone;
}

=head2 read_byte

This will read and return a single byte.

=cut

sub read_byte {    # unpack C
	ord CORE::getc $_[0]->[0];
}

=head2 read_int

This will read four bytes and return an integer.

=cut

sub read_int {     # unpack N
	my $buf;
	CORE::read $_[0]->[0], $buf, 4;
	return unpack("N", $buf);
}

=head2 read_vint

This will read an integer stored in a variable-length format.

=cut

sub read_vint {    # unpack w
	my $b = ord CORE::getc($_[0]->[0]);
	my $i = $b & 0x7F;
	for (my $s = 7 ; ($b & 0x80) != 0 ; $s += 7) {
		$b = ord CORE::getc $_[0]->[0];
		$i |= ($b & 0x7F) << $s;
	}
	return $i;
}

=head2 read_vlong

This will read a long and stored in variable-length format

=cut

*read_vlong = *read_vint;   # Perl is type-agnostic. ;)
                            # Yes, but most Perls don't handle 64bit integers!

=head2 read_string

This will read a string.

=cut

sub read_string {           # unpack w/a
	my $length = $_[0]->read_vint();
	my $utf8;
	CORE::read $_[0]->[0], $utf8, $length;
	_utf8_on($utf8);
	return $utf8;
}

=head2 read_long

This will read eight bytes and return a long.

=cut

sub read_long {    # unpack NN
	my $int_a = $_[0]->read_int;
	my $int_b = $_[0]->read_int;    # Order is important!
	                                # and size matters!
	return (($int_a << 32) | ($int_b & 0xFFFFFFFF));
}

1;
