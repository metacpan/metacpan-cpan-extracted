use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Object::By',
	'VERSION'	=> 'v0.08',
	'AUTHOR'	=> 'Winfried Trumper <pub+perl@wt.tuxomania.net>',
	'LICENSE'	=> 'perl',
	'MIN_PERL_VERSION' => 5.8.1,
	'PREREQ_PM'	  => {
		'parent' => 0.01
	},
);
