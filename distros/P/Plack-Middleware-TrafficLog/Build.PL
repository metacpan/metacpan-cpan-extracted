#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use Module::Build;
use Module::CPANfile;

my $module = 'Plack::Middleware::TrafficLog';

(my $dist = $module) =~ s/::/-/g;

my $prereqs = Module::CPANfile->load->prereqs;

my $build = Module::Build->new(
    module_name             => $module,
    license                 => 'perl',
    build_requires          => $prereqs->requirements_for('build', 'requires')->as_string_hash,
    configure_requires      => $prereqs->requirements_for('configure', 'requires')->as_string_hash,
    requires                => $prereqs->requirements_for('runtime', 'requires')->as_string_hash,
    recommends              => $prereqs->requirements_for('runtime', 'recommends')->as_string_hash,
    test_requires           => $prereqs->requirements_for('test', 'requires')->as_string_hash,
    auto_configure_requires => 0,
    create_makefile_pl      => 'traditional',
    create_readme           => 1,
    create_license          => 1,
    recursive_test_files    => 0,
    add_to_cleanup          => [
        '*.bak', '*.gz', '*.tgz', '*.ppd', '*.ppmx', '*.deb', '*.bat',
        'Makefile', 'pm_to_blib', 'cover_db', 'Debian_CPANTS.txt',
        "$dist-*",
    ],
    meta_merge => {
        resources => {
            bugtracker => "http://github.com/dex4er/perl-$dist/issues",
            repository => "http://github.com/dex4er/perl-$dist",
        },
    },
);

$build->create_build_script;
