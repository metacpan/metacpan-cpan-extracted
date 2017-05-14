use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Syringe',
    AUTHOR              => q{Rick Apichairuk <rick.apichairuk@gmail.com>},
    VERSION_FROM        => 'lib/Syringe.pm',
    ABSTRACT_FROM       => 'lib/Syringe.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Syringe-*' },
);
