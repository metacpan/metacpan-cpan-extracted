
use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'Sort::Key::LargeInt',
	       VERSION_FROM => 'lib/Sort/Key/LargeInt.pm',
	       PREREQ_PM => { Sort::Key => 1.28 },
	       AUTHOR => 'Salvador Fandino <sfandino@yahoo.com>');
