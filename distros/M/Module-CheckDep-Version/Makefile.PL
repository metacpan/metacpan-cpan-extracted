use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Module::CheckDep::Version',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Module/CheckDep/Version.pm',
    ABSTRACT_FROM    => 'lib/Module/CheckDep/Version.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    EXE_FILES        => [qw(bin/checkdep)],
    MIN_PERL_VERSION => '5.006',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/module-checkdep-version/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/module-checkdep-version.git',
                web => 'https://github.com/stevieb9/module-checkdep-version',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Hook::Output::Tiny' => '0.05',
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'MetaCPAN::Client'  => '2.010700',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Module-CheckDep-Version-*' },
);
