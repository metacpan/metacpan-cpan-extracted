package Sort::DJB;

use strict;
use warnings;
use Exporter 'import';
use XSLoader;

our $VERSION = '0.2';

our @EXPORT_OK = qw(
    sort_int32  sort_int32down
    sort_uint32 sort_uint32down
    sort_int64  sort_int64down
    sort_uint64 sort_uint64down
    sort_float32 sort_float32down
    sort_float64 sort_float64down
);

our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    int32  => [qw(sort_int32 sort_int32down)],
    uint32 => [qw(sort_uint32 sort_uint32down)],
    int64  => [qw(sort_int64 sort_int64down)],
    uint64 => [qw(sort_uint64 sort_uint64down)],
    float32 => [qw(sort_float32 sort_float32down)],
    float64 => [qw(sort_float64 sort_float64down)],
);

XSLoader::load('Sort::DJB', $VERSION);

1;

__END__

=head1 NAME

Sort::DJB - Fast sorting using Daniel J. Bernstein's djbsort bitonic sorting networks

=head1 SYNOPSIS

    use Sort::DJB qw(:all);

    # Sort signed 32-bit integers (ascending)
    my $sorted = sort_int32([5, 3, 1, 4, 2]);
    # $sorted = [1, 2, 3, 4, 5]

    # Sort descending
    my $desc = sort_int32down([5, 3, 1, 4, 2]);
    # $desc = [5, 4, 3, 2, 1]

    # All data types
    sort_int32(\@data);       sort_int32down(\@data);
    sort_uint32(\@data);      sort_uint32down(\@data);
    sort_int64(\@data);       sort_int64down(\@data);
    sort_uint64(\@data);      sort_uint64down(\@data);
    sort_float32(\@data);     sort_float32down(\@data);
    sort_float64(\@data);     sort_float64down(\@data);

    # Metadata
    print Sort::DJB::version(), "\n";          # "20260210"
    print Sort::DJB::arch(), "\n";             # "portable" or "amd64"
    print Sort::DJB::int32_implementation(), "\n";  # e.g. "portable4" or "avx2"

=head1 DESCRIPTION

Sort::DJB provides Perl bindings to Daniel J. Bernstein's djbsort library,
which sorts arrays using bitonic sorting networks. Key properties:

=over 4

=item * B<Fast> - SIMD-optimized (AVX2/SSE4.2/NEON) when using a system-installed
djbsort; portable C fallback when built standalone.

=item * B<Constant-time> - Data-independent execution flow, suitable for
cryptographic applications where timing side-channels must be avoided.

=item * B<Type-safe> - Dedicated functions for int32, uint32, int64, uint64,
float32, and float64, with both ascending and descending variants.

=back

Each sort function takes an array reference and returns a new sorted array
reference. The input array is not modified.

=head1 FUNCTIONS

All functions are exportable. Use C<:all> to import everything, or import
by type group (C<:int32>, C<:uint32>, C<:int64>, C<:uint64>, C<:float32>,
C<:float64>).

=head2 sort_int32(\@array), sort_int32down(\@array)

Sort signed 32-bit integers in ascending/descending order.

=head2 sort_uint32(\@array), sort_uint32down(\@array)

Sort unsigned 32-bit integers.

=head2 sort_int64(\@array), sort_int64down(\@array)

Sort signed 64-bit integers.

=head2 sort_uint64(\@array), sort_uint64down(\@array)

Sort unsigned 64-bit integers.

=head2 sort_float32(\@array), sort_float32down(\@array)

Sort 32-bit floats. Handles NaN correctly.

=head2 sort_float64(\@array), sort_float64down(\@array)

Sort 64-bit doubles. Handles NaN correctly.

=head2 version()

Returns the djbsort library version string (e.g., "20260210").

=head2 arch()

Returns the architecture string (e.g., "amd64", "portable").

=head2 int32_implementation(), int64_implementation()

Returns the active sorting implementation (e.g., "avx2", "portable4").

=head1 ALGORITHM

djbsort uses bitonic sorting networks with O(n log^2 n) comparisons. Despite
the worse asymptotic complexity compared to quicksort's O(n log n), the
branch-free, vectorizable nature of sorting networks makes djbsort
significantly faster in practice, especially with SIMD instructions.

=head1 SEE ALSO

L<https://sorting.cr.yp.to/> - djbsort homepage

L<Sort::DJB::Pure> - Pure Perl implementation of the same algorithm

=head1 AUTHOR

XS bindings for djbsort-20260210 by Daniel J. Bernstein.

=head1 LICENSE

GPLv2. See the F<LICENSE> file included with this distribution for the full
text of the GNU General Public License, version 2.

=cut
