use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Physics::PVD',
    VERSION_FROM     => 'lib/Physics/PVD.pm',
    ABSTRACT         => 'Physical Vapor Deposition simulation framework',
    AUTHOR           => 'Physics::PVD Contributors',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.016',
    PREREQ_PM        => {
        'Carp'       => 0,
        'List::Util' => 1.33,
        'POSIX'      => 0,
        'File::Path' => 0,
        'File::Spec' => 0,
        'File::Temp' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0.96,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/your-org/Physics-PVD.git',
            },
        },
        recommends => {
            'PDL'                   => '2.080',
            'PDL::Graphics::Gnuplot' => 0,
        },
    },
);
