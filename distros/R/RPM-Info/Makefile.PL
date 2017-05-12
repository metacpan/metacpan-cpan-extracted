use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'RPM::Info',
	'VERSION_FROM'	=> 'Info.pm',
	'PREREQ_PM'     => {
    		             'Test' => 0,
			   },
	'clean'		=> {
		             'FILES'     => 'RPM-Info-*'
			   },
);
