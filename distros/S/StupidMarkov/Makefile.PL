use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'StupidMarkov',
    AUTHOR              => 'June R. Tate-Gans <june@theonelab.com>',
    VERSION_FROM        => 'lib/StupidMarkov.pm',
    ABSTRACT_FROM       => 'lib/StupidMarkov.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/stupidmarkov-dissociator.pl' ],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'StupidMarkov-*' },
);
