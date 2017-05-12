use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Mojolicious::Plugin::I18N',
	license             => 'perl',
	dist_author         => 'Anatoly Sharifulin <sharifulin@gmail.com>',
	dist_version_from   => 'lib/Mojolicious/Plugin/I18N.pm',
	dist_abstract       => 'Internationalization Plugin for Mojolicious',
	configure_requires  => { 'Module::Build' => 0.42 },
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'perl'           => 5.010001,
		'I18N::LangTags' => 0.35,
		'Mojolicious'    => 5.0,
	},
	add_to_cleanup  => [],
	meta_merge => {
		resources => {
			repository => 'http://github.com/sharifulin/Mojolicious-Plugin-I18N',
		},
		keywords => ['mojo', 'mojolicious', 'plugin', 'i18n', 'internationalization'],
	},
	create_makefile_pl => 'traditional',
);

$builder->create_build_script;
