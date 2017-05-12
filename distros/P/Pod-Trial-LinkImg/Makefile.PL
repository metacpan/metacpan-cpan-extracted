use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Pod::Trial::LinkImg',
    AUTHOR              => 'Otto Hirr <otto.hirr@olabinc.com>',
    VERSION_FROM        => 'lib/Pod/Trial/LinkImg.pm',
    ABSTRACT_FROM       => 'lib/Pod/Trial/LinkImg.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Pod-Trial-LinkImg-*' },
);
