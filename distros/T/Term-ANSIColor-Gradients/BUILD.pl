use Module::Build ;

my $builder = Module::Build->new
	(
	module_name       => 'Term::ANSIColor::Gradients',
	dist_version_from => 'lib/Term/ANSIColor/Gradients.pm',
	license           => 'perl',
	dist_abstract     => 'Curated ANSI 256-color palette library for terminal display',
	dist_author       => 'Nadim Khemir <nadim.khemir@gmail.com>',
	requires          =>
		{
		'Term::ANSIColor' => 0,
		'JSON'            => 2,
		},
 	configure_requires => { 'Module::Build' => 0.42 },
	build_requires     => { 'Test::More' => 0 },
	create_makefile_pl => 'traditional',
	script_files       => ['script/ansicolors_gradients'],
	meta_merge         =>
		{
		resources =>
			{
			repository => 'https://github.com/nkh/P5-Term-ANSIColor-Gradients',
			},
		},
	) ;

$builder->create_build_script ;

