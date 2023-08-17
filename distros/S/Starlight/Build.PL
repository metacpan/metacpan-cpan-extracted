#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use lib 'inc';
use Module::Build::My;

use Module::CPANfile;

my $module = 'Starlight';

(my $dist = $module) =~ s/::/-/g;

my $prereqs = Module::CPANfile->load->prereqs;

my $build = Module::Build::My->new(
    module_name        => $module,
    dist_version_from  => 'script/starlight.pl',
    license            => 'perl',
    configure_requires => $prereqs->requirements_for('configure', 'requires')->as_string_hash,
    build_requires     => $prereqs->requirements_for('build', 'requires')->as_string_hash,
    requires           => $prereqs->requirements_for('runtime', 'requires')->as_string_hash,
    recommends         => $prereqs->requirements_for('runtime', 'recommends')->as_string_hash,
    test_requires      => $prereqs->requirements_for('test', 'requires')->as_string_hash,
    script_files       => [
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
    meta_merge => {
        resources => {
            bugtracker => "http://github.com/dex4er/$dist/issues",
            repository => "http://github.com/dex4er/$dist",
        },
    },
);

$build->create_build_script;
