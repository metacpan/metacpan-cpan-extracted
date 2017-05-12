use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'          => 'POE::Component::Cache',
	'VERSION_FROM'  => 'POE/Component/Cache.pm',
	'PREREQ_PM'     =>  {
	
		'POE'  => 0,
	}
);
