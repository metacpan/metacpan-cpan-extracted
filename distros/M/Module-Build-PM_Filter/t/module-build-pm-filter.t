#!/usr/bin/perl

use strict;
use warnings;
use Carp;
use IO::File;

use lib qw(lib);

use File::Temp qw(tempdir);
use File::Copy::Recursive qw(dircopy);
use Test::More qw(no_plan);

use Module::Build::PM_Filter;

# create a temp directory
my $output_dir = tempdir( CLEANUP => 1 );

SKIP: {
    skip "could not use a temp directory" unless $output_dir;

    # make a copy of the examples directory contents ...
    dircopy( q(examples), $output_dir ) or 
        skip "could not copy the examples directory to ${output_dir}";

    # change to the temp dir ...
    chdir $output_dir;

    # some initial dispositions
    foreach my $script qw(pm_filter debian/rules) {
        if (-e $script and not -x $script) {    
            chmod oct(544), $script || 
                die "could not change permissions on ${script}";
        }
    }

    # create a class from the Build.PL file in the current directory, and do the
    # first action: build 
    my $class = q(Module::Build::PM_Filter);
    my $builder = $class->new_from_context( verbose => 0 );
    isa_ok($builder, $class);

    # check the existence of a Build script
    ok(-e q(Build), "Build script created" );

    #   build the package 
    $builder->dispatch( 'build' );

    # check the existence of a blib version of the module 
    my $bmodule = q(blib/lib/MyModule.pm);
    ok(-e $bmodule, "build action completed");

    # and verify that the pm_filter is working
    ok( _search_pm_filter_string( $bmodule ), "pm_filter in build action");

    # make the distribution directory
    $builder->dispatch('distdir');
    my $distdir = $builder->dist_dir();
    ok(-d $distdir, "distdir action completed");
    ok(-x "${distdir}/pm_filter", "pm_filter is executable");
    ok(-x "${distdir}/debian/rules", "debian/rules is executable");

    # final clean
    $builder->dispatch('distclean');
}

sub _search_pm_filter_string {
    my  $file   =   shift;
    my  $found  =   0;

    if (my $pf = IO::File->new( $file, "<" )) {
        while (my $line = <$pf>) {
            if ($line =~ m{PM_Filter\s+is\s+working}xms) {
                $found = 1;
                last;
            }
        }
        $pf->close();
    }
    else {
        croak "could not open ${file} for reading";
    }

    return $found;
}

