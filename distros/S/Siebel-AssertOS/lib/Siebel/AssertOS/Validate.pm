package Siebel::AssertOS::Validate;

use warnings;
use strict;
use Exporter qw(import);
use Siebel::AssertOS::Linux::Distribution qw(distribution_name);
our $VERSION = '0.9'; # VERSION

=pod

=head1 NAME

Siebel::AssertOS::Validate - validate is OS is supported or not

=head1 DESCRIPTION

This module does the proper validation used on L<Siebel::AssertOS> while it's being
imported. See B<EXPORT>.

This module was created basically to facilitate unit testing.

=head1 EXPORT

Nothing is exported by default.

The function C<os_is> is the only function exported by demand of this module.

=cut

our @EXPORT_OK = qw(os_is);

=head1 FUNCTIONS

=head2 os_is

Expects a string as parameter, being the string the name of the OS (like C<$^O> environment variable).

It returns true or false (in Perl terms) if the OS is supported or not.

In the case of Linux, it will also C<warn> if the distribution is not support and the return false.

=cut

sub os_is {
    my $os = shift;

    if ( $os eq 'linux' ) {
        # supported Linux distribuitions
        my %distros =
          ( redhat => 1, suse => 1, 'oracle enterprise linux' => 1 );
        my $distro = distribution_name();

        if ( exists( $distros{$distro} ) ) {
            return 1;
        }
        else {
            warn "The Linux distribution '$distro' is not supported";
            return 0;
        }

    }

    return 1 if ( $os eq 'MSWin32' );
    return 1 if ( $os eq 'aix' );
    return 1 if ( $os eq 'solaris' );

    if ( $os eq 'hpux' ) {
        return 1;
    }
    else {
        return 0;
    }

}

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel GNU Tools project.

Siebel GNU Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel GNU Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel GNU Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
