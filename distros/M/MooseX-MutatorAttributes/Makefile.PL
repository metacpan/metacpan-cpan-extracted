use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MooseX::MutatorAttributes',
    AUTHOR              => 'ben hengst <notbenh@cpan.org>',
    VERSION_FROM        => 'lib/MooseX/MutatorAttributes.pm',
    ABSTRACT_FROM       => 'lib/MooseX/MutatorAttributes.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp::Assert::More' => 0,
        'Moose' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MooseX-MutatorAttributes-*' },
);
