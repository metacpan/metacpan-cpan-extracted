use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'POE::Component::IRC::Plugin::Hello',
	VERSION_FROM     => 'lib/POE/Component/IRC/Plugin/Hello.pm',
	ABSTRACT_FROM    => 'lib/POE/Component/IRC/Plugin/Hello.pm',
	AUTHOR           => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION => '5.14.0',
	LICENSE          => 'perl',
	SIGN             => 1,
	PREREQ_PM        => {
		qw/List::Util 0

		   IRC::Utils 0
		   POE::Component::IRC::Plugin 0/,
	},
	BUILD_REQUIRES   => {
		qw/Test::MockObject 1.09/,
	},
	META_MERGE       => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=poe-component-irc-plugin-hello.git',
		}
	}
);
