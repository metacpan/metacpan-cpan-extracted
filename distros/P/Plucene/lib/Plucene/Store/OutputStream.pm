package Plucene::Store::OutputStream;

=head1 NAME 

Plucene::Store::OutputStream - a random-access output stream

=head1 SYNOPSIS

	# isa Plucene::Store::InputStream

=head1 DESCRIPTION

This is an abstract class for output to a file in a Directory. 
A random-access output stream. 
Used for all Plucene index output operations.

=head1 METHODS

=cut

use strict;
use warnings;
no warnings 'uninitialized';

use Encode qw(encode);

=head2 new

Create a new Plucene::Store::OutputStream

=cut

sub new {
	my ($self, $filename) = @_;
	$self = ref $self || $self;
	open my $fh, '>', $filename
		or die "$self cannot open $filename for writing: $!";
	binmode $fh;
	bless [ $fh, $filename ], $self;
}

sub DESTROY { CORE::close $_[0]->[0] }

=head2 clone

Clone this

=cut

sub clone {
	my $orig  = shift;
	my $clone = $orig->new($orig->[1]);
	CORE::seek($clone->[0], CORE::tell($orig->[0]), 0);
	return $clone;
}

=head2 fh / read / seek / tell / getc / print / eof / close

File operations

=cut

use Carp 'croak';
sub fh    { croak "OutputStream fh called" }
sub read  { croak "OutputStream read called" }
sub seek  { CORE::seek $_[0]->[0], $_[1], $_[2] }
sub tell  { CORE::tell $_[0]->[0] }
sub getc  { croak "OutputStream getc called" }
sub print { local $\; my $fh = shift->[0]; CORE::print $fh @_ }
sub eof   { CORE::eof $_[0]->[0] }
sub close { CORE::close $_[0]->[0] }

=head2 write_byte

This will write a single byte.

=cut

sub write_byte {
	local $\;
	CORE::print { $_[0]->[0] } $_[1];
}

=head2 write_int

This will write an int as four bytes.

=cut

sub write_int {
	local $\;
	CORE::print { $_[0]->[0] } pack("N", $_[1]);
}

=head2 write_vint

This will write an int in a variable length format.

=cut

sub write_vint {
	local $\;
	use bytes;
	my $i = $_[1];
	my $txt;
	while ($i & ~0x7f) {
		$txt .= chr($i | 0x80);
		$i >>= 7;
	}
	$txt .= chr($i);
	CORE::print { $_[0]->[0] } $txt;
}

=head2 write_long

This will write a long as eight bytes.

=cut

sub write_long {
	local $\;
	CORE::print { $_[0]->[0] }
		pack("NN", 0xffffffff & ($_[1] >> 32), 0xffffffff & $_[1]);
}

=head2 write_vlong

This will write a long in variable length format.

=cut

*write_vlong = *write_vint;

=head2 write_string

This will write a string.

=cut

sub write_string {
	local $\;
	my $s = $_[1];
	$s = encode("utf8", $s) if $s =~ /[^\x00-\x7f]/;
	$_[0]->write_vint(length $s);
	CORE::print { $_[0]->[0] } $s;
}

1;
