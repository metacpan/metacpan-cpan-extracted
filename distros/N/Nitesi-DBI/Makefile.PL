use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Nitesi::DBI',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Nitesi/DBI.pm',
    ABSTRACT_FROM       => 'lib/Nitesi/DBI.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'Test::More' => 0,
	'Test::Database' => 0,
	'SQL::Statement' => 0,
    },
    PREREQ_PM => {
	'SQL::Abstract' => 0,
	'SQL::Abstract::More' => 0,
        'Nitesi' => 0.0092,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Nitesi-DBI-*' },
    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/racke/Nitesi-DBI',
        },
    },
);
