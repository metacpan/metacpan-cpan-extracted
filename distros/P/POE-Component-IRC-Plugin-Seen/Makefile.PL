use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'POE::Component::IRC::Plugin::Seen',
	VERSION_FROM     => 'lib/POE/Component/IRC/Plugin/Seen.pm',
	ABSTRACT_FROM    => 'lib/POE/Component/IRC/Plugin/Seen.pm',
	AUTHOR           => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION => 5.014000,
	LICENSE          => 'perl',
	SIGN             => 1,
	BUILD_REQUIRES   => {
		qw/Test::MockObject 0/,
	},
	PREREQ_PM        => {
		qw/DB_File                     0
		   POE::Component::IRC::Plugin 0
		   IRC::Utils                  0.05/,
	},
	META_MERGE       => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=poe-component-irc-plugin-seen.git',
		}
	}
);
