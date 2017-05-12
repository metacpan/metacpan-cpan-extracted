# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4
# Net::BaruwaAPI Perl bindings for the Baruwa REST API
# Copyright (C) 2015 Andrew Colin Kissa <andrew@topdog.za.net>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::BaruwaAPI',
    license             => 'open_source',
    dist_author         => q{Andrew Colin Kissa <andrew@topdog.za.net>},
    dist_version_from   => 'lib/Net/BaruwaAPI.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Types::Standard'       => 0,
        'Moo'                   => 0,
        'Types::Standard'       => 0,
        'JSON::MaybeXS'         => 0,
        'LWP::UserAgent'        => 0,
        'HTTP::Request'         => 0,
        'LWP::Protocol::https'  => 0,
    },
    add_to_cleanup     => [ 'Net-BaruwaAPI-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
