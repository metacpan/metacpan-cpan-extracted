use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::Descriptive::LogScale',
    AUTHOR              => q{Konstantin S. Uvarin <khedin@gmail.com>},
    VERSION_FROM        => 'lib/Statistics/Descriptive/LogScale.pm',
    ABSTRACT_FROM       => 'lib/Statistics/Descriptive/LogScale.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => 0,
        'POSIX' => 0,
    },
    BUILD_REQUIRES => {
        'Data::Dumper' => 0,
        'FindBin' => 0,
        'Test::More' => 0,
	'Test::Number::Delta' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-Descriptive-LogScale-*' },
);
