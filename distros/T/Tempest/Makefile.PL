use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tempest',
    AUTHOR              => 'Evan Kaufman <evan@digitalflophouse.com>',
    VERSION_FROM        => 'lib/Tempest.pm',
    ABSTRACT_FROM       => 'lib/Tempest.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'MIT')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'File::Basename' => 0,
        'version' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tempest-*' },
);
