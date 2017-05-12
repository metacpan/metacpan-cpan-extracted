use strict;
use warnings;
use 5.006002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Sort::External',
    AUTHOR        => 'Marvin Humphrey <marvin at rectangular dot com>',
    VERSION_FROM  => 'lib/Sort/External.pm',
    ABSTRACT_FROM => 'lib/Sort/External.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
        'File::Temp' => 0.14,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Sort-External-* MANIFEST.bak' },
    # CCFLAGS => ' -Wall -Wextra -pedantic -ansi -DPERL_GCC_PEDANTIC -std=c89 '
);
