use Module::Build;

Module::Build->new(
	module_name => 'Term::ReadLine::Zoid',
	license     => 'perl',
	dist_author => 'Jaap Karssenberg <pardus@cpan.org>',
	requires    => {
		'AutoLoader'    => 0,
     		'Term::ReadKey' => 0,
	},
	recommends  => {
		'File::Temp'    => 0,
	},
	build_requires => {
		'AutoSplit'     => 0,
	},
	autosplit => 'lib/Term/ReadLine/Zoid/ViCommand.pm',
	create_makefile_pl => 'passthrough',
)->create_build_script;
