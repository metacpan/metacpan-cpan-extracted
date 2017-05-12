{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "Sub::Filter",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.008001",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"ExtUtils::CBuilder" => "0.15",
		"Module::Build" => 0,
		"Sub::Mutate" => "0.005",
		"Test::More" => 0,
		"perl" => "5.008001",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Attribute::Lexical" => "0.004",
		"Carp" => 0,
		"Sub::Mutate" => "0.005",
		"XSLoader" => 0,
		"perl" => "5.008001",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
