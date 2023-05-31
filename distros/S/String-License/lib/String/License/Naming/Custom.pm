use Feature::Compat::Class 0.04;

use v5.12;
use utf8;
use warnings;

=head1 NAME

String::License::Naming - names of licenses and license naming schemes

=head1 VERSION

Version v0.0.5

=head1 SYNOPSIS

    use String::License::Naming::Custom;

    my $obj = String::License::Naming::Custom->new( schemes => [qw(spdx internal)] );

    my $schemes = [ $obj->list_schemes ];  # => is_deeply [ 'spdx', 'internal' ]

    my $license = [ grep { /^(Expat|Perl)$/ } $obj->list_licenses ];  # => is_deeply ['Perl']

    # use and prefer Debian-specific identifiers
    $schemes = [ $obj->add_scheme('debian') ];  # => is_deeply [ 'debian', 'spdx', 'internal' ]

    $license = [ grep { /^(Expat|Perl)$/ } $obj->list_licenses ];  # => is_deeply [ 'Expat', 'Perl' ]

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

package String::License::Naming::Custom v0.0.5;

use Carp            qw(croak);
use Log::Any        ();
use List::SomeUtils qw(uniq);
use Regexp::Pattern::License 3.4.0;

use namespace::clean;

class String::License::Naming::Custom :isa(String::License::Naming);

field $log;

=head1 CONSTRUCTOR

=over

=item new

    my $names = String::License::Naming->new;

    my $spdx_names = String::License::Naming->new( schemes => ['spdx'] );

Constructs and returns a String::License::Naming object.

Takes an optional array as named argument B<schemes>.
both ordering by which name licenses should be presented,
and limiting which licenses to cover.

When omitted,
the default schemes array C<[ 'spdx', 'internal' ]> is used,
which includes all supported licenses,
and they are presented by their SPDX name when defined
or otherwise by a semi-stable internal name.

When passing an empty array reference,
all supported licenses are included,
presented by a semi-stable internal potentially multi-word description.

=back

=cut

field $schemes :param = undef;

# TODO: maybe support seeding explicit keys
field $keys;

ADJUST {
	$log = Log::Any->get_logger;

	if ( defined $schemes ) {

		croak $log->fatal('parameter "schemes" must be an array reference')
			unless ref $schemes eq 'ARRAY';

		# TODO: die unless each arrayref entry is a string and supported

		my @uniq_schemes = uniq @$schemes;
		if ( join( ' ', @$schemes ) ne join( ' ', @uniq_schemes ) ) {
			$log->warn("duplicate scheme(s) omitted");
			@$schemes = \@uniq_schemes;
		}
	}
	else {
		$schemes = [];
	}

	$keys = [
		String::License::Naming::resolve_shortnames( $keys, $schemes, 1 ) ];
}

=head1 FUNCTIONS

=over

=item add_scheme

Takes a string representing a license naming scheme to use,
favored over existing schemes in use.

Returns array of schemes in use after addition.

=cut

method add_scheme
{
	my ($new_scheme) = @_;
	croak $log->fatal("no new scheme provided")
		unless $new_scheme;
	$log->warn("excess arguments beyond new scheme ignored")
		if @_ > 1;

	if ( grep { $_ eq $new_scheme } @$schemes ) {
		$log->warn("already included scheme $new_scheme not added");
		return @$schemes;
	}

	# TODO: validate new entry is string and supported, or die
	unshift @$schemes, $new_scheme;

	return @$schemes;
}

=item list_schemes

Returns a list of license naming schemes in use.

=cut

method list_schemes
{
	return @$schemes;
}

=item list_available_schemes

Returns a list of all license naming schemes available.

=cut

method list_available_schemes
{
	my $_prop = '(?:[a-z][a-z0-9_]*)';
	my $_any  = '[a-z0-9_.()]';

	my @result = uniq sort
		map  {/^(?:name|caption)\.alt\.org\.($_prop)$_any*/}
		map  { keys %{ $Regexp::Pattern::License::RE{$_} } }
		grep {/^[a-z]/} keys %Regexp::Pattern::License::RE;

	return @result;
}

=item list_licenses

Returns a list of licensing patterns covered by this object instance,
each labeled by shortname according to current set of schemes.

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
