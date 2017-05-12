use Module::Build;

my $build = Module::Build->new(
	module_name => 'Padre-Plugin-Shopify',
	license_from => 'lib/Padre/Plugin/Shopify.pm',
	dist_author_from => 'lib/Padre/Plugin/Shopify.pm',
	dist_version_from => 'lib/Padre/Plugin/Shopify.pm',
	dist_abstract => 'Support for theme modification, through Padre.',
	configure_requires => { 'Module::Build' => 0.38 },
	requires => {
		'WWW::Shopify' => 0.997,
		'WWW::Shopify::Tools::Themer' => 0.11,
		'WWW::Shopify::Liquid' => 0,
		'Padre' => 0,
		'Browser::Open' => 0
	},
	share_dir => ['share'],
	meta_merge => {
		resources => {
			 repository  => 'https://bitbucket.org/bengmn/padre-shopify-plugin/'
		}
	}
);
$build->create_build_script;
