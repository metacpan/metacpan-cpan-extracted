use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::CallFlow',
    AUTHOR              => 'Kalle Hallivuori <kato@iki.fi>',
    VERSION_FROM        => 'lib/Test/CallFlow.pm',
    ABSTRACT_FROM       => 'lib/Test/CallFlow.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.86,
        'Carp' => 1,
        'Exporter' => 5,
        'File::Spec' => 3,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-CallFlow-*' },
);
