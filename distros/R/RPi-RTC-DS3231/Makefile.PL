use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::RTC::DS3231',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/RTC/DS3231.pm',
    ABSTRACT_FROM    => 'lib/RPi/RTC/DS3231.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    INC              => '-I.',
    OBJECT           => '$(O_FILES)', # include the extra *.c files (bit.c)
    MIN_PERL_VERSION => '5.010',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-rtc-ds3231/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-rtc-ds3231.git',
                web => 'https://github.com/stevieb9/rpi-rtc-ds3231',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-RTC-DS3231-*' },
);
