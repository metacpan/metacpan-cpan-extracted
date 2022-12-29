use v5.10;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Net::MQTT::Simple',
    VERSION_FROM  => 'lib/Net/MQTT/Simple.pm',
    ABSTRACT_FROM => 'lib/Net/MQTT/Simple.pm',
    EXE_FILES     => [ 'bin/mqtt-simple' ],
    PREREQ_PM     => { },
    AUTHOR        => 'Juerd Waalboer <juerd@cpan.org>',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Juerd/Net-MQTT-Simple.git',
                web  => 'https://github.com/Juerd/Net-MQTT-Simple',
            },
            bugtracker => {
                web => 'https://github.com/Juerd/Net-MQTT-Simple/issues'
            },
        },
    },
);
