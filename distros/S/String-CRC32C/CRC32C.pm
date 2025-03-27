=head1 NAME

Strihng::CRC32C - Castagnoli CRC

=head1 SYNOPSIS

 use String::CRC32C; # does not export anything by default
 use String::CRC32C 'crc32c';

 $crc = crc32 "some string";
 $crc = crc32 "some string", $initvalue;

=head1 DESCRIPTION

This module calculates the Castagnoli CRC32 variant (polynomial 0x11EDC6F41).

It is used by iSCSI, SCTP, BTRFS, ext4, leveldb, x86 CPUs and others.

This module uses an optimized implementation for SSE 4.2 targets (GCC
and compatible supported, SSE 4.2 must be enabled in your Perl) and the
SlicingBy8 algorithm for anything else.

=cut

package String::CRC32C;

our $IMPL;

BEGIN {
   $VERSION = 0.02;
   @ISA = qw(Exporter);
   @EXPORT_OK = qw(crc32c);

   require XSLoader;
   XSLoader::load String::CRC32C, $VERSION;
}

use Exporter qw(import);

=over

=item $crc32c = crc32c $string[, $initvalue]

Calculates the CRC32C value of the given C<$string> and returns it as a 32
bit unsigned integer.

To get the common hex form, use one of:

   sprintf "%08x", crc32c $string
   unpack "H*", pack "L>", crc32c $string

A seed/initial crc value can be given as second argument. Note that both
the initial value and the result value are inverted (pre-inversion and
post-inversion), e.g. a common init value of C<-1> from other descriptions
needs to be given as C<0> (or C<~-1>).

This allows easy chaining, e.g.

   (crc32c "abcdefghi") eq (crc32 "ghi", crc32 "def", crc32 "abc)

=item $impl = $String::CRC32C::IMPL

Returns a string indicating the implementation that will be used. Currently either C<SlicingBy8>
for the portable implementation or C<IntelCSSE42> for the SSE 4.2 optimized intel version.

=back

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

CRC32C code by various sources, ported from
https://github.com/htot/crc32c, see sources for details.

=cut

1

