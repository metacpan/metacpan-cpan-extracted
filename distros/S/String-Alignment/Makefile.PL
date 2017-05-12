use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Alignment',
    AUTHOR              => 'Cheng-Lung Sung <clsung@cpan.org>',
    VERSION_FROM        => 'lib/String/Alignment.pm',
    ABSTRACT_FROM       => 'lib/String/Alignment.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'List::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Alignment-*' },
);
