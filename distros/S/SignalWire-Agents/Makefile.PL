use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SignalWire::Agents',
    VERSION_FROM => 'lib/SignalWire/Agents.pm',
    ABSTRACT     => 'SignalWire AI Agents SDK for Perl',
    AUTHOR       => 'SignalWire <support@signalwire.com>',
    LICENSE      => 'mit',
    MIN_PERL_VERSION => '5.026',
    PREREQ_PM => {
        'Moo'               => '2.0',
        'JSON'              => '4.0',
        'Plack'             => '1.0',
        'Plack::Request'    => 0,
        'HTTP::Tiny'        => 0,
        'Digest::SHA'       => 0,
        'MIME::Base64'      => 0,
        'Protocol::WebSocket' => '0.26',
    },
    TEST_REQUIRES => {
        'Test::More'        => '0.98',
        'Plack::Test'       => 0,
        'HTTP::Request::Common' => 0,
    },
    EXE_FILES => ['bin/swaig-test'],
    META_MERGE => {
        resources => {
            repository => 'https://github.com/signalwire/signalwire-agents-perl',
        },
    },
);
