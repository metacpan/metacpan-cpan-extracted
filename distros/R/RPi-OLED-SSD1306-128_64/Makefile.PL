use strict;
use warnings;
use ExtUtils::MakeMaker;

# The wiringPi presence + version guard is the family-canonical check in
# RPi::Const::BuildCheck (pulled in via CONFIGURE_REQUIRES below). It honours
# RPI_DIST_RELEASE and exits 0 with a message before WriteMakefile when
# wiringPi is missing or too old, so CPAN testers report NA, not FAIL.
eval {
    require RPi::Const::BuildCheck;
    RPi::Const::BuildCheck::wiringpi_build_check();
    1;
} or do {
    # No RPi::Const::BuildCheck (a bare `perl Makefile.PL` with no CPAN client
    # to honour CONFIGURE_REQUIRES). Stay NA-safe: exit 0 unless releasing.
    print "RPi::Const (the build-check dependency) is not installed; install " .
          "it first, or set RPI_DIST_RELEASE to skip the wiringPi check.\n";
    exit 0 if ! $ENV{RPI_DIST_RELEASE};
};

WriteMakefile(
    NAME             => 'RPi::OLED::SSD1306::128_64',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/OLED/SSD1306/128_64.pm',
    ABSTRACT_FROM    => 'lib/RPi/OLED/SSD1306/128_64.pm',
    LICENSE          => 'artistic_2',
    LIBS              => ['-lwiringPi -lrt'],
    DEFINE            => '',
    INC              => '-I.',
    OBJECT           => '$(O_FILES)', # include the extra *.c files (bit.c)
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'RPi::Const'          => '1.07',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'RPi::Const' => '1.07',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-OLED-SSD1306-*' },
);
