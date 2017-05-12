package Sort::Key::DateTime;

our $VERSION = '0.07';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(dtkeysort
                    dtkeysort_inplace
                    rdtkeysort
                    rdtkeysort_inplac
                    dtsort
                    dtsort_inplace
                    rdtsort
                    rdtsort_inplace
                    mkkey_datetime
                    dtcmpstr);

use Sort::Key qw(keysort_inplace);
use DateTime;
use Carp;

sub dtcmpstr ($) {
    my $dt=shift;
    my $key = eval { sprintf("%010d%06d%010d", $dt->utc_rd_values) };
    $@ and croak "sorting key '$dt' generated for element '$_' is not a valid DateTime object ($@)";
    $key;
}

sub mkkey_datetime {
    my $dt = @_ ? shift : $_;
    sprintf("%010d%06d%010d", $dt->utc_rd_values);
}

use Sort::Key::Register dt => \&mkkey_datetime, 'string';
use Sort::Key::Register datetime => \&mkkey_datetime, 'string';

use Sort::Key::Maker dtkeysort => 'dt';
use Sort::Key::Maker rdtkeysort => '-dt';
use Sort::Key::Maker dtsort => \&mkkey_datetime, 'str';
use Sort::Key::Maker rdtsort => \&mkkey_datetime, '-str';



1;
__END__

=head1 NAME

Sort::Key::DateTime - Perl extension for sorting objects by some DateTime key

=head1 SYNOPSIS


  use Sort::Key::DateTime qw(dtkeysort);
  my @sorted = dtkeysort { $_->date } @meetings;


=head1 DESCRIPTION

Sort::Key::DateTime allows to sort objects by some (calculated) key of
type DateTime.

=head2 EXPORTS

=over 4

=item dtkeysort { CALC_DT_KEY } @array

returns the elements on C<@array> sorted by the DateTime key
calculated applying C<{ CALC_DT_KEY }> to them.

Inside C<{ CALC_DT_KEY }>, the object is available as C<$_>.

NOTE: sorting order is undefined when floating and non floating
DateTime keys are mixed.

=item rdtkeysort { CALC_DT_KEY } @array

sorted C<@array> in descending order

=item dtsort(@array)

=item rdtsort(@array)

sort an array of DateTime objects in ascending and descending order
respectively.

Example:

  my @sorted = dtsort @unsorted;


=item dtkeysort_inplace { CALC_DT_KEY } @array

=item rdtkeysort_inplace { CALC_DT_KEY } @array

=item dtsort @array

=item rdtsort @array

sort C<@array> in place.

=item mkkey_datetime($dt)

generates string sorting keys for DateTime objects

=back

=head1 SEE ALSO

L<Sort::Key>, L<Sort::Key::Maker>, perl L<sort> function docs.

L<DateTime> module documentation and FAQ available from the DateTime
project web site at L<http://datetime.perl.org/>

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2010 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
