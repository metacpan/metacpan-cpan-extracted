use ExtUtils::MakeMaker;



# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'String::Downgrade::Amharic',
	DISTNAME	=> 'String-Downgrade',
	VERSION_FROM	=> 'lib/String/Downgrade/Amharic.pm',
	dist			=>	{
		COMPRESS        =>	"gzip -9f",
		SUFFIX          =>	"gz",
		POSTOP          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	AUTHOR  	=> "Daniel Yacob <dyacob\@cpan.org>",
	ABSTRACT	=> "Generate Acceptable Spellings from Canonical.",
	PREREQ_PM 	=> { 'Regexp::Ethiopic' => "0.10" }
);
