use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Syntax::Check',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Syntax/Check.pm',
    ABSTRACT_FROM    => 'lib/Syntax/Check.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    EXE_FILES        => [qw(bin/syncheck)],
    MIN_PERL_VERSION => '5.006',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/syntax-check/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/syntax-check.git',
                web => 'https://github.com/stevieb9/syntax-check',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Capture::Tiny' => 0,
        'Test::More'    => 0,
    },
    PREREQ_PM => {
        'Carp'                    => 0,
        'File::Path'              => 0,
        'File::Temp'              => 0,
        'PPI'                     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Syntax-Check-*' },
);
