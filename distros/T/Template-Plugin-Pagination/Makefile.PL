use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Template::Plugin::Pagination',
    'VERSION_FROM'	=> 'lib/Template/Plugin/Pagination.pm', 
    'PREREQ_PM'		=> { 
			'Template' => '2.07', 
			'Data::Paginated' => '1.00' 
		},
);
