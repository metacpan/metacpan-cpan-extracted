package Sort::Key::LargeInt;

use strict;
use warnings;

BEGIN {
    our $VERSION = '0.01';
    require XSLoader;
    XSLoader::load('Sort::Key::LargeInt', $VERSION);
}

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( largeintkeysort
		     largeintkeysort_inplace
		     rlargeintkeysort
		     rlargeintkeysort_inplace
		     largeintsort
		     largeintsort_inplace
		     rlargeintsort
		     rlargeintsort_inplace
		     encode_largeint
		     encode_largeint_hex);

sub encode_largeint_hex {
    join " ", map sprintf("%02x", ord($_)), split //, encode_largeint(@_);
}

use Sort::Key::Register largeint => \&encode_largeint, 'str';

use Sort::Key::Maker largeintkeysort => 'largeint';
use Sort::Key::Maker rlargeintkeysort => '-largeint';
use Sort::Key::Maker largeintsort => \&encode_largeint, 'str';
use Sort::Key::Maker rlargeintsort => \&encode_largeint, '-str';

1;
__END__

=head1 NAME

Sort::Key::LargeInt - sort large integers very fast

=head1 SYNOPSIS

  use Sort::Key::LargeInt qw(largeintsort);
  my @data = qw(+8970938740872304
                -12
                98_908_345_309_345_345_353_453_466_545_645_676_567
                ...);
  my @sorted = largeintsort @data;

=head1 DESCRIPTION

This module extends the L<Sort::Key> family of modules to support
sorting strings containing integer numbers of arbitrary length
(referred by this module as large-integers) numerically.

Large-integers must match the following regular expresion:

  /^[+\-]?[\d_]*$/

=head2 FUNCTIONS

The functions that can be imported from this module are:

=over 4

=item largeintsort @data

returns the large-integer values in C<@data> sorted.

=item rlargeintsort @data

returns the large-integer values in C<@data> sorted in descending order.

=item largeintkeysort { CALC_KEY($_) } @data

returns the elements on C<@array> sorted by the large-integer
keys resulting from applying them C<CALC_KEY>.

=item rlargeintkeysort { CALC_KEY($_) } @data

is similar to C<largeintkeysort> but sorts the elements in descending
order.

=item largeintsort_inplace @data

=item rlargeintsort_inplace @data

=item largeintkeysort_inplace { CALC_KEY($_) } @data

=item rlargeintkeysort_inplace { CALC_KEY($_) } @data

these functions are similar respectively to C<largeintsort>, C<rlargeintsort>,
C<largeintsortkey> and C<rlargeintsortkey>, but they sort the array C<@data> in
place.

=back

=head1 SEE ALSO

L<Sort::Key>, L<Sort::Key::Maker>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2009 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
