use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'POE::Component::IRC::Plugin::Infobot',
	VERSION_FROM      => 'lib/POE/Component/IRC/Plugin/Infobot.pm',
	ABSTRACT_FROM     => 'lib/POE/Component/IRC/Plugin/Infobot.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/POE::Component::IRC::Plugin 0
		   IRC::Utils                  0.12
		   DB_File                     0/,
	},
	BUILD_REQUIRES      => {
		qw/Test::MockObject 0/,
	},
	META_MERGE          => {
		dynamic_config  => 0,
		resources       => {
			repository  => 'http://git.ieval.ro/?p=poe-component-irc-plugin-infobot.git',
		}
	},
);
