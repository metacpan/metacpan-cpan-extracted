package Sort::Bucket;

use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(inplace_bucket_sort);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Sort::Bucket', $VERSION);

1;
__END__

=head1 NAME

Sort::Bucket - a fast XS bucket sort

=head1 SYNOPSIS

  use Sort::Bucket qw(inplace_bucket_sort);

  inplace_bucket_sort(@some_array);

=head1 DESCRIPTION

A fast XS implementation of the Bucket Sort algorithm.  If your data is
well suited to a bucket sort then this can be significantly faster than
Perl's builtin sort() function.

A bucket sort works best when there is a large amount of variation in the
first few bytes of the strings to be sorted.

=head1 LIMITATIONS

Only in-place sorting is implemented so far.

Limited to sorting in standard string comparison order.

B<Sort::Bucket> can be used to sort either byte strings or character
strings, but not a mixture.  If you apply B<Sort::Bucket> to an array
containing both byte strings and character strings then it may sort them
into the wrong order, so don't do that.

There is no C<locale> support, i.e. C<use locale> will not effect the
order into which this module sorts your strings as it does with Perl's
builtin sort.

If the array is already partially sorted, Perl's builtin sort() can take
advantage of that to sort it very quickly.  For this reason, B<Sort::Bucket>
can be slower than Perl's builtin sort on partially sorted input,
even with data that's well suited to a bucket sort.

=head1 EXPORTS

Exports nothing by default.  The following functions are available
for import:

=over

=item inplace_bucket_sort( ARRAY_OF_STRINGS [,BUCKET_BITS] )

Sorts ARRAY_OF_STRINGS in-place.

BUCKET_BITS specifies the number of bits from the start of each string
to use to select the bucket into which to place the string.  If set,
it must be an integer from 1 to 31.

The elements of the array will be distributed into 2**BUCKET_BITS buckets,
and then sorted within each bucket.  If BUCKET_BITS is omitted then a
sensible value will be selected based on the size of the array.

=back

=head1 ALGORITHM

For each element in the array, a B<major bucket> and a B<minor bucket>
value is computed.  The B<major bucket> is the first BUCKET_BITS bits of the
string, and the B<minor bucket> is the next 32 bits.

The elements are then distributed into 2**BUCKET_BITS major buckets,
according to their major bucket values.  The minor bucket value is
stored along with each element.

For each of the 2**BUCKET_BITS possible major bucket values, the
elements in that bucket are sorted by minor bucket.  Any that compare
equal by minor bucket are further sorted using Perl's native sort.

The extra step of sorting by minor bucket before falling back to Perl's
sort speeds up the process, since comparing 32-bit integers is much faster
than comparing Perl scalars.

=head1 SEE ALSO

L<perlfunc/sort>

There are several other fast sorting modules on CPAN, any of which may be
faster than C<Sort::Bucket> for your data.  For example, L<Sort::Key>.
L<Sort::Maker>, L<Sort::Merge>.

If the data to be sorted does not fit into memory, you probably want
L<Sort::External>.

=head1 AUTHOR

Nick Cleaton, E<lt>nick@cleaton.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Nick Cleaton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
