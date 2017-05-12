use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Slay::Makefile::Gress',
    AUTHOR              => 'Mark Nodine <mnodine@alum.mit.edu>',
    VERSION_FROM        => 'lib/Slay/Makefile/Gress.pm',
    ABSTRACT            => 'Use Slay::Makefile for software regression testing',
    EXE_FILES           => [],
    PL_FILES            => {},
    PREREQ_PM => {
	'Slay::Makefile' => 0.04,
	'File::Path'    => 0,
	'File::Copy::Recursive' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Slay-Makefile-*' },
);
