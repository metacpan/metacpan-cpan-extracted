#!/usr/bin/perl -w

use 5.008_008;

use strict;
use lib 'inc';

use MyBuilder;

my $builder = MyBuilder->new(
    module_name => 'Object::ID',
    license     => 'perl',
    dist_author => 'Michael G Schwern <schwern@pobox.com>',

    no_index => {
        package => [
            "UNIVERSAL"
        ],
    },

    meta_merge  => {
        resources => {
            repository =>
              'http://github.com/schwern/Object-ID',
        },

        keywords => [ 'id', 'identifier', 'universal', 'object' ],

        configure_requires => {
            'Module::Build'     => '0.340201'     # what shipped with 5.10.1
        },
    },

    build_requires      => {
        'Test::More'        => '0.88',    # for done_testing
        version             => '0.77',
    },

    requires             => {
        perl                    => '5.8.8',
        "Sub::Name"             => '0.03',
        'Hash::FieldHash'       => '0.10',
    },

    auto_features => {
        object_uuid     => {
            description => "Unique object idenifier using UUIDs",
            requires    => {
                "Data::UUID" => 1.148
            }
        }
    },

    create_license      => 1,
    create_readme       => 1,
);

$builder->create_build_script();
