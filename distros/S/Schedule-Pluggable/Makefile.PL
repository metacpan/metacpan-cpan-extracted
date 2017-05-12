use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Schedule::Pluggable',
    AUTHOR              => 'Tony Edwardson <tony@edwardson.co.uk>',
    VERSION_FROM        => 'lib/Schedule/Pluggable.pm',
    ABSTRACT_FROM       => 'lib/Schedule/Pluggable.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Moose' => 0,
        'MooseX::Workers' => 0,
        'MooseX::Object::Pluggable' => 0,
        'Test::More' => 0,
        'XML::Simple' => 0,
        'Template' => 0,
        'Try::Tiny' => 0,
        'version'    => 0,
    },
    TEST_REQUIRES => {
        'Test::Pod::Coverage' => 1.04,
        'Test::Pod' => 1.14,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Schedule--Pluggable-*' },
);
