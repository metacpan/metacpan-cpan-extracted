use 5.005;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> "Mojolicious::Plugin::AppCacheManifest",
	ABSTRACT_FROM	=> "lib/Mojolicious/Plugin/AppCacheManifest.pm",
	VERSION_FROM	=> "lib/Mojolicious/Plugin/AppCacheManifest.pm",
	PREREQ_PM	=> {
		Mojolicious	=> "3.12",
	},
	META_MERGE	=> {
		resources	=> {
			license		=> "http://dev.perl.org/licenses/",
			repository	=> "https://github.com/sbertrang/mojolicious-plugin-appcachemanifest.git",
			bugtracker	=> "https://github.com/sbertrang/mojolicious-plugin-appcachemanifest/issues",
		},
	},
	LICENSE		=> "perl",
	AUTHOR		=> 'Simon Bertrang <janus@cpan.org>',
);

