
use Module::Build;

my $build = Module::Build->new(
	license            => 'perl',
	dist_version       => '3.00',
	dist_author        => 'Sullivan Beck <sbeck@cpan.org>',
	module_name        => 'Template::Plugin::NDS_Multi',
	dist_abstract      => 'Interface to Data::NDS::Multi* modules',
	requires           => {
		'perl'                => '5.6.0',
		'Template'            => '0',
		'Template::Plugin'    => '0',
	},
	build_requires     => {
		'Data::NDS::Multiele' => '0',
		'Data::NDS::Multifile'=> '0',
		'Data::NDS::Multisource'=> '0',
		'IO::File'            => '0',
		'Template::Constants' => '0',
		'Test::More'          => '0',
	},
	build_recommends   => {
		'Test::Pod'           => '0',
		'Test::Pod::Coverage' => '0',
	},
	sign               => 1,
);

$build->create_build_script;
