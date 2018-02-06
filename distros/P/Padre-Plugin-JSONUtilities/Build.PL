use Module::Build;

my $build = Module::Build->new(
	module_name => 'Padre-Plugin-JSONUtilities',
	license_from => 'lib/Padre/Plugin/JSONUtilities.pm',
	dist_author_from => 'lib/Padre/Plugin/JSONUtilities.pm',
	dist_version_from => 'lib/Padre/Plugin/JSONUtilities.pm',
	dist_abstract => 'Support for beautifying/compressing JSON directly in Padre.',
	configure_requires => { 'Module::Build' => 0.38 },
	requires => {
		'Padre' => 0,
		'JSON' => 0
	},
	share_dir => ['icons']
);
$build->create_build_script;
