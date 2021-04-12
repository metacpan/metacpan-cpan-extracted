package TOML::XS::Timestamp;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

TOML::XS::Document - Object representation of a L<TOML|https://toml.io/> timestamp

=head1 SYNOPSIS

See L<TOML::XS>.

=head1 DESCRIPTION

This object represents a parse of a TOML timestamp. It is not
directly instantiable.

=head1 ACCESSOR METHODS

Any of the following may be undef:

=over

=item * C<year()>

=item * C<month()>

=item * C<day()> (alias: C<date()>)

=item * C<hour()> (alias: C<hours()>)

=item * C<minute()> (alias: C<minutes()>)

=item * C<second()> (alias: C<seconds()>)

=item * C<millisecond()> (alias: C<milliseconds()>)

=item * C<timezone()>

=back

=head1 OTHER METHODS

=head2 $str = I<OBJ>->to_string()

Returns a string that represents I<OBJ>.

=cut
