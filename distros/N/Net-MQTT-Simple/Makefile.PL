use v5.10;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Net::MQTT::Simple',
    VERSION_FROM  => 'lib/Net/MQTT/Simple.pm',
    ABSTRACT_FROM => 'lib/Net/MQTT/Simple.pm',
    EXE_FILES     => [ 'bin/mqtt-simple' ],
    PREREQ_PM     => { },
    AUTHOR        => 'Juerd Waalboer <juerd@cpan.org>'
);
