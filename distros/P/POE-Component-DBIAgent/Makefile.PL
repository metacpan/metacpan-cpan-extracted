use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'POE::Component::DBIAgent',
	      'VERSION_FROM' => 'DBIAgent.pm',
	      'PREREQ_PM' => { 'POE' => 0.17,
			       'DBI' => 0,
			       'Storable' => 0,
			       'Socket' => 0,
			       'Class::MethodMaker' => 0,
			     },
);
