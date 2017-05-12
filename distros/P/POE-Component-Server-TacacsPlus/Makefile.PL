use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'POE::Component::Server::TacacsPlus',
	VERSION_FROM => 'lib/POE/Component/Server/TacacsPlus.pm', # finds $VERSION
	PREREQ_PM    => {
		Carp::Clan    => 0,
		'Log::Log4perl'              => 0,
		Test::More    => 0,
		'Net::TacacsPlus::Client'    => '1.09',
		'Net::TacacsPlus::Constants' => '1.09',
		'Net::TacacsPlus::Packet'    => '1.09',
		POE           => 0,
	},
	ABSTRACT_FROM => 'lib/POE/Component/Server/TacacsPlus.pm', # retrieve abstract from module
	AUTHOR        => 'Jozef Kutej <jkutej@cpan.org>',
	(MM->can('signature_target') ? (SIGN => 1) : ()),
	LICENSE => 'perl',
);
