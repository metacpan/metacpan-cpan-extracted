use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Template::Nest',
    VERSION_FROM      => 'lib/Template/Nest.pm',
    PREREQ_PM         => { 
		'Carp' => 0,
		'File::Spec' => 0	
	},
    ABSTRACT_FROM     => 'lib/Template/Nest.pm',
    AUTHOR            => 'Tom Gracey <tomgracey@gmail.com>',
    LICENSE           => 'perl',
);
