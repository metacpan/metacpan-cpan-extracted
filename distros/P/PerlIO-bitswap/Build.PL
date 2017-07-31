{ use 5.006; }
use warnings;
use strict;

use Module::Build;

Module::Build->new(
	module_name => "PerlIO::bitswap",
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
		"Test::More" => 0,
		"perl" => "5.008001",
		"strict" => 0,
		"warnings" => 0,
	},
	requires => {
		"XSLoader" => 0,
		"perl" => "5.008001",
		"strict" => 0,
		"warnings" => 0,
	},
	dynamic_config => 0,
	meta_add => { distribution_type => "module" },
	meta_merge => {
		"meta-spec" => { version => "2" },
		resources => {
			bugtracker => {
				mailto => "bug-PerlIO-bitswap\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=PerlIO-bitswap",
			},
		},
	},
	sign => 1,
)->create_build_script;

1;
