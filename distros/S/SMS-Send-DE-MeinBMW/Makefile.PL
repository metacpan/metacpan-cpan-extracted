use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SMS::Send::DE::MeinBMW',
    AUTHOR              => 'Boris Zentner <bzm@2bz.de>',
    VERSION_FROM        => 'lib/SMS/Send/DE/MeinBMW.pm',
    ABSTRACT_FROM       => 'lib/SMS/Send/DE/MeinBMW.pm',
    PL_FILES            => {},
    PREREQ_PM => {
      'LWP::UserAgent' => 0,
      'HTTP::Response' => 0,
      'HTTP::Request::Common' => 0,
      'HTTP::Cookies' => 0,
      'HTML::Form' => 0,
      Carp => 0,
      'Test::More' => 0,
      'SMS::Send::Driver' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SMS-Send-DE-MeinBMW-*' },
);
