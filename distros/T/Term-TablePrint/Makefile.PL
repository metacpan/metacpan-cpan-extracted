use 5.008003;
use warnings;
use strict;
use ExtUtils::MakeMaker;

my %prereqs_os_specific;

if ( $^O eq 'MSWin32' ) {
    %prereqs_os_specific = (
        'Win32::Console::ANSI' => 0,
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
              web  => 'https://github.com/kuerbis/Term-TablePrint',
              url  => 'https://github.com/kuerbis/Term-TablePrint.git',
            },
        },
    },
    AUTHOR           => 'Matthaeus Kiem <cuer2s@gmail.com>',
    NAME             => 'Term::TablePrint',
    ABSTRACT_FROM    => 'lib/Term/TablePrint.pm',
    VERSION_FROM     => 'lib/Term/TablePrint.pm',
    EXE_FILES        => [],
    BUILD_REQUIRES   => {
        'Test::More'           => 0,
    },
    PREREQ_PM => {
        'constant'                => 0,
        'strict'                  => 0,
        'warnings'                => 0,
        'Carp'                    => 0,
        'Data::Dumper'            => 0,
        'Exporter'                => 0,
        'List::Util'              => 0,
        'Scalar::Util'            => 0,
        'Term::Choose'            => '1.654',
        'Term::Choose::Util'      => '0.074',
        %prereqs_os_specific,
    },
    dist  => {
        COMPRESS => 'gzip',
        SUFFIX   => '.gz',
        TARFLAGS => '--format=gnu -cvf',
    },
    clean => {
        FILES => 'Term-TablePrint-*',
    },
);
