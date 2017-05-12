use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Stlgen',
    AUTHOR              => q{Greg London <email@greglondon.com>},
    VERSION_FROM        => 'lib/Stlgen.pm',
    ABSTRACT_FROM       => 'lib/Stlgen.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Stlgen-*' },
);
