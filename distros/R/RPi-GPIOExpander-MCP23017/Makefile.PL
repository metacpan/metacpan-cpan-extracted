use strict;
use warnings;
use ExtUtils::MakeMaker;

if (! -f '/usr/include/linux/i2c.h' && ! -f '/usr/local/include/linux/i2c.h'){
    print "i2c is not available, exiting...\n";
    exit;
}

WriteMakefile(
    NAME             => 'RPi::GPIOExpander::MCP23017',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/GPIOExpander/MCP23017.pm',
    ABSTRACT_FROM    => 'lib/RPi/GPIOExpander/MCP23017.pm',
    LICENSE          => 'artistic_2',
    INC              => '-I.',
    OBJECT           => '$(O_FILES)', # include the extra *.c files (bit.c)
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-gpioexpander-mcp23017/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-gpioexpander-mcp23017.git',
                web => 'https://github.com/stevieb9/rpi-gpioexpander-mcp23017',
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
        'RPi::Const'    => 1.04,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-GPIOExpander-MCP23017-*' },
);
