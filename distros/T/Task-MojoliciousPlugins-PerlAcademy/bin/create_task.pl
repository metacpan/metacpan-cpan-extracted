#!/usr/bin/perl

# PODNAME: create_task

use strict;
use warnings;

use Data::Dumper;
use File::Basename;
use File::Spec;
use IO::File;
use MetaCPAN::Client;
use Parse::CPAN::Packages;
use LWP::Simple qw(getstore);
use File::Temp ();

our $VERSION = 0.01;

my $dist_ini = File::Spec->catfile(
    dirname( __FILE__ ),
    '..',
    'dist.ini',
);

my $file = File::Temp->new( UNLINK => 0, SUFFIX => '.txt.gz' );
if ( !$ARGV[0] || !-f $ARGV[0] || $ARGV[0] !~ /02packages\.details\.txt\.gz$/ ) {
    print STDERR "Download 02packages.details.txt.gz...\n";
    my $url = 'http://www.cpan.org/modules/02packages.details.txt.gz';
    getstore $url, $file->filename;
    $ARGV[0] = $file->filename;
    print "downloaded " . (-s $file->filename) . " bytes to " . $file->filename . "\n";
}

my %modules = get_modules($ARGV[0]);
write_prereqs( $dist_ini, %modules );
create_pod( %modules );

sub get_modules {
    my ($packages_file) = @_;

    print STDERR "Get modules...";

    my $parser        = Parse::CPAN::Packages->new( $packages_file );
    my @distributions = $parser->latest_distributions;
    my $mcpan         = MetaCPAN::Client->new;

    my %modules;
    for my $dist ( @distributions ) {
        my $name     = $dist->dist;

        next if $name !~ m!^Mojo (?:X|licious)!x;

        my $version  = $dist->version;

        print STDERR "found $name ($version)\n";

        my $abstract = $mcpan->release( $name )->abstract || '';

        $modules{$name} = +{ version => $version, abstract => $abstract };
    }

    print STDERR " found " . (scalar keys %modules) . "modules\n";

    return %modules;
}

sub write_prereqs {
    my ($config, %modules) = @_;

    print STDERR "write prereqs...\n";

    my $dist_ini = '';
    my $fh = IO::File->new( $config, 'r' );
    while ( my $line = $fh->getline ) {
        $dist_ini .= $line;
        last if $line =~ m{^\[Prereq};
    }
    $fh->close;

    $dist_ini .= "perl = 5.010001\n";
    for my $dist ( sort keys %modules ) {
        my $name = $dist =~ s/-/::/gr;
        $dist_ini .= sprintf "%s = %s\n", $name, $modules{$dist}->{version};
    }

    my $fh_write = IO::File->new( $config, 'w' );
    $fh_write->print( $dist_ini );
    $fh_write->close;
}

sub create_pod {
    my (%modules) = @_;

    print STDERR "write pod...\n";

    my $pm_file  = File::Spec->catfile(
        dirname( __FILE__ ),
        '..',
        'lib',
        'Task',
        'MojoliciousPlugins',
        'PerlAcademy.pm'
    );

    my $pod = '';
    my $pod_fh_r = IO::File->new( $pm_file, 'r' );
    while ( my $line = $pod_fh_r->getline ) {
        $pod .= $line;
        last if $line =~ m{^=over 4};
    }
    $pod_fh_r->close;

    my $pod_fh_w = IO::File->new( $pm_file, 'w' );
    $pod_fh_w->print( $pod, "\n" );
    for my $module ( sort keys %modules ) {
        my $abstract = $modules{$module}->{abstract};
        $pod_fh_w->print( sprintf "=item * %s\n\n%s\n\n", $module, $abstract );
    }
    $pod_fh_w->print( "=back\n" );
    $pod_fh_w->close;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

create_task

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
