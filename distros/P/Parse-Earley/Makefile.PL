use ExtUtils::MakeMaker;

WriteMakefile(
	($] ge '5.006001') ? 
	(
		AUTHOR => 'Luke Palmer (fibonaci@babylonia.flatirons.org)',
		ABSTRACT => 'Parse _any_ context-free grammar',
	) : (),
	clean => { FILES => 'blib/* Makefile Parse-Earley-*' },
	dist => { COMPRESS => 'gzip', SUFFIX => 'gz' },
	DISTNAME => 'Parse-Earley',
	NAME => 'Parse::Earley',
	PM => { 'Earley.pm' => '$(INST_LIBDIR)/Earley.pm' },
	PREREQ_PM => { 'Text::Balanced' => 0 },
	VERSION => '0.14'
);
