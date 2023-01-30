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
		perl                    => '5.12.0', # Prima is minimum 5.12
		'PDL::Drawing::Prima'	  => 0.15,
		PDL                     => '2.4.0',
		Prima                   => 1.67,
		# Needed for event_loop
#		'Term::ReadLine'       => '1.09',
	},
	meta_merge => {
		resources => {
			repository => 'http://github.com/PDLPorters/PDL-Graphics-Prima',
			bugtracker => 'http://github.com/PDLPorters/PDL-Graphics-Prima/issues',
		},
	},
);

$build->add_build_element('png');
$build->create_build_script;
