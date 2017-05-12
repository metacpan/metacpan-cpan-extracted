
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Sort::Key::Merger',
	       VERSION_FROM => 'lib/Sort/Key/Merger.pm',
	       PREREQ_PM => { Test::More => 0,
			      Sort::Key => 0 },
	       ABSTRACT_FROM  => 'lib/Sort/Key/Merger.pm',
	       AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>',	
	       # OPTIMIZE => '-g -O0',
	       INC => '-I.' );

