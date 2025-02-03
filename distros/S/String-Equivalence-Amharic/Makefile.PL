use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'String::Equivalence::Amharic',
	'DISTNAME'	=> 'String-Equivalence-Amharic',
	'VERSION_FROM'	=> 'lib/String/Equivalence/Amharic.pm',
	'AUTHOR'  	=> "Daniel Yacob <dyacob\@cpan.org>",
	'ABSTRACT'	=> "Normalization Utilities for Amharic.",
	'dist'		=>	{
		'COMPRESS'        =>	"gzip -9f",
		'SUFFIX'          =>	"gz",
		'POSTOP'          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	'PREREQ_PM' 	=> { 'Regexp::Ethiopic' => "0.15" },
	'LICENSE'	=> 'perl',
	'MIN_PERL_VERSION' => '5.6.1'
);
