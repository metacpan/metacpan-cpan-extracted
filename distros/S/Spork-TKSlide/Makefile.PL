
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Kang-min Liu (gugod@gugod.org)',
    ABSTRACT            => 'Spork backend for TKSlide (fancy look html slideshow)',
    NAME                => 'Spork::TKSlide',
    VERSION_FROM		=> 'lib/Spork/TKSlide.pm',
    DISTNAME            => 'Spork-TKSlide',
    PREREQ_PM           => {
        'Spork'   => '0.16',
    },
    dist                => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
    },
);

