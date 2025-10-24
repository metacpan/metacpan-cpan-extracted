use ExtUtils::MakeMaker;
 

WriteMakefile(
    NAME             => 'Object::Meta',
    LICENSE          => 'perl',
    AUTHOR           => 'Bodo (Hugo) Barwich <b.barwich@hotmail.com>',
    VERSION_FROM     => 'lib/Object/Meta.pm',
    MIN_PERL_VERSION => '5.010',
    test             => {TESTS => 't/*.t'},
    BUILD_REQUIRES   => {
        'ExtUtils::MakeMaker' => '6.46',
    },
    META_MERGE          => {
        'meta-spec' => { version => 2 },
        resources       => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bodo-hugo-barwich/object-meta.git',
                web  => 'https://github.com/bodo-hugo-barwich/object-meta',
            },
            bugtracker => {
                web => 'https://github.com/bodo-hugo-barwich/object-meta/issues'
            },
        },
    },
);

