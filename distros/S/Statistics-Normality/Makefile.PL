use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::Normality',
    AUTHOR              => 'Mike Wendl <mwendl@genome.wustl.edu>',
    VERSION_FROM        => 'lib/Statistics/Normality.pm',
    ABSTRACT_FROM       => 'lib/Statistics/Normality.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-Normality-*' },
);
