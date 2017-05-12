use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		=> 'Regexp::Cherokee',
	DISTNAME	=> 'Regexp-Cherokee',
	VERSION_FROM	=> 'lib/Regexp/Cherokee.pm', # finds $VERSION
	AUTHOR		=> "Daniel Yacob <dyacob\@cpan.org>",
	ABSTRACT	=> "Regular Expressions Support for Cherokee Script and the Languages that use it.",
	dist			=>	{
		COMPRESS        =>	"gzip -9f",
		SUFFIX          =>	"gz",
		POSTOP          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	}
);
