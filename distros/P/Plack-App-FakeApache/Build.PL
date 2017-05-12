#!/usr/bin/perl
# $Id:$

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Plack::App::FakeApache',

    requires    => {
        'Plack'      => 0,
        'APR::Pool'  => 0,
        'APR::Table' => 0,
        'CGI::Emulate::PSGI' => 0,
        'Try::Tiny' => 0,
    },

    meta_merge => {
        resources => {
            repository => 'http://github.com/pmakholm/plack-app-wrapapachereq/tree/master',
        }
    },
);

$build->create_build_script;

