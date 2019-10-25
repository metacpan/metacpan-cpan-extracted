#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Mojo::HTTPStatus',

    dist_author => 'Tudor Marghidanu',
    dist_abstract => 'Readable HTTP status codes',

    meta_merge => {
        resources => {
            repository => 'https://gitlab.com/marghidanu/mojo-httpstatus.git',
        },

        x_contributors => [
            'Tudor Marghidanu <tudor@marghidanu.com>',
        ],
    },

    license => 'artistic_2',

    requires => {
        'Mojolicious' => '8.25',
        'Package::Constants' => '0.06',
        'Test::More' => undef,
    },
);

$builder->create_build_script();