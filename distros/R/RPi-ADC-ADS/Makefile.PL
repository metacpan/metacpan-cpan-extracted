use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'RPi::ADC::ADS',
    VERSION_FROM      => 'lib/RPi/ADC/ADS.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/RPi/ADC/ADS.pm',
       AUTHOR         => 'Steve Bertrand <steveb@cpan.org>') : ()),
    LIBS              => [],
    DEFINE            => '',
    INC               => '-I.',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-adc-ads/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-adc-ads.git',
                web => 'https://github.com/stevieb9/rpi-adc-ads',
            },
        },
    },
    PREREQ_PM         => {
    },
#    CCFLAGS => => '-Wno-unused-result',
);
