use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
		NAME              => 'Properties',
		VERSION_FROM      => 'lib/Properties.pm', # finds $VERSION
		PREREQ_FATAL => 1,
		PREREQ_PM         => {
				strict => 0,
				warnings => 0,
				Merror => 1.4,	
		},
		($] >= 5.005 ?     ## Add these new keywords supported since 5.005
				(ABSTRACT_FROM  => 'lib/Properties.pm', # retrieve abstract from module
						AUTHOR         => 'Markus Mazurczak <coding@markus-mazurczak.de>'
				) : ()
		),
);
