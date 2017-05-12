use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => 'Myco::Core::User',
	      AUTHOR => 'Ben Sommer <ben@mycohq.com>',
	      VERSION_FROM => 'lib/Myco/Core/User.pm',
	      PREREQ_PM => {
			    'Test::More' => 0,
			    'Myco' => 0,
			    'Myco::Core::Person' => 0,
			    'Digest::MD5' => 0,
			   },
	     );
