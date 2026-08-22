use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Physics::Lithography',
    VERSION_FROM => 'lib/Physics/Lithography.pm',
    ABSTRACT     => 'Laser Direct Imprint Lithography simulation toolkit',
    AUTHOR       => 'Jovan Trujillo',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Carp'       => 0,
        'List::Util' => 0,
        'File::Path' => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/jtrujil43/Physics-Lithography',
        },
    },
);
