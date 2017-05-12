use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Multilingual',
    AUTHOR              => 'Eric Cholet <cholet@logilune.com>',
    VERSION_FROM        => 'lib/Template/Multilingual.pm',
    ABSTRACT_FROM       => 'lib/Template/Multilingual.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Template'   => 2,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Multilingual-*' },
);
