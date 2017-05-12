use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MobilePhone',
    AUTHOR              => 'Ali Craigmile <ali@hodgers.com>',
    VERSION_FROM        => 'lib/MobilePhone.pm',
    ABSTRACT_FROM       => 'lib/MobilePhone.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MobilePhone-*' },
);
