use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Preproc::Tiny',
    VERSION_FROM     => 'lib/Preproc/Tiny.pm',
    MIN_PERL_VERSION => '5.010',
    EXE_FILES        => ['bin/pp'],

    TEST_REQUIRES => {
        'Test::More'        => 0,
        'Capture::Tiny'     => 0,
        'Path::Tiny'        => 0,
        'Test::Differences' => 0,
    },

    ABSTRACT_FROM => 'lib/Preproc/Tiny.pm',
    AUTHOR        => 'Paulo Custodio <pscust@cpan.org>',
    LICENSE       => 'perl',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },

    NO_MYMETA => 1,

    META_ADD => {
        'meta-spec' => { version => 2 },
        license     => ['Artistic-1.0-Perl'],
        resources   => {
            repository => {
                type => 'git',
                url  =>
                  'https://github.com/pauloscustodio/perl-Preproc-Tiny.git',
                web => 'https://github.com/pauloscustodio/perl-Preproc-Tiny',
            },
            bugtracker => {
                web =>
                  'https://github.com/pauloscustodio/perl-Preproc-Tiny/issues',
            },
        },
    },
);
