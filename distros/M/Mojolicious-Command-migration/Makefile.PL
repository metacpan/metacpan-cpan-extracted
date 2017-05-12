

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Mojolicious::Command::migration',
	VERSION_FROM => 'lib/Mojolicious/Command/migration.pm', # finds \$VERSION
	AUTHOR       => 'Alexey Likhatskiy <likhatskiy\@gmail.com>',
	ABSTRACT     => 'MySQL migration tool for Mojolicious',
	PREREQ_PM    => {
		'Test::Simple'          => 0.44,
		'Mojolicious'           => 4.0,
		'DBI'                   => 0,
		'DBD::mysql'            => 0,
		'common::sense'         => 0,
		'Getopt::Long'          => 0,
		'SQL::Translator'       => 0,
		'SQL::Translator::Diff' => 0,
	},
);
