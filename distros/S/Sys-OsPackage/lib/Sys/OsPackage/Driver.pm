# Sys::OsPackage::Driver
# ABSTRACT: parent class for packaging handler drivers for Sys::OsPackage
# Copyright (c) 2022 by Ian Kluft
# Open Source license Perl's Artistic License 2.0: <http://www.perlfoundation.org/artistic_license_2_0>
# SPDX-License-Identifier: Artistic-2.0

# This module is maintained for minimal dependencies so it can build systems/containers from scratch.

## no critic (Modules::RequireExplicitPackage)
# This resolves conflicting Perl::Critic rules which want package and strictures each before the other
use strict;
use warnings;
use utf8;
## use critic (Modules::RequireExplicitPackage)

package Sys::OsPackage::Driver;
$Sys::OsPackage::Driver::VERSION = '0.4.0';

# demonstrate module is accessible without launching packaging commands
# all drivers inherit this to respond to ping for testing
sub ping
{
    my $class = shift;

    # enforce class lineage
    if ( not $class->isa(__PACKAGE__) ) {
        return __PACKAGE__;
    }

    return $class;
}

# demonstrate modules are able to read the sudo flag via Sys::OsPackage's class interface
# returns "sudo" if the sudo flag is set and user is not already root, otherwise an empty list
sub sudo_check
{
    my ( $class, $ospkg ) = @_;

    my $cmd = $ospkg->sudo_cmd();
    return $cmd;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Sys::OsPackage::Driver - parent class for packaging handler drivers for Sys::OsPackage

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

  my $ospkg = Sys::OsPackage->instance();

  # check if packaging commands exist for this system
  if (not $ospkg->call_pkg_driver(op => "implemented")) {
    return 0;
  }

  # find OS package name for Perl module
  my $pkgname = $ospkg->call_pkg_driver(op => "find", module => $module);

  # install a Perl module as an OS package
  my $result1 = $ospkg->call_pkg_driver(op => "modpkg", module => $module);

  # install an OS package
  my $result2 = $ospkg->call_pkg_driver(op => "install", pkg => $pkgname);

=head1 DESCRIPTION

⛔ This is for Sys::OsPackage internal use only.

The Sys::OsPackage method call_pkg_driver() will call the correct driver for the running platform.

All the platforms' packaging drivers must use this class as their parent class.

=head1 SEE ALSO

"pacman/Rosetta" at Arch Linux Wiki compares commands of 5 Linux packaging systems L<https://wiki.archlinux.org/title/Pacman/Rosetta>

GitHub repository for Sys::OsPackage: L<https://github.com/ikluft/Sys-OsPackage>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/Sys-OsPackage/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/Sys-OsPackage/pulls>

=head1 LICENSE INFORMATION

Copyright (c) 2022 by Ian Kluft

This module is distributed in the hope that it will be useful, but it is provided “as is” and without any express or implied warranties. For details, see the full text of the license in the file LICENSE or at L<https://www.perlfoundation.org/artistic-license-20.html>.

=head1 AUTHOR

Ian Kluft <cpan-dev@iankluft.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Ian Kluft.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

# POD documentation
