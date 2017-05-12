use strict;
use warnings;
 
use ExtUtils::MakeMaker;
 
my %WriteMakefileArgs = (
	'ABSTRACT' => 'Perl Modules Information Extractor',
	'AUTHOR' => 'Nuno Martins <nuno.martins@caixamagica.pt>',
	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker' => '6.31'
	},
	'DISTNAME' => 'PMInfoExtr',
	'EXE_FILES' => [ 
		"bin/modules-extractor.pl",
	],
	'LICENSE' => 'Apache2',
	'NAME' => 'PMInfoExtr',
	'VERSION_FROM'  => 'lib/PMInfoExtr/Manager.pm',
	'PREREQ_PM' => {
		'JSON' => '0',
		'Moose' => '0',
		'UUID::Tiny' => '0',
		'MetaCPAN::API' => '0',
		'DPKG::Parse' => '0',
		'Devel::Modlist' => '0',
		'Getopt::Long' => '0',
		'File::Find::Rule' => '0',
	},
	'test' => {
		'TESTS' => 't/*.t'
	},
	'SIGN' => '1',
);
 
WriteMakefile(%WriteMakefileArgs)
