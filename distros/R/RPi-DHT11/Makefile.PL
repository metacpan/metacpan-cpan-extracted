use ExtUtils::MakeMaker;

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
