use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Object::Recorder',
    AUTHOR              => 'Nilson Santos Figueiredo Junior <nilsonsfj@cpan.org>',
    VERSION_FROM        => 'lib/Object/Recorder.pm',
    ABSTRACT_FROM       => 'lib/Object/Recorder.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Memoize'    => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Object-Recorder-*' },
);
