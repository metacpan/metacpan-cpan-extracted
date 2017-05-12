#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use Module::Build;

my $module = 'Test::Assert';

(my $dist = $module) =~ s/::/-/g;

my $build = Module::Build->new(
    module_name => $module,
    license => 'perl',
    requires => {
        'perl'                    => 5.006,
        'constant::boolean'       => 0.02,
        'Exception::Base'         => 0.21,
        'Symbol::Util'            => 0.0202,
    },
    optional => {
    },
    build_requires => {
        'parent'                  => 0,
        'Class::Inspector'        => 0,
        'Test::Unit::Lite'        => 0.11,
    },
    auto_configure_requires => 0,
    create_makefile_pl => 'traditional',
    create_readme => 1,
    create_license => 1,
    sign => 1,
    recursive_test_files => 1,
    add_to_cleanup => [
        '*.bak', '*.gz', '*.tgz', '*.ppd', '*.ppmx', '*.deb', '*.bat',
        'Makefile', 'pm_to_blib', 'cover_db', 'xt/Debian_CPANTS.txt',
        "$dist-*",
    ],
    meta_merge => {
        resources => {
            bugtracker => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist",
            repository => "http://dexter-cpan.googlecode.com/svn/$dist",
        },
    },
);

$build->create_build_script;
