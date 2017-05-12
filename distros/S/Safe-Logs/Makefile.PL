use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.1.1.1 2003/03/03 05:20:28 lem Exp $

WriteMakefile(
    'NAME'		=> 'Safe::Logs',
    'VERSION_FROM'	=> 'Logs.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM	=> 'Logs.pm',
		AUTHOR     	=> 'Luis E. Muñoz <luismunoz@cpan.org>') : ()),

);
