use 5.012;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'MooseX::Types::StrictScalarTypes',
    META_MERGE => {
        license => 'open_source',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-MooseX-Types-StrictScalarTypes',
            bugtracker => 'https://github.com/DrHyde/perl-modules-MooseX-Types-StrictScalarTypes/issues'
        },
    },
    VERSION_FROM => 'lib/MooseX/Types/StrictScalarTypes.pm',
    PREREQ_PM => {
        'Scalar::Type'         => v1.0.1,
        'Test2::V0'            => 0.000159,
        'Moose'                => 1.06,
        'MooseX::Types'        => 0.50,
        'MooseX::Types::Moose' => 0.50,
    },
);
