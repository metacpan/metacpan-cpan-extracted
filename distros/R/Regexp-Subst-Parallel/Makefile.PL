use ExtUtils::MakeMaker;

WriteMakefile(
	AUTHOR => 'Luke Palmer (fibonaci@babylonia.flatirons.org',
	ABSTRACT => 'Perform safe, parallel substitutions',
	clean => { FILES => 'blib/* Makefile' },
	dist => { COMPRESS => 'gzip', SUFFIX => 'gz' },
	DISTNAME => 'Regexp-Subst-Parallel',
	NAME => 'Regexp::Subst::Parallel',
	PM => { 'Parallel.pm' => '$(INST_LIBDIR)/Parallel.pm' },
	PREREQ_PM => { },
);
