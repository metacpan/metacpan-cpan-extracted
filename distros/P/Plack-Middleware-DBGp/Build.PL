#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Plack::Middleware::DBGp',
    license     => 'perl',
    requires    => {
        'perl'                  => '5.10.0',
        'Plack'                 => '1.0031',
        'Devel::Debug::DBGp'    => '0.18',
    },
    configure_requires => {
        'Module::Build' => 0.42,
    },
    test_requires => {
        'Test::DBGp'                => '0.07',
        'DBGp::Client'              => 0,
        'HTTP::CookieJar'           => 0,
    },
    meta_merge  => {
        resources   => {
            license     => [ 'http://dev.perl.org/licenses/' ],
#            homepage    => 'https://github.com/mbarbon/plack-middleware-dbgp',
            bugtracker  => 'https://github.com/mbarbon/plack-middleware-dbgp/issues',
            repository  => 'https://github.com/mbarbon/plack-middleware-dbgp.git',
        },
    },
);
$build->create_build_script;
