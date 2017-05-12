use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SMS::Send::DE::Sipgate',
    AUTHOR              => q{Dominik Schulz <dominik.schulz@gauner.org>},
    VERSION_FROM        => 'lib/SMS/Send/DE/Sipgate.pm',
    ABSTRACT_FROM       => 'lib/SMS/Send/DE/Sipgate.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTTP::Cookies' => 0,
        'XMLRPC::Lite'  => 0,
        'SMS::Send' => 0.02,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SMS-Send-DE-Sipgate-*' },
);
