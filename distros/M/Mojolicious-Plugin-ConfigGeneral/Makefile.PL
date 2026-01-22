#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Mojolicious'           => 7.94,    # Ubuntu = libmojolicious-perl          RHEL = perl-Mojolicious
        'Config::General'       => 2.00,    # Ubuntu = libconfig-general-perl       RGEL = perl-Config-General
    };

WriteMakefile(
    'NAME'              => 'Mojolicious::Plugin::ConfigGeneral',
    'MIN_PERL_VERSION'  => 5.020,
    'VERSION_FROM'      => 'lib/Mojolicious/Plugin/ConfigGeneral.pm',
    'ABSTRACT_FROM'     => 'lib/Mojolicious/Plugin/ConfigGeneral.pm',
    'BUILD_REQUIRES'    => $build_requires,
    'PREREQ_PM'         => $prereq_pm,
    'AUTHOR'            => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'           => 'artistic_2',
    'META_MERGE'        => {
        'meta-spec' => {version => 2},
        prereqs     => {runtime => {requires => {perl => '5.020'}}},
        resources   => {
            homepage    => 'https://sourceforge.net/projects/mojolicious-plugin-cg/',
            license     => 'https://opensource.org/license/artistic-2-0',
            repository      => {
                    type => 'git',
                    url  => 'https://abalama@git.code.sf.net/p/mojolicious-plugin-cg/code',
                    web  => 'https://sourceforge.net/p/mojolicious-plugin-cg/code/ci/master/tree/',
                  },
        },
    },
);

1;
