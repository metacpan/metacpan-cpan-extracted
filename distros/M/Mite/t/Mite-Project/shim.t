#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Path::Tiny;

my $Orig_Cwd = Path::Tiny->cwd;

tests add_mite_shim => sub {
    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    my $project = sim_project;
    $project->init_project("Foo::Bar");

    my $shim = path($project->config->data->{source_from}, "Foo", "Bar", "Mite.pm");
    is $project->_project_shim_file, $shim;

    $project->add_mite_shim;

    ok -e $shim;

    require $shim->absolute;
    isa_ok("Foo::Bar::Mite", "Mite::Shim");

    chdir $Orig_Cwd;
};

done_testing;
