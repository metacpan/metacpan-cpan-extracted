use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'RiveScript',
	VERSION_FROM      => 'lib/RiveScript.pm', # finds $VERSION
	PREREQ_PM         => {
		version => 0.77,
		JSON => 0,
	}, # e.g., Module::Name => 1.1
	EXE_FILES         => [ 'bin/rivescript' ],
	LICENSE           => 'mit',
	MIN_PERL_VERSION  => '5.8.0',
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	  (ABSTRACT_FROM  => 'lib/RiveScript.pm', # retrieve abstract from module
	   AUTHOR         => 'Noah Petherbridge <kirsle@cpan.org>') : ()),
);
