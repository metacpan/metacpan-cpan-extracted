use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Object::Event',
    AUTHOR              => 'Robin Redeker <elmex@x-paste.de>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/Object/Event.pm',
    ABSTRACT_FROM       => 'lib/Object/Event.pm',
    PL_FILES            => {},
    test                => { TESTS => "t/*.t t/methds/*.t" },
    PREREQ_PM => {
        'Test::More'    => 0,
        'AnyEvent'      => 3.5,
        'common::sense' => 0,
    },
    dist                => {
       COMPRESS => 'gzip -9f',
       SUFFIX   => 'gz',
       PREOP => 'pod2text lib/Object/Event.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
    },
    clean               => { FILES => 'Object-Event-*' },
);
