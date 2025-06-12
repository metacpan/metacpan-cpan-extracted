use 5.10.1;
use warnings;
use strict;
use ExtUtils::MakeMaker;


my %prereqs_os_specific;

if ( $^O eq 'MSWin32' ) {
    %prereqs_os_specific = (
        'Encode'                          => 0,
        'Encode::Locale'                  => 0,
        'Win32::Console'                  => 0,
        'Win32::Console::ANSI'            => 0,
        'Win32::Console::PatchForRT33513' => 0,
    );
}


my $has_xs = eval { require Term::Choose::LineFold::XS };
my %prereqs_xs;
if ( $has_xs ) {
    %prereqs_xs = ( 'Term::Choose::LineFold::XS' => '0.001', );
}


WriteMakefile(
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.10.1',
    LICENSE          => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => "https://github.com/kuerbis/Term-Choose/issues",
            },
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
        'open'                  => 0,
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
        %prereqs_xs,
    },
    test  => {
        TESTS => 't/*/*.t',
    },
    dist  => {
        COMPRESS => 'gzip',
        SUFFIX   => '.gz',
        TARFLAGS => '--format=gnu -cvf',
    },
);
