use strict;
use warnings;
use ExtUtils::MakeMaker;

# RPI_DIST_RELEASE allows cutting release tarballs on non-Pi machines by
# bypassing the wiringPi presence check below. Without it, missing wiringPi
# exits before WriteMakefile so CPAN testers report NA, not FAIL (the exit
# was previously commented out, which sacrificed the NA behavior)

if (! $ENV{RPI_DIST_RELEASE}){
    if (! -f '/usr/include/wiringPi.h' && ! -f '/usr/local/include/wiringPi.h'){
        print "wiringPi is not installed and RPI_DIST_RELEASE is not set, " .
              "exiting...\n";
        exit;
    }
}

WriteMakefile(
    NAME              => 'RPi::DHT11',
    VERSION_FROM      => 'lib/RPi/DHT11.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/RPi/DHT11.pm',
       AUTHOR         => 'Steve Bertrand <steveb@cpan.org>') : ()
    ),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-dht11/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-dht11.git',
                web => 'https://github.com/stevieb9/rpi-dht11',
            },
        },
    },
    BUILD_REQUIRES => {
        'Test::More' => 1.302078,
    },
    LIBS              => ['-lwiringPi -lrt'],
    DEFINE            => '',
    INC               => '-I.',
);
