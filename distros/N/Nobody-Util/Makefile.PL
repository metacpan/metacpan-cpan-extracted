use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Nobody-Util',
    AUTHOR           => 'Rich Paul <rpaul@cpan.org>',
    VERSION_FROM     => 'Nobody/Util.pm',
    ABSTRACT         => 'Utility modules used by Nobody (but useful to everybody)',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.020',
    PREREQ_PM => {
        'common::sense' => 0,
        'JSON::XS'      => 0,
        'Scalar::Util'  => 0,
        'List::Util'    => 1.45,
        'POSIX'         => 0,
        'Carp'          => 0,
        'Path::Tiny'    => 0,
        'Sub::Util'     => 0,
        'URI'           => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/nobody-does-ai/nobody.git',
                web  => 'https://gitlab.com/nobody-does-ai/nobody',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'Nobody-*' },
);
