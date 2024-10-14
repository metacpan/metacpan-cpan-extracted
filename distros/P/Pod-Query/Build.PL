#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

my $class = Module::Build->subclass(
    code => q{
        use Cwd qw( cwd );

        #---------------------------------
        #            Build
        #---------------------------------

        sub ACTION_build {
            my ($s) = @_;
            $s->_readme();
            $s->SUPER::ACTION_build;
        }

        # Only for the maintainer on "Build build".
        sub _readme {
            my ($s) = @_;
            return if cwd() !~ m{ / git / perlmy / [^/]+ $ }x;

            my ($installed) =
                grep { -x "$_/pod2markdown" }
                split /:/, $ENV{PATH};
            return if !$installed;

            print "Building README\n";
            my $lib = $s->{properties}{dist_version_from};
            system "pod2markdown $lib > README.md";
        }

    },
);

my $builder = $class->new(
    module_name        => 'Pod::Query',
    license            => 'artistic_2',
    dist_author        => q{Tim Potapov <tim.potapov[AT]gmail.com>},
    dist_version_from  => 'lib/Pod/Query.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl'            => '5.018',
        'Pod::LOL'        => '0.08',
        'Term::Size::Any' => '0.002',
        'Role::Tiny'      => '2.002004',
    },
    add_to_cleanup => ['Pod-Query-*'],
    meta_merge     => {
        resources => {
            bugtracker => 'https://github.com/poti1/pod-query/issues',
            repository => 'https://github.com/poti1/pod-query',
        },
    },
);

$builder->create_build_script();
