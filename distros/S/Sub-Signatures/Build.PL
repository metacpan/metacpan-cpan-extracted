#!/usr/bin/perl -w

use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Sub::Signatures',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <moc.oohay@eop_divo_sitruc>',
    dist_version_from => 'lib/Sub/Signatures.pm',
    requires          => {

        # No, I don't really require Sub::Uplevel, but I'm tired of my
        # tests failing because of this.
        'Sub::Uplevel'   => 0.09,
        'Filter::Simple' => 0.78,
    },
    build_requires => {
        'Test::Exception' => 0.21,
        'Test::More'      => 0.6,
    },
    add_to_cleanup     => ['Sub-Signatures-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
