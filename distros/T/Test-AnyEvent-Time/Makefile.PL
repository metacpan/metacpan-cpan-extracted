use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::AnyEvent::Time',
    AUTHOR              => q{Toshio Ito <debug.ito@gmail.com>},
    VERSION_FROM        => 'lib/Test/AnyEvent/Time.pm',
    ABSTRACT_FROM       => 'lib/Test/AnyEvent/Time.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Scalar::Util' => 0,
        'Test::Builder' => 0,
        'AnyEvent' => '7.01',
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-AnyEvent-Time-*' },
);
