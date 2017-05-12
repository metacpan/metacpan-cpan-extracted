use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Mojolicious::Plugin::ShareHelpers',
	license             => 'perl',
	dist_author         => 'Anatoly Sharifulin <sharifulin@gmail.com>',
	dist_version_from   => 'lib/Mojolicious/Plugin/ShareHelpers.pm',
	dist_abstract       => 'A Mojolicious Plugin for generate share urls, buttons and meta for Twitter, Facebook, Google Buzz, VKontakte, MyMailRU and Google Plus',
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'Mojolicious' => '1.17',
	},
	add_to_cleanup  => [],
	meta_merge => {
		resources => {
			repository => 'http://github.com/sharifulin/Mojolicious-Plugin-ShareHelpers',
		},
		keywords => ['mojo', 'mojolicious', 'share', 'helper', 'plugin'],
	},
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
