use 5.008003;
use warnings;
use strict;
use ExtUtils::MakeMaker;


my %prereqs_os_specific;

if ( $^O eq 'MSWin32' ) {
    %prereqs_os_specific = (
        'Encode'                          => 0,
        'Encode::Locale'                  => 0,
        'Win32::Console'                  => 0,
        'Win32::Console::PatchForRT33513' => 0,
    );
}

WriteMakefile(
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008003',
    LICENSE          => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
              type => 'git',
              web  => 'https://github.com/kuerbis/Term-Choose',
              url  => 'https://github.com/kuerbis/Term-Choose.git',
            },
        },
    },
    AUTHOR           => 'Matthaeus Kiem <cuer2s@gmail.com>',
    NAME             => 'Term::Choose',
    ABSTRACT_FROM    => 'lib/Term/Choose.pm',
    VERSION_FROM     => 'lib/Term/Choose.pm',
    EXE_FILES        => [],
    BUILD_REQUIRES   => {
        'lib'                   => 0,
        'File::Spec::Functions' => 0,
        'FindBin'               => 0,
        'Test::More'            => 0,
        'Test::Fatal'           => 0,
    },
    PREREQ_PM => {
        'constant'          => 0,
        'strict'            => 0,
        'warnings'          => 0,
        'Carp'              => 0,
        'Exporter'          => 0,
        %prereqs_os_specific,
    },
    test  => {
        TESTS => 't/*/*.t',
    },
    dist  => {
        COMPRESS => 'gzip',
        SUFFIX   => '.gz',
        TARFLAGS => '--format=gnu -cvf',
    },
    clean => {
        FILES => 'Term-Choose-*',
    },
);
