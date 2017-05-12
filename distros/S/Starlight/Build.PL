#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use lib 'inc';
use Module::Build::My;

use Config;

my $module = 'Starlight';

(my $dist = $module) =~ s/::/-/g;

my $build = Module::Build::My->new(
    module_name             => $module,
    dist_version_from       => 'script/starlight.pl',
    license                 => 'perl',
    requires                => {
        'perl'                  => 5.008_001,
        'Plack'                 => 0.9920,
    },
    recommends              => {
        $^O eq 'cygwin' ? ('Win32::Process' => 0) : (),
    },
    suggests                => {
        'IO::Socket::IO'        => 0,
        'IO::Socket::SSL'       => 0,
        'Net::SSLeay'           => '1.49',
    },
    build_requires          => {
        'HTTP::Tiny'            => 0,
        'Test::More'            => 0.88,
        'Test::TCP'             => 0.15,
    },
    script_files => [
        'script/starlight.pl',
    ],
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
            bugtracker => "http://github.com/dex4er/$dist/issues",
            repository => "http://github.com/dex4er/$dist",
        },
    },
);

$build->create_build_script;
