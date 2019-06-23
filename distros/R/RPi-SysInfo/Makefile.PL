use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::SysInfo',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/SysInfo.pm',
    ABSTRACT_FROM    => 'lib/RPi/SysInfo.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-sysinfo/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-sysinfo.git',
                web => 'https://github.com/stevieb9/rpi-sysinfo',
            },
        },
    },
    MIN_PERL_VERSION   => 5.010,
    LICENSE => 'perl_5',
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
    clean => { FILES => 'RPi-SysInfo-*' },
);
