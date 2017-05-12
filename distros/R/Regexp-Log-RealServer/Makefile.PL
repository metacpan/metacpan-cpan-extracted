use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Regexp::Log::RealServer',
	       VERSION_FROM => 'lib/Regexp/Log/RealServer.pm',
	       PREREQ_PM => { Regexp::Log => 0,
			      Test::More => 0 },
	       ABSTRACT_FROM  => 'lib/Regexp/Log/RealServer.pm',
	       AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>' );

