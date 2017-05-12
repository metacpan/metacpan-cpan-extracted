use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'		=> 'Template::Provider::MD5',
	'VERSION_FROM'	=> 'lib/Template/Provider/MD5.pm', 
	'PREREQ_PM'	=> {
		'Template' => 2.06,
	},
	(
    		$] >= 5.6 ? (
			ABSTRACT_FROM 	=> 'lib/Template/Provider/MD5.pm',
       			AUTHOR     	=> 'Scott Penrose <scott@cpan.org>'
		) : ()
	),
);
