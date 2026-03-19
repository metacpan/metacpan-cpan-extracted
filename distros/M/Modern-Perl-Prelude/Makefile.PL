use v5.30;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Modern::Perl::Prelude',
    VERSION_FROM      => 'lib/Modern/Perl/Prelude.pm',
    ABSTRACT_FROM     => 'lib/Modern/Perl/Prelude.pm',
    AUTHOR            => 'Sergey Kovalev <skov@cpan.org>',
    LICENSE           => 'perl',
    MIN_PERL_VERSION  => '5.30.0',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },

    PREREQ_PM => {
        'Import::Into'         => 0,
        'Feature::Compat::Try' => 0,
        'builtin::compat'      => 0,
    },

    TEST_REQUIRES => {
        'Test::More'             => 0,
        'Feature::Compat::Class' => 0,
        'Feature::Compat::Defer' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                type => 'git',
                url  => 'git@github.com:neo1ite/Modern-Perl-Prelude.git',
                web  => 'https://github.com/neo1ite/Modern-Perl-Prelude',
            },
            bugtracker => {
                web => 'https://github.com/neo1ite/Modern-Perl-Prelude/issues',
            },
        },
    },
);
