package Sort::Key::OID;

use strict;
use warnings;

BEGIN {
    our $VERSION = '0.05';

    require XSLoader;
    XSLoader::load('Sort::Key::OID', $VERSION);
}

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( oidkeysort
                     oidkeysort_inplace
                     roidkeysort
                     roidkeysort_inplace
                     oidsort
                     oidsort_inplace
                     roidsort
                     roidsort_inplace
                     encode_oid
                     encode_oid_hex);

sub encode_oid_hex {
    join " ", map sprintf("%02x", ord($_)), split //, encode_oid(@_);
}

use Sort::Key::Register oid => \&encode_oid, 'str';

use Sort::Key::Maker oidkeysort => 'oid';
use Sort::Key::Maker roidkeysort => '-oid';
use Sort::Key::Maker oidsort => \&encode_oid, 'str';
use Sort::Key::Maker roidsort => \&encode_oid, '-str';

1;

__END__

=head1 NAME

Sort::Key::OID - sort OIDs very fast

=head1 SYNOPSIS

  use Sort::Key::OID qw(oidsort);
  my @data = qw(1 1.2 1.1.3 1.4.1.1 1.5.235.2356 1.1);
  my @sorted = oidsort @data;

=head1 DESCRIPTION

This module extends the L<Sort::Key> family of modules to support
sorting of OID values.

Also, once this module is loaded, the new type C<oid> will be
available from L<Sort::Key::Maker>.

Valid OIDs are sequences of unsigned integers separated by some
symbol. For instance:

   1.2.3.45  # valid
   1-2-3-45  # valid
   1 2 3 45  # valid
   1:2:3:45  # valid

   1..2.3.45 # invalid
   1  2 3 45 # invalid
   1:2.3 45  # invalid

=head2 FUNCTIONS

The functions that can be imported from this module are:

=over 4

=item oidsort @data

returns the OID values in C<@data> sorted.

=item roidsort @data

returns the OID values in C<@data> sorted in descending order.

=item oidkeysort { CALC_KEY($_) } @data

returns the elements on C<@array> sorted by the OID
keys resulting from applying them C<CALC_KEY>.

=item roidkeysort { CALC_KEY($_) } @data

is similar to C<oidkeysort> but sorts the elements in descending
order.

=item oidsort_inplace @data

=item roidsort_inplace @data

=item oidkeysort_inplace { CALC_KEY($_) } @data

=item roidkeysort_inplace { CALC_KEY($_) } @data

these functions are similar respectively to C<oidsort>, C<roidsort>,
C<oidsortkey> and C<roidsortkey>, but they sort the array C<@data> in
place.

=back

=head1 SEE ALSO

L<Sort::Key>, L<Sort::Key::Maker>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2007-2009 by Salvador FandiE<ntilde>o
E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
