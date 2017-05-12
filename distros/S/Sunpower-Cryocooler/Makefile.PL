use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sunpower::Cryocooler',
    AUTHOR              => 'Sam Kerr <kerr@cpan.org>',
    VERSION_FROM        => 'lib/Sunpower/Cryocooler.pm',
    ABSTRACT_FROM       => 'lib/Sunpower/Cryocooler.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Device::SerialPort' => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sunpower-Cryocooler-*' },
);
