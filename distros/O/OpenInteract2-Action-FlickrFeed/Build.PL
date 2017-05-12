#!/usr/bin/perl -w

use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'OpenInteract2::Action::FlickrFeed',
    license           => 'perl',
    dist_author       => 'Chris Winters <chris@cwinters.com>',
    dist_version_from => 'lib/OpenInteract2/Action/FlickrFeed.pm',
    requires          => {
         'OpenInteract2::Action::RSS' => '0.10',
    },
    build_requires => {
        'Test::More'      => 0.4,
    },
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
