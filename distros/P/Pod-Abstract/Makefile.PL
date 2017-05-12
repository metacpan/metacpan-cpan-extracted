use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Pod::Abstract',
    AUTHOR              => 'Ben Lilburne <bnej@mac.com>',
    VERSION_FROM        => 'lib/Pod/Abstract.pm',
    ABSTRACT_FROM       => 'lib/Pod/Abstract.pm',
    EXE_FILES           => [ 'bin/paf' ],
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	    'Pod::Parser' => 0,
        'IO::String' => 0,
        'File::Temp' => 0,
        'Scalar::Util' => 0,
        'Task::Weaken' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Pod-Abstract-*' },
);
