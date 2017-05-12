use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PFIX',
    AUTHOR              => q{"Gabriel Galibourg" <"">},
    VERSION_FROM        => 'lib/PFIX.pm',
    ABSTRACT_FROM       => 'lib/PFIX.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PFIX-*' },
);
