=head1 NAME

PerlIO::bitswap - I/O layer to swap bits and bytes

=head1 SYNOPSIS

	open($fh, "<:bitswap(7)", $filename);
	open($fh, ">:bitswap(7)", $filename);

=head1 DESCRIPTION

This PerlIO layer swaps the order of bits, nybbles, or bytes within
bytes or words.  It is a convenience when working with a file that uses
a different endianness from the program, or when some other part of the
system applies unwanted swaps.

The layer takes one argument, which must be a non-negative integer,
specified in any of the ways that are by default permitted in Perl
source.  Each bit of the argument controls one of a set of swaps that
are available, and the swaps for all set bits occur simultaneously.
Generically, bit N (which has numeric value 2**N) causes the two
2**N-bit halves of each aligned 2**(N+1)-bit unit to be swapped.  So,
for example, an argument of 16 (only bit 4 set) swaps the two two-octet
halves of each four-octet unit, while preserving the order of the octets
within each two-octet unit and the order of the bits within each octet.
The most useful swap arguments are:

=over

=item B<7>

Reverse the order of the eight bits within each octet, leaving the
sequence of octets unmodified.

=item B<8>

Swap octets within each two-octet word.

=item B<0x18>

Reverse the order of the four octets within each four-octet word.

=item B<0x38>

Reverse the order of the eight octets within each eight-octet word.

=back

If octets or larger units are being swapped (argument 8 or greater),
any incomplete swap block will result in an I/O error.  It is permitted
for individual reads and writes to involve incomplete swap blocks, but any
sequence of reads and writes must cover an integral number of swap blocks.
Seeks, similarly, must always travel an integral number of swap blocks.
The logic assumes that the end of a regular file is always at a block
boundary, and will yield incorrect results if that is not the case.

=cut

package PerlIO::bitswap;

{ use 5.008001; }
use warnings;
use strict;

our $VERSION = "0.002";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 SEE ALSO

L<PerlIO>,
L<PerlIO::encoding>,
L<perlfunc/open>,
L<perlfunc/pack>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2010, 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
