use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RF::HC12',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RF/HC12.pm',
    ABSTRACT_FROM    => 'lib/RF/HC12.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rf-hc12/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rf-hc12.git',
                web => 'https://github.com/stevieb9/rf-hc12',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'RPi::Serial'       => 2.99,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RF-HC12-*' },
);
