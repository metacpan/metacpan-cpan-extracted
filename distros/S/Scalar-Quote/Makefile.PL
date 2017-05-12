use 5.006000;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Scalar::Quote',
	       VERSION_FROM  => 'lib/Scalar/Quote.pm',
	       PREREQ_PM     => { Test::More },
	       ABSTRACT_FROM => 'lib/Scalar/Quote.pm',
	       AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>' );
