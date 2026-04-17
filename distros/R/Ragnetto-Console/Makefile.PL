use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Ragnetto::Console',
    AUTHOR           => 'Gabriele Secci <ragnettosoftware@gmail.com>',
    VERSION_FROM     => 'lib/Ragnetto/Console.pm',
    ABSTRACT_FROM    => 'lib/Ragnetto/Console.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        'strict'   => 0,
        'warnings' => 0,
        'utf8'     => 0,
        'IO::Handle' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Ragnetto-Console-*' },
);
