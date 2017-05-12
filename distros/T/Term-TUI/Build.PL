
use Module::Build;

my $build = Module::Build->new(
	license            => 'perl',
	dist_version       => '1.23',
	dist_author        => 'Sullivan Beck <sbeck@cpan.org>',
	module_name        => 'Term::TUI',
	dist_abstract      => 'simple tool for building text-based user interfaces',
	requires           => {
		'perl'                => '5.6.0',
		'Term::ReadLine'      => '0',
		'Text::ParseWords'    => '0',
	},
	build_requires     => {
		'Test::More'          => '0',
	},
	build_recommends   => {
		'Test::Pod'           => '0',
		'Test::Pod::Coverage' => '0',
	},
	sign               => 1,
);

$build->create_build_script;
