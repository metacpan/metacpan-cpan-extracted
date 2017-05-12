use ExtUtils::MakeMaker;



# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'String::Equivalence::Amharic',
	DISTNAME	=> 'String-Equivalence-Amharic',
	VERSION_FROM	=> 'lib/String/Equivalence/Amharic.pm',
	dist			=>	{
		COMPRESS        =>	"gzip -9f",
		SUFFIX          =>	"gz",
		POSTOP          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	AUTHOR  	=> "Daniel Yacob <dyacob\@cpan.org>",
	ABSTRACT	=> "Normalization Utilities for Amharic.",
	PREREQ_PM 	=> { 'Regexp::Ethiopic' => "0.15" }
);
