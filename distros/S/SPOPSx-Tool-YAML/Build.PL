use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'SPOPSx::Tool::YAML',
	license            => 'perl',
	create_makefile_pl => 'passthrough',
	create_readme      => 1,
	requires           => {
		'SPOPS' => '0.87',
		'YAML'  => '0.39',
	},
);

$build->create_build_script;
