#!/usr/bin/perl 
# PODNAME: fetch-reqs.pl
#        USAGE: ./fetch-reqs.pl [--debug] [--quiet] [--notest] [--sudo] [[file|module] ...]
#  DESCRIPTION: install prerequisite modules for a Perl script with minimal prerequisites for this tool
#       AUTHOR: Ian Kluft (IKLUFT), 
#      CREATED: 04/14/2022 05:45:29 PM
# As part of Sys::OsPackage, this must be maintained for minimal dependencies to build systems and containers.

use strict;
use warnings;
use utf8;
use autodie;
use Carp qw(carp croak);
use Getopt::Long;
use Try::Tiny;
use Data::Dumper;
use Sys::OsPackage;

# collect CLI parameters with Getopt::Long, then initialize Sys::OsPackage
sub init_params
{
    # collect CLI parameters
    my %params;
    GetOptions ( \%params, "debug", "quiet", "notest", "sudo" );

    # initialize Sys::OsPackage
    Sys::OsPackage->init( (scalar keys %params > 0) ? \%params : () );
    Sys::OsPackage->establish_cpan(); # make sure CPAN is available

    return;
}


# process one item from command line
# returns 1 for success, 0 for failure
sub process
{
    my $target = shift;
    my $ospackage = Sys::OsPackage->instance();
    my $result = 1;

    my $basename;
    my $filename = $target;
    if (index($filename, '/') == -1) {
        # no directory provided so use pwd
        $basename = $filename;
        $filename = $ospackage->pwd()."/".$filename;
    } else {
        # $filename is a path so keep it that way, and extract basename
        $basename = substr($filename, rindex($filename, '/')+1);
    }
    $ospackage->debug() and print STDERR "debug(process): filename=$filename basename=$basename\n";

    # if the target doesn't specify an existing file, try to install it as a module name
    if ( not -e $filename ) {
        try {
            $result = $ospackage->install_module($target);
        } catch {
            carp "install failed for $target: $!";
            $result = 0;
            $ospackage->debug() and print STDERR "debug(process): install_module($target) failed\n";
        };
        $ospackage->debug() and print STDERR "debug(process): install_module($target) -> $result\n";
        return $result;
    }

    # scan for dependencies
    require Perl::PrereqScanner::NotQuiteLite;
    my $scanner = Perl::PrereqScanner::NotQuiteLite->new();
    my $deps_ref = $scanner->scan_file($filename);
    $ospackage->debug() and print STDERR "debug(process): deps_ref = ".Dumper($deps_ref)."\n";

    # load Perl modules for dependencies
    my $deps = $deps_ref->requires();
    $ospackage->debug() and print STDERR "deps = ".Dumper($deps)."\n";
    foreach my $module (sort keys %{$deps->{requirements}}) {
        next if $ospackage->mod_is_pragma($module);
        $ospackage->debug() and print STDERR "debug(process): install_module($module)\n";
        try {
            $result = $result and $ospackage->install_module($module);
        } catch {
            carp "install failed for $module: $!";
            $result = 0;
            $ospackage->debug() and print STDERR "debug(process): install_module($module) failed\n";
        };
    }
    $ospackage->debug() and print STDERR "debug(process): result -> $result\n";
    return $result;
}

#
# mainline
#

# main function called from exception-handling wrapper
sub main
{
    # set up
    init_params();
    my $ospackage = Sys::OsPackage->instance();
    $ospackage->debug() and print STDERR "main: begin\n";
    my $success = 1;

    # process command line
    if (@ARGV) {
        # process elements from command line
        foreach my $arg (@ARGV) {
            if ( not process($arg)) {
                $success = 0;
                $ospackage->debug() and print STDERR "main: process($arg) failed\n";
            }
        }
    } else {
        # if empty command line, process lines from STDIN, similar to cpanm usage
        while (my $target = <>) {
            chomp $target;
            if ( not process($target)) {
                $success = 0;
                $ospackage->debug() and print STDERR "main: process($target) failed\n";
            }
        }
    }
    $ospackage->debug() and print STDERR "main: end\n";
    return ($success ? 0 : 1);
}

# exception-handling wrapper for main()
my $rescode = 1; # assume failure until/unless success result is returned from main
try {
    $rescode = main();
} catch {
    print STDERR "error: $_\n";
};
exit $rescode;

=pod

=encoding UTF-8

=head1 NAME

fetch-reqs.pl

=head1 VERSION

version 0.3.1

=head1 DESCRIPTION

I<fetch-reqs.pl> is the command-line interface for L<Sys::OsPackage>. It installs prerequisite modules for
a named Perl script, or directly installs Perl modules via the OS packaging system.
It falls back to installation with CPAN if the module is not packaged for the OS.

=head1 USAGE

  fetch-reqs.pl [--debug] [--quiet] [--notest] [--sudo] filename|module [...]
  cat req-list.txt | fetch-reqs.pl [--debug] [--quiet] [--notest] [--sudo]

=head1 OPTIONS

The following command-line flags are available.

=over 1

=item --notest

Similar to the option in L<cpanm>, --notest installs modules without running automated tests.

=item --sudo

Similar to the option in L<cpanm>, the --sudo flag enables running commands with "sudo" to
run install commands as the root user.
The sudo command must be separately installed on the system or container if this is used.

=item --quiet

When this flag is on, output status is reduced.

=item --debug

This flag is used for development to print internal details of the program run.
If requesting help or submitting a bug report, it is useful to include this output for developers to see
what happened on your system.

=back

The files listed on the command line should either be file names of Perl scripts or modules
to scan for dependencies, or names of Perl modules to load.
Each file's Perl module dependencies or each named Perl module
will be installed by L<Sys::OsPackage> using operating system packages
if available, or otherwise via CPAN.

If no file or module names are inclued on the command line, then the standard input is read
for those parameters, each on their own separate line.

=head1 OS PACKAGING DRIVERS

L<Sys::OsPackage> currently contains OS packaging drivers for Fedora/RHEL/CentOS, Debian/Ubuntu, SuSE/OpenSuSE, Arch
and Alpine Linux and their derivatives.
More drivers can be added by creating new subclasses of L<Sys::OsPackage::Driver>.

=head1 EXIT STATUS

Standard Unix program exit codes are used: 0 if no error, 1 if error.

=head1 SEE ALSO

L<Sys::OsRelease> is used by I<Sys::OsPackage> to detect the operating system by its ID.
For Linux distributions, it also uses ID_LIKE data to detect common distirbutions it is derived from.
For example, Linux distributions derived from Debian or Red Hat are not all known,
but are recognizable with ID_LIKE.

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
