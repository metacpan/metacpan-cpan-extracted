use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'POE::Component::Server::AsyncEndpoint',
    VERSION_FROM      => 'lib/POE/Component/Server/AsyncEndpoint.pm',
    PREREQ_PM         => {
        POE => '0.38',
        POE::Component::IKC::Server => 0,
        POE::Component::Logger => 0,
        POE::Component::MessageQueue => '0.2.2',
        POE::Component::Client::Stomp => '0.07',
	SOAP::Lite => 0,
        SOAP::Transport::HTTP => 0,
        AppConfig => 0,
        File::Find => 0,
        File::Util => 0,
        File::Spec => 0,
        File::Basename => 0,
        Term::ReadKey => 0,
	JSON => '2.06',
        IO::Socket => 0,
        Test::More => 0,
        Data::Dumper => 0,
        Net::Stomp => 0,
        Event::Notify => 0,

    },
    EXE_FILES => [
        'bin/aescreate',
        'bin/endpointcreate',
    ],
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/POE/Component/Server/AsyncEndpoint.pm', 
       AUTHOR         => 'Alejandro Imass <ait@p2ee,org>') : ()),
);
