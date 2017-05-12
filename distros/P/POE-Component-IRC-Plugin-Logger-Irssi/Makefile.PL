use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'POE::Component::IRC::Plugin::Logger::Irssi',
	VERSION_FROM      => 'lib/POE/Component/IRC/Plugin/Logger/Irssi.pm',
	ABSTRACT_FROM     => 'lib/POE/Component/IRC/Plugin/Logger/Irssi.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	META_MERGE         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'http://git.ieval.ro/?p=poe-component-irc-plugin-logger-irssi.git',
		}
	}
);
