use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Omega::DP41::Data::Current',
    AUTHOR              => 'Sam Kerr <kerr@cpan.org>',
    VERSION_FROM        => 'lib/Omega/DP41/Data/Current.pm',
    ABSTRACT_FROM       => 'lib/Omega/DP41/Data/Current.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Device::SerialPort' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Omega-DP41-Data-Current-*' },
);
