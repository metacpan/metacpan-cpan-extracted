#!/usr/bin/perl

use Module::Build;

my $b = Module::Build->new(
	'module_name'	=> 'Number::Phone::Normalize',
	'license'	=> 'perl',
	
	'sign'		=> 1,
	'create_license' => 1,
	'write_makefile_pl' => 'traditional',

	'build_requires' => {
		'Test::More' => 0,
	}
);

$b->create_build_script;
