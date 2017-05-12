use ExtUtils::MakeMaker;
WriteMakefile( NAME => "Module-MetaInfo",
	       VERSION_FROM => "lib/Module/MetaInfo.pm",
	       dist => {COMPRESS => "gzip",
			SUFFIX => "gz" },
	     );
