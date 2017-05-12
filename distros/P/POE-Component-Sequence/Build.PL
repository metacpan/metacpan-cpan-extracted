use Module::Build;

my $build = Module::Build->new(
	module_name => 'POE::Component::Sequence',
	license     => 'perl',
	sign        => 1,
	create_readme => 1,
	configure_requires => {
		'Module::Build' => 0.4,
	},
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'POE' => 0,
		'Class::MethodMaker' => 1,
	},
	create_makefile_pl => 'small',
	meta_merge => {
		resources => {
			repository => "http://github.com/ewaters/poe-component-sequence",
			bugtracker => "http://github.com/ewaters/poe-component-sequence/issues?labels=bug",
		},
	},
);

$build->create_build_script;

