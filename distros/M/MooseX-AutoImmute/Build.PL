#!/usr/bin/perl
use 5.008;
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'MooseX::AutoImmute',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Moose' => 0,
        'Hook::AfterRuntime' => '0.003',
        'Fennec' => '0.029',
    },
    build_requires => {
        'Test::More'      => 0.88,
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/exodist/MooseX-AutoImmute',
            bugtracker => 'http://github.com/exodist/MooseX-AutoImmute/issues',
            homepage   => 'http://open-exodus.net/projects/MooseX-AutoImmute'
        },
    }
);

$build->create_build_script;
