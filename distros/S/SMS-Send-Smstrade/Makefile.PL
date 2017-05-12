use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SMS::Send::Smstrade',
    AUTHOR              => q{Dominik Schulz <dominik.schulz@gauner.org>},
    VERSION_FROM        => 'lib/SMS/Send/Smstrade.pm',
    ABSTRACT_FROM       => 'lib/SMS/Send/Smstrade.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'URI::Escape' => 0,
        'SMS::Send' => 0.02,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SMS-Send-Smstrade-*' },
);
