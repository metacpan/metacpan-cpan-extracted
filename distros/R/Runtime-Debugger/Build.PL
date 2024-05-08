#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

my $class = Module::Build->subclass(
    code => q{
        use ExtUtils::MakeMaker;
        sub ACTION_installdeps {
            my ($s) = @_;
            print "Checking if our version of ExtUtils::MakeMaker is ok\n";
            my $minimum = "7.6502";
            my $version = ExtUtils::MakeMaker->VERSION;
            print "Need ExtUtils::MakeMaker $minimum (have $version)\n";
            if ( $version < $minimum ) {
                print "Fetching version $minimum from repo\n";
                system "cpanm https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/archive/refs/tags/v7.65_02.tar.gz";
            }
            $s->SUPER::ACTION_installdeps;
        }
        sub ACTION_readme {
            my ($s) = @_;
            print "Building README\n";
            system "pod2markdown lib/Runtime/Debugger.pm > README.md";
        }
    },
);
$class->ACTION_readme();

my $builder = $class->new(
    module_name        => 'Runtime::Debugger',
    license            => 'artistic_2',
    dist_author        => q{Tim Potapov <tim.potapov[AT]gmail.com>},
    dist_version_from  => 'lib/Runtime/Debugger.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl'                => '5.018',
        'Term::ReadLine::Gnu' => '1.44',
        'PadWalker'           => '2.5',
        'Class::Tiny'         => '1.008',
        'Data::Printer'       => '1.002001',
    },
    add_to_cleanup => [
        'Runtime-Debugger-*',
        'build_dir/',
        'MANIFEST*.bak',
        'README*',
        'blib/',
    ],
    meta_merge     => {
        resources => {
            bugtracker => 'https://github.com/poti1/runtime-debugger/issues',
            repository => 'https://github.com/poti1/runtime-debugger',
        },
    },
);

$builder->create_build_script();
