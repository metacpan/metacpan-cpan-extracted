use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Slay::Makefile',
    AUTHOR              => 'Mark Nodine <mnodine@alum.mit.edu>',
    VERSION_FROM        => 'lib/Slay/Makefile.pm',
    ABSTRACT            => 'Wrapper to Slay::Maker that reads the rules from a file',
    EXE_FILES           => [qw(slaymake)],
    PL_FILES            => {},
    PREREQ_PM => {
	'Slay::Maker' => 0.04,
	'File::Path'  => 0,
	'File::Copy::Recursive' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Slay-Makefile-*' },
);
