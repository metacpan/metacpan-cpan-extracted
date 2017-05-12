package PkgForge::Utils;    # -*- perl -*-
use strict;
use warnings;

# $Id: Utils.pm.in 15529 2011-01-19 08:37:34Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15529 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge/Utils.pm.in $
# $Date: 2011-01-19 08:37:34 +0000 (Wed, 19 Jan 2011) $

our $VERSION = '1.4.8';

use English qw(-no_match_vars);
use File::Find::Rule ();
use File::Spec       ();
use IO::Dir          ();

sub remove_tree {
    my ( $top_dir, $options ) = @_;

    $options ||= {};

    # This is designed to be mostly compatible with remove_tree() in
    # newer versions of File::Path

    my $verbose   = $options->{verbose};
    my $errors    = $options->{error};
    my $results   = $options->{result};
    my $keep_root = $options->{keep_root};

    my $count;

    if ( !-d $top_dir ) {
        return 0;
    }

    my @files =
      File::Find::Rule->not( File::Find::Rule->directory )->in($top_dir);

    for my $file (@files) {
        my $ok = unlink $file;
        if ($ok) {
            $count++;
            print $file . "\n" if $verbose;
            push @{$results}, $file if $results;
        } else {
            push @{$errors}, $file if $errors;
        }
    }

    my @dirs;
    if ( -d $top_dir ) {
        list_dirs( $top_dir, \@dirs );
    }

    for my $dir (@dirs) {
        my $ok = rmdir $dir;
        if ($ok) {
            $count++;
            print $dir . "\n" if $verbose;
            push @{$results}, $dir if $results;
        } else {
            push @{$errors}, $dir if $errors;
        }
    }

    if ( !$keep_root ) {
        my $ok = rmdir $top_dir;
        if ($ok) {
            $count++;
            print $top_dir . "\n" if $verbose;
            push @{$results}, $top_dir if $results;
        } else {
            push @{$errors}, $top_dir if $errors;
        }
    }

    return $count;
}

sub list_dirs {
    my ( $dir, $list ) = @_;

    my $dh = IO::Dir->new($dir)
      or die "Could not open $dir: $OS_ERROR\n";

    while ( defined( my $item = $dh->read ) ) {
        if ( $item eq q{.} || $item eq q{..} ) {
            next;
        }

        my $path = File::Spec->catdir( $dir, $item );
        if ( -d $path ) {
            list_dirs( $path, $list );

            push @{$list}, $path;
        }
    }

    return;
}

sub kinit {
    my ( $keytab, $principal, $ccache ) = @_;

    $ccache ||= 'MEMORY:pkgforge_' . int(rand(10000));

    require Authen::Krb5;

    Authen::Krb5::init_context()
      or die "Failed to initialise Krb5 context\n";

    my $client = Authen::Krb5::parse_name($principal)
      or die Authen::Krb5::error() . " while parsing client principal\n";

    my $server = Authen::Krb5::parse_name( 'krbtgt/' . $client->realm )
      or die Authen::Krb5::error() . " while parsing server principal\n";

    my $cc = Authen::Krb5::cc_resolve($ccache)
      or die Authen::Krb5::error() . " while resolving ccache\n";

    $cc->initialize($client)
      or die Authen::Krb5::error() . " while initializing ccache\n";

    my $kt=Authen::Krb5::kt_resolve($keytab)
      or die Authen::Krb5::error() . " while resolving keytab\n";

    Authen::Krb5::get_in_tkt_with_keytab( $client, $server, $kt, $cc )
      or die Authen::Krb5::error() . " while getting ticket\n";

    $ENV{KRB5CCNAME} = $ccache;

    return;
}

sub job_resultsdir {
    my ( $results_base, $uuid ) = @_;

    my $resultsdir = File::Spec->catdir( $results_base, $uuid );

    return $resultsdir;
}



1;
__END__

=head1 NAME

PkgForge::Utils - General utilities for the LCFG Package Forge

=head1 VERSION

This documentation refers to PkgForge::Utils version 1.4.8

=head1 SYNOPSIS

     use PkgForge::Utils;

     PkgForge::Utils::remove_tree($dir);

=head1 DESCRIPTION

This module provides various utility functions which are used
throughout the LCFG Package Forge software suite.

=head1 SUBROUTINES/METHODS

=over

=item remove_tree($dir,[$options]);

This will remove a tree of files and directories in a similar way to
the function with the same name in newer versions of the L<File::Path>
module. It takes a directory name and an optional reference to a hash
of options. It returns the number of files and directories which have
been deleted. The supported options are:

=over

=item verbose

A boolean, when this is true the files and directories removed will be
printed to STDOUT, defaults to false.

=item keep_root

A boolean, when this is true the top-level directory itself will not
be removed, only the contents would be erased. This defaults to false.

=item result

A reference to an array into which the list of removed files and
directories will be added.

=item error

A reference to an array into which the list of any failures to remove
files and directories will be added.

=back

=item list_dirs( $dir, $list )

This function will find all the sub-directories of the specified
directory. It puts them into an array (which is referenced in the
second required argument) which is ordered such that the
sub-directories are before the directory itself. This is used by
C<remove_tree>.

=item kinit( $keytab, $principal, $ccache )

This does the equivalent of kinit(1) using the specified keytab and
principal. Optionally you can specify the credentials cache to use, by
default it uses a memory cache. The KRB5CCNAME environment variable
will be set so that Kerberos-aware modules (such as DBI) will
automatically use the credentials cache.

=item job_resultsdir( $results_base, $job_uuid )

This computes and returns the job-specific results directory given the
base directory and the UUID for the job.

=back

=head1 DEPENDENCIES

This module requires L<File::Find::Rule>. To use the C<kinit> method
you will also need the L<Authen::Krb5> to be installed.

=head1 SEE ALSO

L<PkgForge>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux5, Fedora13

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2010-2011 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
