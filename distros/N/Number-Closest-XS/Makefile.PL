use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME                => 'Number::Closest::XS',
    AUTHOR              => q{Pavel Shaydo <zwon@cpan.org>},
    VERSION_FROM        => 'lib/Number/Closest/XS.pm',
    ABSTRACT_FROM       => 'lib/Number/Closest/XS.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
    },
    TEST_REQUIRES => {
        'Test::More' => 0.94,
        'Test::Most' => 0.22,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.64,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Number-Closest-XS-*' },
    META_MERGE => {
        no_index => {
            file => 'README.pod'
        },
        resources => {

            homepage   => 'https://github.com/trinitum/perl-Number-Closest-XS',
            bugtracker => 'https://github.com/trinitum/perl-Number-Closest-XS/issues',
            repository => 'git://github.com/trinitum/perl-Number-Closest-XS',

            license    => 'http://dev.perl.org/licenses/',
        },
    },
);
