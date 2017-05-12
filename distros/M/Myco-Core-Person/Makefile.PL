use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => 'Myco::Core::Person',
	      AUTHOR => 'Ben Sommer <ben@mycohq.com>',
	      VERSION_FROM => 'lib/Myco/Core/Person.pm',
	      PREREQ_PM => {
			    'Test::More' => 0,
			    'Myco' => 0,
			    'Lingua::Strfname' => 0,
			   },
	     );
