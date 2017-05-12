use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => "PerlIO::via::escape_ansi",
    LICENSE             => "perl",
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => "lib/PerlIO/via/escape_ansi.pm",
    ABSTRACT_FROM       => "lib/PerlIO/via/escape_ansi.pm",
    OBJECT              => 'escape_ansi$(OBJ_EXT) escape_chars$(OBJ_EXT)',
    PREREQ_PM => {
        # prereqs
        'PerlIO::via'   => 0,

        # build/test prereqs
        'Test::More'    => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => "gzip -9f", SUFFIX => "gz", },
    clean               => { FILES => "PerlIO-via-escape_ansi-*" },
);

