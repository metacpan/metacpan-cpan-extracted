use ExtUtils::MakeMaker;

WriteMakefile
(
   'PL_FILES'       => 	{},
   'INSTALLDIRS' 	=> 	'site',
   'NAME'           => 	'Statistics::Distributions::Ancova',
   'AUTHOR'         => 	'Daniel S. T. Hughes <dsth@cantab.net>',
   'EXE_FILES' 		=> 	[],
   'VERSION_FROM'   => 	'lib/Statistics/Distributions/Ancova.pm',
   'PREREQ_PM' 		=> {
        					'Test::More' 				=> 0,
    						'Statistics::Distributions' => '1.02',
							'Math::Cephes' 				=> '0.47', 
							'Carp'		 				=> '1.08', 
							'Perl6::Form' 				=> '0.04',
							'Contextual::Return'		=>  '0.2.1',
                            'List::Util'                => '1.19', 
					   },
);
