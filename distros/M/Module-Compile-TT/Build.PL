use strict;
use Module::Build;

my $build = Module::Build->new(
	create_makefile_pl => 'traditional',
	license			   => 'perl',
	module_name		   => 'Module::Compile::TT',
	dist_version_from  => "lib/tt.pm",
	requires		   => {
		Template          => 0,
		'Module::Compile' => 0,
		ok                => 0,
	},
	create_readme => 1,
	sign		  => 1,
);
$build->create_build_script;

