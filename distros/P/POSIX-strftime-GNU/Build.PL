#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use lib 'inc';
use Module::Build::My;
use ExtUtils::CBuilder;

use Config;

my $module = 'POSIX::strftime::GNU';

(my $dist = $module) =~ s/::/-/g;

my $build = Module::Build::My->new(
    module_name             => $module,
    license                 => 'perl',
    requires                => {
        'perl'                  => 5.006,
        'XSLoader'              => 0,
    },
    recommends              => {
    },
    build_requires          => {
        'ExtUtils::CBuilder'    => 0,
        'ExtUtils::CChecker'    => 0,
        'Test::More'            => 0,
    },
    get_options             => {
        pp                      => {},
        'pureperl-only'         => {},
    },
    pm_files                => {
        'lib/POSIX/strftime/GNU.pm' => 'lib/POSIX/strftime/GNU.pm',
        'lib/POSIX/strftime/GNU/PP.pm' => 'lib/POSIX/strftime/GNU/PP.pm',
    },
    xs_files                => {
    },
    include_dirs            => [
        'xs',
    ],
    auto_configure_requires => 0,
    create_makefile_pl      => 'small',
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

$build->log_info("Hint: run '$^X Build.PL --pp' if you don't want to compile XS module \n");

$build->args(pp => 1) if $build->args('pureperl-only') or not $build->cbuilder->have_compiler;

if (not $build->args('pp')) {
    print "POSIX::strftime::GNU configured with XS.\n";
    $build->xs_files({ %{$build->xs_files}, 'xs/strftime.xs' => 'lib/POSIX/strftime/GNU/XS.xs' });
    $build->pm_files({ %{$build->pm_files}, 'lib/POSIX/strftime/GNU/XS.pm' => 'lib/POSIX/strftime/GNU/XS.pm' });
}
else {
    print "POSIX::strftime::GNU configured with Pure Perl.\n";
};

$build->create_build_script;
