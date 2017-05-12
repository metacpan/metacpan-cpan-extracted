use ExtUtils::MakeMaker;

require 5.006;

print <<'HERE';
=====================================================================
             This module is looking for a maintainer!

No one is maintaining this module, but you can take up its care
and feeding by requesting CPAN persmissions from modules@perl.org.

This version is assigned to the ADOPTME CPAN user and hosted in
GitHub:

	https://github.com/CPAN-Adopt-Me/Palm-Magellan-NavCompanion

=====================================================================
HERE

WriteMakefile
	(
	'NAME'          => 'Palm::Magellan::NavCompanion',
	'ABSTRACT'      => 'access the Magellan GPS Companion waypoints file',
	'VERSION_FROM'  => 'lib/Palm/NavCompanion.pm',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'PREREQ_PM'      => {
		'Test::More'        => '0',
		'Palm::Raw'         => '0',
		'Palm::StdAppInfo'  => '0',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/CPAN-Adopt-Me/Palm-Magellan-NavCompanion',
				web  => 'https://github.com/CPAN-Adopt-Me/Palm-Magellan-NavCompanion',
				},
			},
		},

	clean => { FILES => 'Palm-Magellan-*' },
	);
