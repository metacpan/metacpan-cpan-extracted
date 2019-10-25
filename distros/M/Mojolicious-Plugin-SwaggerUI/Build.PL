#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Mojolicious::Plugin::SwaggerUI',

    dist_author => 'Tudor Marghidanu',
    dist_abstract => 'Swagger UI plugin for Mojolicious',

    meta_merge => {
        resources => {
            repository => 'https://gitlab.com/marghidanu/mojolicious-plugin-swaggerui.git',
        },

        x_contributors => [
            'Tudor Marghidanu <tudor@marghidanu.com>',
        ],
    },

    license => 'artistic_2',

    share_dir => 'share',

    requires => {
        'Mojolicious' => '8.25',
    },
);

$builder->create_build_script();