use 5.008003;
use warnings;
use strict;
use ExtUtils::MakeMaker;


my %prereqs_os_specific;
if ( $^O eq 'MSWin32' ) {
    %prereqs_os_specific = (
        'Win32::Console'       => 0,
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
              web  => 'https://github.com/kuerbis/Term-Choose-Util',
              url  => 'https://github.com/kuerbis/Term-Choose-Util',
            },
        },
    },
    AUTHOR           => 'Matthaeus Kiem <cuer2s@gmail.com>',
    NAME             => 'Term::Choose::Util',
    VERSION_FROM     => 'lib/Term/Choose/Util.pm',
    EXE_FILES        => [],
    BUILD_REQUIRES   => {
        'Test::More'            => 0,
    },
    PREREQ_PM => {
        'constant'               => 0,
        'strict'                 => 0,
        'warnings'               => 0,
        'Encode'                 => 0,
        'Encode::Locale'         => 0,
        'Exporter'               => 0,
        'File::Basename'         => 0,
        'File::HomeDir'          => 0,
        'File::Spec::Functions'  => 0,
        'List::Util'             => 0,
        'Term::Choose'           => '1.500',
        'Term::Choose::LineFold' => '1.500',
        'Term::ReadKey'          => 0,
        %prereqs_os_specific,
    },
    dist  => {
        COMPRESS => 'gzip',
        SUFFIX   => '.gz',
        TARFLAGS => '--format=gnu -cvf',
    },
    clean => {
        FILES => 'Term-Choose-Util-*',
    },
);
