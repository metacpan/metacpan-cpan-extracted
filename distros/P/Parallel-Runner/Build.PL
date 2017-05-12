#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Parallel::Runner',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Time::HiRes' => 0,
        'POSIX'       => 0,
        'Child'       => '0.009'
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Exception::LessClever' => 0,
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Parallel-Runner',
            bugtracker  => 'http://github.com/exodist/Parallel-Runner/issues',
            homepage    => 'http://open-exodus.net/projects/parrallel-runner'
        },
    }
);

$build->create_build_script;
