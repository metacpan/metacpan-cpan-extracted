use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Papery',
    AUTHOR              => 'Philippe Bruhat (BooK) <book@cpan.org>',
    VERSION_FROM        => 'lib/Papery.pm',
    ABSTRACT_FROM       => 'lib/Papery.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'http://github.com/book/Papery',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Papery-*' },
);
