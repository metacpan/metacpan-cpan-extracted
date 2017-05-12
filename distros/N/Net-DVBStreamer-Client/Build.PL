use Module::Build;

my $build = Module::Build->new
(
	module_name => 'Net::DVBStreamer::Client',
	license => 'perl',
	script_files => [
		'scripts/dvbctrl.pl',
	],
	build_requires => {
		'Module::Build' => '0.20'
	},
	requires => {
		'perl'	=> '5.5.0',
		'IO::Socket' => 0,
		'Pod::Usage' => 0,
		'Term::ReadLine' => 0,
		'Getopt::Std' => 0,
	},
	
	create_makefile_pl => 'passthrough',
	
	recommends => {
		'HTTP::Daemon' => 0,
	},
);

$build->create_build_script;
