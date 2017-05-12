use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Padre::Plugin::Filter',
    AUTHOR              => q{Gregory Siems <gsiems@gmail.com>},
    VERSION_FROM        => 'lib/Padre/Plugin/Filter.pm',
    ABSTRACT_FROM       => 'lib/Padre/Plugin/Filter.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Padre'      => 0.43,
        'Padre::Plugin::Shell::Base' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Padre-Plugin-Filter-*' },
);
