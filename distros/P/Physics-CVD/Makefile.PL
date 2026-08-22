use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Physics::CVD',
    VERSION_FROM => 'lib/Physics/CVD.pm',
    ABSTRACT     => 'Chemical Vapor Deposition simulation framework',
    AUTHOR       => 'Jovan Trujillo',
    LICENSE      => 'perl_5',
    PREREQ_PM    => {
        'Carp'       => 0,
        'List::Util' => 0,
        'File::Path' => 0,
        'POSIX'      => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jtrujil43/Physics-CVD.git',
                web  => 'https://github.com/jtrujil43/Physics-CVD',
            },
        },
    },
    MIN_PERL_VERSION => '5.016',
);
