use Feature::Compat::Class 0.04;

use v5.12;
use utf8;
use warnings;

=head1 NAME

String::License::Naming::SPDX - licenses as named by SPDX

=head1 VERSION

Version v0.0.5

=head1 SYNOPSIS

    use String::License::Naming::SPDX;

    my $spdx = String::License::Naming::SPDX->new;

    my $license = [ grep { /^(Expat|Perl)$/ } $spdx->list_licenses ];  # => is_deeply ['Perl']

=head1 DESCRIPTION

L<String::License::Naming> enumerates supported licenses
matching an ordered set of naming schemes,
or enumerates the names of supported license naming schemes.

Some licenses are known by different names.
E.g. the license "MIT" according to SPDX
is named "Expat" in Debian.

Some licenses are not always represented.
E.g. "Perl" is a (discouraged) license in Debian
while it is a relationship of several licenses with SPDX
(and that expression is recommended in Debian as well).

By default,
licenses are matched using naming schemes C<[ 'spdx', 'internal' ]>,
which lists all supported licenses,
preferrably by their SPDX name
or as fallback by an internal name.

=cut

package String::License::Naming::SPDX v0.0.5;

use Carp            qw(croak);
use Log::Any        ();
use List::SomeUtils qw(uniq);
use Regexp::Pattern::License 3.4.0;

use namespace::clean;

class String::License::Naming::SPDX :isa(String::License::Naming);

field $log;

=head1 CONSTRUCTOR

=over

=item new

Constructs and returns a String::License::Naming object.

Includes all licenses defined by SPDX,
and presents them by their SPDX shortname.

=back

=cut

field $schemes;

# TODO: maybe support seeding explicit keys
field $keys;

ADJUST {
	$log = Log::Any->get_logger;

	$schemes = ['spdx'];

	$keys = [
		String::License::Naming::resolve_shortnames( $keys, $schemes, 1 ) ];
}

=head1 FUNCTIONS

=item list_schemes

Returns a list of license naming schemes in use.

=cut

method list_schemes
{
	return @$schemes;
}

=item list_licenses

Returns a list of all licensing patterns covered by SPDX,
each labeled by SPDX shortname.

=cut

method list_licenses
{
	return String::License::Naming::resolve_shortnames( $keys, $schemes );
}

=back

=encoding UTF-8

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>

=head1 COPYRIGHT AND LICENSE

  Copyright © 2023 Jonas Smedegaard

This program is free software:
you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License
as published by the Free Software Foundation,
either version 3, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY;
without even the implied warranty
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Affero General Public License for more details.

You should have received a copy
of the GNU Affero General Public License along with this program.
If not, see <https://www.gnu.org/licenses/>.

=cut

1;
