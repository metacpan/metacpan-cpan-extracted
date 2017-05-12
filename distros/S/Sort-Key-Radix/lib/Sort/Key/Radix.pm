package Sort::Key::Radix;

our $VERSION = '0.14';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(isort
                    usort
                    nsort
                    ssort
                    risort
                    rusort
                    rnsort
                    rssort
                    ikeysort
                    ukeysort
                    nkeysort
                    skeysort
                    rikeysort
                    rukeysort
                    rnkeysort
                    rskeysort
                    isort_inplace
                    usort_inplace
                    nsort_inplace
                    ssort_inplace
                    risort_inplace
                    rusort_inplace
                    rnsort_inplace
                    rssort_inplace
                    ikeysort_inplace
                    ukeysort_inplace
                    nkeysort_inplace
                    skeysort_inplace
                    rikeysort_inplace
                    rukeysort_inplace
                    rnkeysort_inplace
                    rskeysort_inplace );

require XSLoader;
XSLoader::load('Sort::Key::Radix', $VERSION);

1;

__END__

=head1 NAME

Sort::Key::Radix - Radix sort implementation in XS

=head1 SYNOPSIS

  use Sort::Key::Radix qw(ukeysort);
  
  my @sorted = ukeysort { $_->age } @people;

=head1 DESCRIPTION

This module reimplements some of the funcions in the L<Sort::Key>
module using a Radix sort as the sorting algorithm.

For some kinds of data (for instance large data sets of small
integers, postal codes, logins, serial numbers, dates, etc.) it can be
faster than the Merge sort algorithm used internally by Perl and by
L<Sort::Key>.

=head2 FUNCTIONS

The following functions are equivalent to those from L<Sort::Key> that
have the same name:

  isort, usort, nsort, risort, rusort, rnsort, isort_inplace,
  usort_inplace, nsort_inplace, risort_inplace, rusort_inplace,
  rnsort_inplace, ikeysort, ukeysort, nkeysort, rikeysort, rukeysort,
  rnkeysort, ikeysort_inplace, ukeysort_inplace, nkeysort_inplace,
  rikeysort_inplace, rukeysort_inplace, rnkeysort_inplace

And the following are also provided:

=over 4

=item ssort, rssort, skeysort, ssort_inplace, etc.

First, these functions extend the keys to match the length of the
largest one, appending "\000" chars to their right.

Then they perform an alphabetic radix sort interpreting the keys as
byte strings (and that means that the unicode flag is ignored).

=item fsort, rfsort fkeysort, fsort_inplace, etc.

Before sorting the elements, these funcions convert the keys to single
floating point values.

They are only available on computers where the size of the C float
datatype is 32 bits.

=back

=head1 SEE ALSO

L<Sort::Key> and the Radix Sort algorithm description on the Wikipedia
L<http://en.wikipedia.org/wiki/Radix_sort>

=head1 BUGS AND SUPPORT

This is an early release of the module, expect bugs on it, and if you
find any, please, send me an email or use the CPAN bug tracking system
at L<http://rt.cpan.org> to report it!

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, 2012 by Salvador FandiE<ntilde>o (sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
