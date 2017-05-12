use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Object::Generic',
    AUTHOR              => 'Jim Mahoney <mahoney@marlboro.edu>',
    VERSION_FROM        => 'lib/Object/Generic.pm',
    ABSTRACT_FROM       => 'lib/Object/Generic.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Object-Generic-*' },
);
