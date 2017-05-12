package Siebel::AssertOS;
use warnings;
use strict;
use Siebel::AssertOS::Linux::Distribution qw(distribution_name);

our $VERSION = "0.07";

sub import {

    shift;
    die_if_os_isnt();
}

sub die_if_os_isnt {

    my $os = shift || $^O;

    os_is($os) ? 1 : die_unsupported($os);

}

sub die_unsupported {

    my $os = shift;
    die "The operation system $os is not supported";

}

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

1;

__END__

=head1 NAME

Siebel::AssertOS - verifies if the OS is supported by Siebel applications

=head1 SYNOPSIS

    package Your::Package;
	use Siebel::AssertOS;

=head1 DESCRIPTION

This modules will help identifying if the current OS that is running is supported by Siebel applications. If not, the module will C<die>, 
forcing the code to stop being executed.

This is particulary useful for automated tests.

The list of supported OS is as defined by Oracle documentation regarding Siebel 8.2 and the list of OS from L<Devel::CheckOS> distribution. Actually, 
Siebel::AssertOS is based on L<Devel::CheckOS>, borrowing code from it, but does not depend on it.

Regarding supported Linux distributions, this module will also validate if the code is running on a supported by Siebel distribution.

=head2 EXPORT

None, but the functions below can be used by calling them with the complete package name (Siebel::AssertOS::<function>).

=head3 die_if_os_isnt

Expects an optional string parameter with the operational system name. If not given, it will assume $^O as default.

It will execute C<os_is> with the operational system name, calling C<die_unsuported> if the return value from C<os_is> is false.

Beware that the given parameter must follow the same provided by $^O, including case and format.
C<die_if_os_isnt> is called by default when the module is imported to another package.

=head3 die_unsupported

Expects a string as parameter.

Will execute C<die> with a message telling that the parameter is not supported.

=head3 os_is

Expects a string as parameter, being the string the OS name.

Returns true or false depending on the give value. The string is restricted by those return by $^O special variable.

=head1 SEE ALSO

=over

=item *

Oracle documentation about supported OS: L<http://docs.oracle.com/cd/E11886_01/V8/CORE/SRSP_81/SRSP_81_ServerEnv4.html#wp1009117>

=item *

L<Devel::CheckOS>

=item *

L<Linux::Distribution>

=item *

L<Devel::AssertOS::OSFeatures::SupportsSiebel> does almost the same thing, but implementation is different and it doesn't care about Linux distribution.

=item *

Project website: L<https://github.com/glasswalk3r/siebel-gnu-tools>.

=back

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

