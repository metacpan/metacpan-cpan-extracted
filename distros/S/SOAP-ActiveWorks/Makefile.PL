
use Config;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'SOAP',
	DISTNAME	=> 'SOAP-ActiveWorks',
	VERSION 	=> '0.12',
	PREREQ_PM 	=> { 'SOAP' => 1, 'Aw' => 1 },
	dist		=>	{ 
		COMPRESS	=>	"gzip -9f",
		SUFFIX		=>	"gz",
		POSTOP		=>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	}
);
