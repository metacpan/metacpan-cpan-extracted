use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Schedule::AdaptiveThrottler',
    AUTHOR              => q{David Morel <david.morel@amakuru.net>},
    VERSION_FROM        => 'lib/Schedule/AdaptiveThrottler.pm',
    ABSTRACT_FROM       => 'lib/Schedule/AdaptiveThrottler.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),

    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
        'Digest::MD5' => 0,
        },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Schedule-AdaptiveThrottler-*' },
);
