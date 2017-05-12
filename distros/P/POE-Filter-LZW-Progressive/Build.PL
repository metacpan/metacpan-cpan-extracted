use Module::Build;

my $build = Module::Build->new(
	module_name => 'POE::Filter::LZW::Progressive',
	license => 'perl',
	requires => {
		'Compress::LZW::Progressive' => 0,
		'POE' => '0.34_01',
	},
	sign => 1,
	create_makefile_pl => 'passthrough',
	create_readme => 1,
);

$build->create_build_script;
