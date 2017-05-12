{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->subclass(code => q{
	sub ACTION_testauthor { $_[0]->generic_test(type => "author") }
})->new(
	module_name => "Net::FTP::Tiny",
	license => "perl",
	configure_requires => {
		"Module::Build" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	build_requires => {
		"Module::Build" => 0,
		"Test::More" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"Carp" => 0,
		"Exporter" => 0,
		"IO::Socket::INET" => "1.24",
		"Socket" => "1.72",
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
		("$]" < 5.008 ? (
			"bytes" => 0,
			"utf8" => 0,
		) : (
			"utf8" => 0,
		)),
	},
	recommends => {
		"IO::Socket::IP" => "0.08",
	},
	dynamic_config => 1,
	meta_add => { distribution_type => "module" },
	test_types => { author => ".at" },
	create_makefile_pl => "passthrough",
	sign => 1,
)->create_build_script;

1;
