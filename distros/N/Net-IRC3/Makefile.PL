use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::IRC3',
    AUTHOR              => 'Robin Redeker <elmex@ta-sa.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/Net/IRC3.pm',
    ABSTRACT_FROM       => 'lib/Net/IRC3.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'AnyEvent'   => 0,
    },
    dist                => {
       COMPRESS => 'gzip -9f',
       SUFFIX => 'gz',
       PREOP => 'pod2text lib/Net/IRC3.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
    },
    clean               => { FILES => 'Net-IRC3-*' },
);
