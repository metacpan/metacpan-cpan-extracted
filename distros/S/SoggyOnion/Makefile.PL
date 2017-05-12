use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'SoggyOnion',
    VERSION_FROM  => 'lib/SoggyOnion.pm',
    ABSTRACT_FROM => 'lib/SoggyOnion.pm',
    AUTHOR        => 'Ian Langworth <ian@cpan.org>',
    INSTALLBIN    => 'bin',
    PL_FILES      => {
        'bin/soggyonion-install.PL' => 'bin/soggyonion-install',
        'bin/soggyonion.PL'         => 'bin/soggyonion'
    },
    EXE_FILES => [
        qw(
            bin/soggyonion-install
            bin/soggyonion
            )
    ],
    PREREQ_PM => {
        qw(
            Cache::FileCache            0
            File::Basename              0
            File::Find::Rule            0
            File::Path                  0
            Geo::Weather                0
            HTML::Entities              0
            HTML::Strip                 0
            HTML::TokeParser            0
            IO::All                     0
            IO::Scalar                  0
            LWP::Simple                 0
            Parallel::ForkManager       0
            Template                    0
            Test::More                  0
            XML::RSS                    0
            YAML                        0
            )
    },
    dist  => { 'PREOP' => 'pod2text lib/SoggyOnion.pm >README', },
    clean => {
        FILES =>
            'Color-Scheme-* bin/soggyonion-install bin/soggyonion .lwpcookies'
    },
);

