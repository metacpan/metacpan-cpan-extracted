use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Religion::Bible::Regex::Versification',
    AUTHOR              => 'Daniel Holmlund <holmlund.dev@gmail.com>',
    VERSION_FROM        => 'lib/Religion/Bible/Regex/Versification.pm',
    ABSTRACT_FROM       => 'lib/Religion/Bible/Regex/Versification.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Religion::Bible::Regex::Builder' => 0,
        'Religion::Bible::Regex::Config' => 0,
        'Religion::Bible::Regex::Reference' => 0,
        'Test::More' => 0,
        'Test::Deep' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Religion-Bible-Regex-Versification-*' },
);
