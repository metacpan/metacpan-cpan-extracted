use strict;
use warnings;

use ExtUtils::MakeMaker;


my %WriteMakefileArgs = (
	'ABSTRACT' => 'Network Information Extractor',
	'AUTHOR' => 'Nuno Martins <nuno.martins@caixamagica.pt>',
	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker' => '6.31'
	},
	'DISTNAME' => 'NetInfoExtractor',
	'EXE_FILES' => [
		"bin/network_extractor.pl",
	],
	'LICENSE' => 'Apache 2',
	'NAME' => 'NetInfoExtractor',
	'VERSION_FROM'  => 'lib/NetInfoExtractor/Interface.pm',
	'PREREQ_PM' => {
		'JSON' => '0',
		'Moose' => '0',
		'UUID::Tiny' => '0',
		'Getopt::Long' => '0',
	},
	'test' => {
		'TESTS' => 't/*.t'
	},
	'SIGN' => '1',
);

WriteMakefile(%WriteMakefileArgs);
