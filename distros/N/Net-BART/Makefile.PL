use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::BART',
    DISTNAME         => 'Net-BART',
    VERSION_FROM     => 'lib/Net/BART.pm',
    ABSTRACT_FROM    => 'lib/Net/BART.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',

    XSMULTI          => 1,
    OPTIMIZE         => '-O2',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.12',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0.96',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.96',
    },
    PREREQ_PM => {},

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/gaissmai/Net-BART.git',
                web  => 'https://github.com/gaissmai/Net-BART',
            },
            bugtracker => {
                web => 'https://github.com/gaissmai/Net-BART/issues',
            },
        },
        provides => {
            'Net::BART' => {
                file    => 'lib/Net/BART.pm',
                version => '0.01',
            },
            'Net::BART::XS' => {
                file    => 'lib/Net/BART/XS.pm',
                version => '0.01',
            },
            'Net::BART::Art' => {
                file    => 'lib/Net/BART/Art.pm',
                version => '0.01',
            },
            'Net::BART::BitSet256' => {
                file    => 'lib/Net/BART/BitSet256.pm',
                version => '0.01',
            },
            'Net::BART::LPM' => {
                file    => 'lib/Net/BART/LPM.pm',
                version => '0.01',
            },
            'Net::BART::Node' => {
                file    => 'lib/Net/BART/Node.pm',
                version => '0.01',
            },
            'Net::BART::SparseArray256' => {
                file    => 'lib/Net/BART/SparseArray256.pm',
                version => '0.01',
            },
        },
        no_index => {
            directory => [qw(t gobench)],
        },
    },

    clean => { FILES => 'lib/Net/BART/XS.c lib/Net/BART/XS.o lib/Net/BART/XS.bs' },
);
