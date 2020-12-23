use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'STEVEB::Dist::Mgr',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/STEVEB/Dist/Mgr.pm',
#    ABSTRACT_FROM    => 'lib/STEVEB/Dist/Mgr.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/steveb-dist-mgr/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/steveb-dist-mgr.git',
                web => 'https://github.com/stevieb9/steveb-dist-mgr',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Hook::Output::Tiny' => '1.00',
        'Test::More'         => '0',
    },
    PREREQ_PM => {
        'File::Find::Rule'  => 0,
        'PPI'               => 0,
        'Tie::File'         => 0,
        'version'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'STEVEB-Dist-Mgr-*' },
);
