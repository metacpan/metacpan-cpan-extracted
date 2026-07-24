package TOML::XS::Timestamp;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

TOML::XS::Timestamp - Object representation of a L<TOML|https://toml.io>
timestamp

=head1 SYNOPSIS

See L<TOML::XS>.

=head1 DESCRIPTION

Instances of this class represent a parse of a TOML timestamp.

This class is not directly instantiable.

=head1 ACCESSOR METHODS

Any of the following may be undef, depending on the original TOML.

=over

=item * C<year()>

=item * C<month()>

=item * C<day()> (alias: C<date()>)

=item * C<hour()> (alias: C<hours()>)

=item * C<minute()> (alias: C<minutes()>)

=item * C<second()> (alias: C<seconds()>)

=item * C<millisecond()> (alias: C<milliseconds()>)

=item * C<microsecond()> (alias: C<microseconds()>)

=item * C<timezone()> (string)

=back

=head1 OTHER METHODS

=head2 $str = I<OBJ>->to_string()

Returns a string that represents I<OBJ>.

=cut
