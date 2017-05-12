#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use Module::Build;

my $module = 'Plack::Middleware::TrafficLog';

(my $dist = $module) =~ s/::/-/g;

my $build = Module::Build->new(
    module_name             => $module,
    license                 => 'perl',
    requires                => {
        'perl'                      => 5.008,
        'Plack'                     => 0,
        'POSIX::strftime::Compiler' => 0,
    },
    build_requires          => {
        'Test::More'                => 0,
    },
    auto_configure_requires => 0,
    create_makefile_pl      => 'traditional',
    create_readme           => 1,
    create_license          => 1,
    recursive_test_files    => 0,
    add_to_cleanup          => [
        '*.bak', '*.gz', '*.tgz', '*.ppd', '*.ppmx', '*.deb',
        'pm_to_blib', 'cover_db', 'Debian_CPANTS.txt',
        'compilet*', 'test-*',
        "$dist-*",
    ],
    meta_merge              => {
        resources               => {
            bugtracker => "http://github.com/dex4er/perl-$dist/issues",
            repository => "http://github.com/dex4er/perl-$dist",
        },
    },
);

$build->create_build_script;
