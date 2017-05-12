
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Pipeworks',
	VERSION_FROM	=> 'lib/Pipeworks.pm',
	PREREQ_PM	=> {
		Mojolicious	=> '6.0',
	},
	ABSTRACT_FROM	=> 'lib/Pipeworks.pm',
	AUTHOR		=> 'Simon Bertrang <janus@cpan.org>',
	META_MERGE	=> {
		resources	=> {
			license		=> 'http://dev.perl.org/licenses/',
			repository	=> 'https://github.com/sbertrang/pipeworks.git',
			bugtracker	=> 'https://github.com/sbertrang/pipeworks/issues',
		},
	},
	LICENSE		=> 'perl',
);
