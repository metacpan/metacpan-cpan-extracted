#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Plack::Middleware::Camelcadedb',
    license     => 'perl',
    requires    => {
        'perl'                  => '5.10.0',
        'Plack'                 => '1.0031',
        'Devel::Camelcadedb'    => '0.18',
    },
    configure_requires => {
        'Module::Build' => 0.42,
    },
    meta_merge  => {
        resources   => {
            license     => [ 'http://dev.perl.org/licenses/' ],
#            homepage    => 'https://github.com/mbarbon/plack-middleware-camelcadedb',
            bugtracker  => 'https://github.com/mbarbon/plack-middleware-camelcadedb/issues',
            repository  => 'https://github.com/mbarbon/plack-middleware-camelcadedb.git',
        },
    },
);
$build->create_build_script;
