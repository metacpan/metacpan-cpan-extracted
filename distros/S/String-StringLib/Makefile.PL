use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(NAME => 'String::StringLib',
	      VERSION_FROM => 'StringLib.pm',
	      PREREQ_PM => { String::Strip => 1.01, },
	      dist => {
		       COMPRESS => 'gzip',
		       SUFFIX => '.gz',
		      },
             );

