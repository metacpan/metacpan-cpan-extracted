use strict;
use warnings;
use ExtUtils::MakeMaker;

use version;

my $min_wpi_ver = 2.36;

if (! -f '/usr/include/wiringPi.h' && ! -f '/usr/local/include/wiringPi.h'){
    print "wiringPi is not installed, exiting...\n";
    exit;
}

if (my $path = (grep { -x "$_/gpio" } split /:/, $ENV{PATH})[0]){
    my $bin = "$path/gpio";
    my $gpio_info = `$bin -v`;

    if (my ($version) = $gpio_info =~ /version:\s+(\d+\.\d+)/){

        my $installed_ver = version->parse($version);

        if ($installed_ver < $min_wpi_ver){
            print "\nyou must have wiringPi version $min_wpi_ver" .
                " or greater installed to continue.\n\n" .
                "You have version $version\n";
            exit;
        }
    }
}
else {
    print "\ncan not determine wiringPi version. Ensure version 2.36+ " .
        " is installed. Can't continue\n";
    exit;
}

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
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-OLED-SSD1306-*' },
);
