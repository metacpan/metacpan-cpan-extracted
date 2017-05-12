use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'PDL::Graphics::Prima',
	dist_version_from => 'lib/PDL/Graphics/Prima.pm',
	license  => 'perl',
	configure_requires => {
		# meta_merge was added in v 0.28:
		'Module::Build' => 0.28,
	},
	requires => {
		# No I will not support 5.6
		perl					=> '5.8.0',
		'PDL::Drawing::Prima'	=> 0.07,
		PDL						=> '2.4.0',
		Prima					=> 1.40,
		# Needed for event_loop
#		'Term::ReadLine'       => '1.09',
	},
	meta_merge => {
		resources => {
			repository
				=> 'http://github.com/run4flat/PDL-Graphics-Prima',
#				=> {
#					web => 'http://github.com/run4flat/PDL-Graphics-Prima',
#					url => 'git://github.com/run4flat/PDL-Graphics-Prima.git',
#					type => 'git',
#				},
			bugtracker
				=> 'http://github.com/run4flat/PDL-Graphics-Prima/issues',
#				=> {
#					web => 'http://github.com/run4flat/PDL-Graphics-Prima/issues',
#				},
		},
	},
);

$build->create_build_script;
