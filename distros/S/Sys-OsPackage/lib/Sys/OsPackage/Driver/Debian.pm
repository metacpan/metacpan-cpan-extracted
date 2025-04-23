# Sys::OsPackage::Driver::Debian
# ABSTRACT: Debian/Ubuntu DEB packaging handler for Sys::OsPackage
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

package Sys::OsPackage::Driver::Debian;
$Sys::OsPackage::Driver::Debian::VERSION = '0.4.0';
use parent "Sys::OsPackage::Driver";

# check if packager command found (deb)
sub pkgcmd
{
    my ( $class, $ospkg ) = @_;

    return ( defined $ospkg->sysenv("apt") ? 1 : 0 );
}

# find name of package for Perl module (deb)
sub modpkg
{
    my ( $class, $ospkg, $args_ref ) = @_;
    return if not $class->pkgcmd($ospkg);

    # search by deb format for Perl module packages
    my $pkgname = "lib" . join( "-", ( map { lc $_ } @{ $args_ref->{mod_parts} } ), "perl" );
    $args_ref->{pkg} = $pkgname;
    if ( not $class->find( $ospkg, $args_ref ) ) {
        return;
    }
    $ospkg->debug() and print STDERR "debug(" . __PACKAGE__ . "->modpkg): $pkgname\n";

    # package was found - return the simpler name since pkg add won't take this full string
    return $pkgname;

}

# find named package in repository (deb)
sub find
{
    my ( $class, $ospkg, $args_ref ) = @_;
    return if not $class->pkgcmd($ospkg);

    my $querycmd = $ospkg->sysenv("apt-cache");
    my @pkglist  = sort $ospkg->capture_cmd(
        { list => 1 },
        $ospkg->sudo_cmd(), $querycmd,
        qw(search --quiet=2),
        '^' . $args_ref->{pkg} . '$'
    );
    return if not scalar @pkglist;    # empty list means nothing found
    return $pkglist[-1];              # last of sorted list should be most recent version
}

# install package (deb)
sub install
{
    my ( $class, $ospkg, $args_ref ) = @_;
    return if not $class->pkgcmd($ospkg);

    # determine packages to install
    my @packages;
    if ( defined $args_ref->{pkg} ) {
        if ( ref $args_ref->{pkg} eq "ARRAY" ) {
            push @packages, @{ $args_ref->{pkg} };
        } else {
            push @packages, $args_ref->{pkg};
        }
    }

    # install the packages
    my $pkgcmd = $ospkg->sysenv("apt");
    return $ospkg->run_cmd( $ospkg->sudo_cmd(), $pkgcmd, "install", "--yes", @packages );
}

# check if an OS package is installed locally
sub is_installed
{
    my ( $class, $ospkg, $args_ref ) = @_;
    return if not $class->pkgcmd($ospkg);

    # check if package is installed
    my $querycmd = $ospkg->sysenv("dpkg-query");
    my @pkglist  = $ospkg->capture_cmd( { list => 1 },
        $ospkg->sudo_cmd(), $querycmd, '--show', '--showformat=\${package}\n', $args_ref->{pkg} );
    return ( scalar @pkglist > 0 ) ? 1 : 0;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Sys::OsPackage::Driver::Debian - Debian/Ubuntu DEB packaging handler for Sys::OsPackage

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
The driver implements these methods: I<pkgcmd>, I<modpkg>, I<find>, I<install> and I<ping>.

=head1 SEE ALSO

Debian Linux docs: Debian package management system L<https://www.debian.org/doc/manuals/debian-faq/pkg-basics.en.html>

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
