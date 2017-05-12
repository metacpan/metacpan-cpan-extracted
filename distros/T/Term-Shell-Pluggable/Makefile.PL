use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Term::Shell::Pluggable',
	AUTHOR => 'Dmitri Popov <operator@cv.dp-net.com>',
	LICENSE => 'perl',
	VERSION_FROM => 'lib/Term/Shell/Pluggable.pm',
	ABSTRACT_FROM => 'lib/Term/Shell/Pluggable.pm',
	PL_FILES => {},
	PREREQ_PM => {
		'Test::More' => 0,
		'Term::Shell' => 0,
	},
	MIN_PERL_VERSION => '5.8.8',
	META_MERGE => {
		resources => {
			bugtracker => 'http://github.com/pin/term-shell-pluggable/issues',
			repository => 'git://github.com/pin/term-shell-pluggable.git',
		},
	},
	dist => {
		COMPRESS => 'gzip -9f',
		SUFFIX => 'gz'
	},
	clean => {
		FILES => 'Term-Shell-Pluggable-*'
	}
);
