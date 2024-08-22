use v5.20;
use utf8;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Feature::Compat::Class 0.07;

=head1 NAME

String::License::Naming - base class for names of licenses and license naming schemes

=head1 VERSION

Version v0.0.11

=head1 DESCRIPTION

L<String::License::Naming> is a base class
for how to constrain, enumerate, and present licenses.

This class cannot be instantiated on its own.
Please use a subclass instead,
e.g. L<String::License::Naming::SPDX>.

=cut

package String::License::Naming v0.0.11;

use namespace::clean;

class String::License::Naming;

method list_schemes () { ...; }

method list_licenses () { ...; }

sub resolve_shortnames ( $keys, $schemes, $bootstrap = undef )
{
	my ( @schemes, $fallback, %names, @result );

	$keys = [ sort keys %Regexp::Pattern::License::RE ]
		unless defined $keys and scalar @$keys;

	for (@$schemes) {
		if ( $_ eq 'internal' ) {
			$fallback = 1;
			last;
		}
		push @schemes, $_;
	}

	KEY:
	for my $key (@$keys) {
		for my $key2 (
			@schemes
			? sort keys %{ $Regexp::Pattern::License::RE{$key} }
			: ()
			)
		{
			my ( %attr, @attr );

			@attr = split /[.]/, $key2;

			next unless $attr[0] eq 'name';

			# TODO: simplify, and require R::P::License v3.8.1
			if ( $Regexp::Pattern::License::VERSION < v3.8.1 ) {
				push @attr, undef
					if @attr % 2;
				%attr = @attr[ 2 .. $#attr ];
				next if exists $attr{version};
				next if exists $attr{until};
			}
			else {
				%attr = @attr[ 2 .. $#attr ];
				next if exists $attr{until};
			}
			for my $org (@schemes) {
				if ( exists $attr{org} and $attr{org} eq $org ) {
					$names{$key} = $Regexp::Pattern::License::RE{$key}{$key2};
					next KEY;
				}
			}
		}
		if ($fallback) {
			$names{$key} = $Regexp::Pattern::License::RE{$key}{name} // $key;
		}
		elsif ( exists $Regexp::Pattern::License::RE{$key}{name} ) {
			$names{$key} = $Regexp::Pattern::License::RE{$key}{name};
		}
	}

	@result = $bootstrap ? sort keys %names : sort { lc $a cmp lc $b }
		values %names;

	return @result;
}

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
