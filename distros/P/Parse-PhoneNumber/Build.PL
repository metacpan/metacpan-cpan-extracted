use strict;

use Module::Build;

Module::Build->new(
	module_name => 'Parse::PhoneNumber',
	license     => 'perl',
	build_requires => {
		'Test::More'    => 0,
		'Module::Build' => 0,
	},
	create_makefile_pl => 'traditional',
	configure_requires => { 'Module::Build' => 0.38 },
	meta_merge => {
		resources => {
			repository => 'https://github.com/twilde/Parse-PhoneNumber',
		},
	},
)->create_build_script;
