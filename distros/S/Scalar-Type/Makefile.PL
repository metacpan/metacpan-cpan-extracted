use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Scalar::Type',
    META_MERGE => {
        license => 'open_source',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Scalar-Type',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Scalar-Type/issues'
        },
    },
    VERSION_FROM => 'lib/Scalar/Type.pm',
    OBJECT => 'Type$(OBJ_EXT)',
    PREREQ_PM => {
        'Scalar::Util'    => 0,
        'Test::Exception' => 0,
        'Test::More'      => 0.96,
        'Devel::Peek'     => 0,
        'Capture::Tiny'   => 0,
        'Carp'            => 0,
        'if'              => 0,
    },
);
