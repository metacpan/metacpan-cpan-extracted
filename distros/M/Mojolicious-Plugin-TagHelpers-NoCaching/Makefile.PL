use 5.005000;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME              => 'Mojolicious::Plugin::TagHelpers::NoCaching',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/Mojolicious/Plugin/TagHelpers/NoCaching.pm',
	PREREQ_PM         => { 'Mojolicious' => 3.12 },
	BUILD_REQUIRES    => {
		'Test::More' => 0.88
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => { 
		resources => {repository => 'https://github.com/olegwtf/p5-Mojolicious-Plugin-TagHelpers-NoCaching'},
	},
	($] >= 5.005 ?
	(ABSTRACT_FROM  => 'lib/Mojolicious/Plugin/TagHelpers/NoCaching.pm',
	AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
