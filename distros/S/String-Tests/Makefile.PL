use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Tests',
    AUTHOR              => 'Shaun Fryer <pause.cpan.org@sourcery.ca>',
    VERSION_FROM        => 'lib/String/Tests.pm',
    ABSTRACT_FROM       => 'lib/String/Tests.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => 0,
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Tests-*' },
);
