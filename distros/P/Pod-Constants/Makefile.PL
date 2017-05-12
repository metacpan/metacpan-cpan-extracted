use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Pod::Constants',
	VERSION_FROM     => 'lib/Pod/Constants.pm',
	ABSTRACT_FROM    => 'lib/Pod/Constants.pm',
	AUTHOR           => ['Sam Vilain <sam@vilain.net>', 'Marius Gavrilescu <marius@ieval.ro>'],
	MIN_PERL_VERSION => '5.6.2',
	LICENSE          => 'artistic_2',
	SIGN             => 1,
	PREREQ_PM => {
		qw/Pod::Parser  1.13/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=pod-constants.git',
		},
	}
);
