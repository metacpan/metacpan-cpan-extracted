use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME	    => 'Module::TestConfig',
	      VERSION_FROM  => 'lib/Module/TestConfig.pm',
	      PREREQ_PM	    => { Term::ReadKey	   => 2.21,
				 Params::Validate  => 0.58,
				 Config::Auto	   => 0.03,
#				 Text::FormatTable => 1.00,
				 Test::Warn	   => 0.07,
			       },
);
