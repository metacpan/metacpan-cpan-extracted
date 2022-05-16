#!/usr/bin/env perl 
# PODNAME: fetch-reqs.pl
#        USAGE: ./fetch-reqs.pl  
#  DESCRIPTION: install prerequisite modules for a Perl script with minimal prerequisites for this tool
#       AUTHOR: Ian Kluft (IKLUFT), 
#      CREATED: 04/14/2022 05:45:29 PM
# As part of Sys::OsPackage, this must be maintained for minimal dependencies to build systems and containers.

use strict;
use warnings;
use utf8;
use autodie;
use Carp qw(carp croak);
use Data::Dumper;
use Sys::OsPackage;

sub process
{
    my $filename = shift;
    my $ospackage = Sys::OsPackage->instance();

    my $basename;
    if (index($filename, '/') == -1) {
        # no directory provided so use pwd
        $basename = $filename;
        $filename = $ospackage->pwd()."/".$filename;
    } else {
        # $filename is a path so keep it that way, and extract basename
        $basename = substr($filename, rindex($filename, '/')+1);
    }
    $ospackage->debug() and print STDERR "debug(process): filename=$filename basename=$basename\n";

    # scan for dependencies
    require Perl::PrereqScanner::NotQuiteLite;
    my $scanner = Perl::PrereqScanner::NotQuiteLite->new();
    my $deps_ref = $scanner->scan_file($filename);
    $ospackage->debug() and print STDERR "debug: deps_ref = ".Dumper($deps_ref)."\n";

    # load Perl modules for dependencies
    my $deps = $deps_ref->requires();
    $ospackage->debug() and print STDERR "deps = ".Dumper($deps)."\n";
    foreach my $module (sort keys %{$deps->{requirements}}) {
        next if $ospackage->mod_is_pragma($module);
        $ospackage->debug() and print STDERR "install_module($module)\n";
        $ospackage->install_module($module);
    }
    return;
}

#
# mainline
#

# set up
Sys::OsPackage->init();
Sys::OsPackage->establish_cpan(); # make sure CPAN is available

# process command line
foreach my $arg (@ARGV) {
    process($arg);
}

=pod

=encoding UTF-8

=head1 NAME

fetch-reqs.pl

=head1 VERSION

version 0.1.2

=head1 NAME

fetch-reqs.pl - install prerequisite modules for a Perl script with minimal prerequisites for this tool

=head1 USAGE

  fetch-reqs.pl filename [...]

=head1 OPTIONS

The files listed on the command line should all be Perl scripts or modules to scan for dependencies.
Each file's Perl module dependencies will be installed by L<Sys::OsPackage> by operating system packages
if available, or otherwise via CPAN.

=head1 EXIT STATUS

Program exit codes are 0 if no error, 1 if error.

=head1 SEE ALSO

L<Sys::OsPackage>

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
