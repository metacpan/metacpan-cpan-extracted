use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Regexp::Log::WMS',
	       VERSION_FROM => 'lib/Regexp/Log/WMS.pm',
	       PREREQ_PM => { Regexp::Log => 0,
			      Test::More => 0 },
	       ABSTRACT_FROM  => 'lib/Regexp/Log/WMS.pm',
	       AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>');
