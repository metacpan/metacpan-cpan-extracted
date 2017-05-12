#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Mock::Quick',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'Carp'              => 0,
        'Scalar::Util'      => 0,
        'Exporter::Declare' => '0.103',
    },
    build_requires => {
        'Test::Simple'    => 0.88,
        'Test::Exception' => 0.29,
        'Fennec::Lite'    => '0.004',
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/exodist/Mock-Quick',
            bugtracker  => 'http://github.com/exodist/Mock-Quick/issues',
        },
    }
);

$build->create_build_script;
