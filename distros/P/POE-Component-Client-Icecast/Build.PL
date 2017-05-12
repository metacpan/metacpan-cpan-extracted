use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'POE::Component::Client::Icecast',
	dist_abstract       => 'non-blocking client to Icecast server for getting tags',
	license             => 'perl',
	dist_author         => 'Anatoly Sharifulin <sharifulin@gmail.com>',
	dist_version_from   => 'lib/POE/Component/Client/Icecast.pm',
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'perl' => '5.008',
		'POE::Component::Client::HTTP' => 0,
		'POE::Filter::Stream' => 0,
		'POE::Session' => 0,
		'Carp' => 0,
	},
	meta_merge => {
		resources => {
			repository => 'http://github.com/sharifulin/poe-component-client-icecast/tree',
		},
		keywords => [
			'POE',
			'PoCo',
			'Icecast',
		],
	},
	add_to_cleanup      => [],
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
