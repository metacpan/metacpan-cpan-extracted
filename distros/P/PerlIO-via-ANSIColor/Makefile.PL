require 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PerlIO::via::ANSIColor',
    AUTHOR              => 'Masanori Hara <massa.hara at gmail.com>',
    VERSION_FROM        => 'lib/PerlIO/via/ANSIColor.pm',
    ABSTRACT_FROM       => 'lib/PerlIO/via/ANSIColor.pm',
    PL_FILES            => {},
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More'      => 0,
        'Term::ANSIColor' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PerlIO-via-ANSIColor-*' },
);
