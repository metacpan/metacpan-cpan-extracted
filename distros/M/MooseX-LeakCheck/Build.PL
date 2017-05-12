#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'MooseX::LeakCheck',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Scalar::Util' => 0,
        'Moose'        => 0,
    },
    build_requires => {
        'Test::More' => '0.71',
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/MooseX-LeakCheck',
            bugtracker  => 'http://github.com/exodist/MooseX-LeakCheck/issues',
        },
    }
);

$build->create_build_script;
