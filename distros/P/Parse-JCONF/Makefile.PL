use 5.005000;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME              => 'Parse::JCONF',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/Parse/JCONF.pm',
	PREREQ_PM         => { parent => 0, constant => 1.03 },
	BUILD_REQUIRES    => {
		'Test::More' => 0.88
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => { 
		resources => {repository => 'https://github.com/olegwtf/p5-Parse-JCONF'},
	},
	($] >= 5.005 ?
	(ABSTRACT_FROM  => 'lib/Parse/JCONF.pm',
	AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
