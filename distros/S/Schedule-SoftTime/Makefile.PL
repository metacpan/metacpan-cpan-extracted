use ExtUtils::MakeMaker;
WriteMakefile( NAME => "Schedule-SoftTime",
	       VERSION_FROM => "lib/Schedule/SoftTime.pm",
	       dist => {COMPRESS => "gzip",
			SUFFIX => "gz" }
	     );
