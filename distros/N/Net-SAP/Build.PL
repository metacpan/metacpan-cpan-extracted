use Module::Build;

my $build = Module::Build->new
(
	module_name => 'Net::SAP',
	license => 'perl',
	script_files => [
		'examples/psapd',
	],
	build_requires => {
		'Module::Build' => '0.20'
	},
	requires => {
		'perl'	=> '5.5.0',
		'IO::Socket::Multicast6' => '0.02',
		'IO::Interface' => '1.00',
		'Compress::Zlib' => '1.14',
		'Test::More' => 0,
		'Getopt::Std' => 0,
		'Pod::Usage' => 0,
	},
	
	create_makefile_pl => 'passthrough',
	
	recommends => {
		'Net::SDP' => 0,
	},
);

$build->create_build_script;
