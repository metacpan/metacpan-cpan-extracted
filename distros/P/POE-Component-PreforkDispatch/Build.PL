use Module::Build;

my $build = Module::Build->new(
	module_name => 'POE::Component::PreforkDispatch',
	license => 'perl',
	requires => {
		'POE' => '0.34_01',
                'IO::Capture::Stdout' => 0,
                'Error' => 0,
                'Params::Validate' => 0,
	},
	sign => 1,
	create_makefile_pl => 'passthrough',
	create_readme => 1,
);

$build->create_build_script;
