use strict;
use Module::Build;
use vars qw($build);

my $build = Module::Build->new (
	module_name		=> 'NetAthlon2::RAW',
	license			=> 'perl',
	create_makefile_pl	=> 'passthrough',
	create_readme		=> 1,
	sign				=> 0,
	add_to_cleanup		=> ['t/Bike*.RAW', 't/Bike*.png', 'Makefile' ],
	script_files		=> [ 'script/na2png' ],
	requires			=> {
		'perl'		=> '5.005_03',
		'Carp'		=> 0,
		'POSIX'		=> 0,
		'Socket'		=> 0,
		'GD::Graph'	=> 0,
	},
	build_requires		=> {
		'Archive::Tar'	=> 0,
	},
	recommendes		=> {
		'Test'		=> 0,
	},
);

$build->create_build_script;
