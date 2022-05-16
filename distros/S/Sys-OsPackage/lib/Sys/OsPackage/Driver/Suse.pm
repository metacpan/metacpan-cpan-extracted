# Sys::OsPackage::Driver::Suse
# ABSTRACT: SUSE/OpenSUSE Zypper packaging handler for Sys::OsPackage
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

package Sys::OsPackage::Driver::Suse;
$Sys::OsPackage::Driver::Suse::VERSION = '0.1.2';
use base "Sys::OsPackage::Driver";

# check if packager command found (zypper)
sub pkgcmd
{
    my ($class, $ospkg) = @_;

    return (defined $ospkg->sysenv("zypper") ? 1 : 0);
}

# find name of package for Perl module (zypper)
sub modpkg
{
    my ($class, $ospkg, $args_ref) = @_;
    return if not $class->pkgcmd($ospkg);

    #return join("-", "perl", @{$args_ref->{mod_parts}}); # zypper/rpm format for Perl module packages
    my @querycmd = $ospkg->sysenv("zypper");
    my @pkglist = sort $ospkg->capture_cmd({list=>1}, @querycmd,
        qw(--non-interactive --quiet --terse search --provides --type=package --match-exact),
        "'perl(".$args_ref->{module}.")'");
    $ospkg->debug()
        and print STDERR "debug(".__PACKAGE__."->modpkg): ".$args_ref->{module}." -> ".join(" ", @pkglist)."\n";
    return if not scalar @pkglist; # empty list means nothing found
    splice @pkglist, 0, 3; # remove table header in 3 leading lines
    my $pkg_found = $pkglist[-1]; # get last entry from table
    $pkg_found =~ s/^[^\|]*\|\s*//x; # remove 1st column
    $pkg_found =~ s/\s*\|.*$//x; # remove 3rd & following columns
    return $pkg_found;
}

# find named package in repository (zypper)
sub find
{
    my ($class, $ospkg, $args_ref) = @_;
    return if not $class->pkgcmd($ospkg);

    my @querycmd = $ospkg->sysenv("zypper");
    my @pkglist = sort $ospkg->capture_cmd({list=>1}, @querycmd,
        qw(--non-interactive --quiet --terse search --provides --type=package --match-exact),
        $args_ref->{pkg});
    return if not scalar @pkglist; # empty list means nothing found
    splice @pkglist, 0, 3; # remove table header in 3 leading lines
    my $pkg_found = $pkglist[-1]; # get last entry from table
    $pkg_found =~ s/^[^\|]*\|\s*//x; # remove 1st column
    $pkg_found =~ s/\s*\|.*$//x; # remove 3rd & following columns
    return $pkg_found;
}

# install package (zypper)
sub install
{
    my ($class, $ospkg, $args_ref) = @_;
    return if not $class->pkgcmd($ospkg);

    # determine packages to install
    my @packages;
    if (exists $args_ref->{pkg}) {
        if (ref $args_ref->{pkg} eq "ARRAY") {
            push @packages, @{$args_ref->{pkg}};
        } else {
            push @packages, $args_ref->{pkg};
        }
    }

    # install the packages
    my $pkgcmd = $ospkg->sysenv("zypper");
    return $ospkg->run_cmd($pkgcmd, qw(--non-interactive --quiet --terse install), @packages);
}

# check if an OS package is installed locally
sub is_installed
{
    my ($class, $ospkg, $args_ref) = @_;
    return if not $class->pkgcmd($ospkg);

    # check if package is installed
    my $querycmd = $ospkg->sysenv("rpm");
    my @pkglist = $ospkg->capture_cmd({list=>1}, $querycmd, qw(--query), $args_ref->{pkg});
    return (scalar @pkglist > 0) ? 1 : 0;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Sys::OsPackage::Driver::Suse - SUSE/OpenSUSE Zypper packaging handler for Sys::OsPackage

=head1 VERSION

version 0.1.2

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
The driver implements these methods: I<pkgcmd>, I<modpkg>, I<find>, I<install>, I<is_installed> and I<ping>.

=head1 SEE ALSO

OpenSuSE Linux docs: Portal:Zypper L<https://en.opensuse.org/Portal:Zypper>

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
