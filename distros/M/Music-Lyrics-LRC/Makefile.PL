use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME             => 'Music::Lyrics::LRC',
    AUTHOR           => q{Tom Ryder <tom@sanctum.geek.nz>},
    VERSION_FROM     => 'lib/Music/Lyrics/LRC.pm',
    ABSTRACT_FROM    => 'lib/Music/Lyrics/LRC.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'English'    => '0',
        'File::Temp' => '0',
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Carp'        => 0,
        'English'     => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides => {
            'Music::Lyrics::LRC' => {
                version => '0.17',
                file => 'lib/Music/Lyrics/LRC.pm',
            },
        },
        resources => {
            homepage => 'https://dev.sanctum.geek.nz/cgit/Music-Lyrics-LRC.git/',
            repository => {
                type => 'git',
                url => 'https://sanctum.geek.nz/code/Music-Lyrics-LRC.git/',
                web => 'https://dev.sanctum.geek.nz/cgit/Music-Lyrics-LRC.git/',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Music-Lyrics-LRC-*' },
);
