
use Config;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'SOAP',
	DISTNAME	=> 'SOAP-Lite-ActiveWorks',
	VERSION 	=> '0.10',
	PREREQ_PM 	=> { 'SOAP::Lite' => '0.44', 'Aw' => '0.13' },
	dist		=>	{ 
		COMPRESS	=>	"gzip -9f",
		SUFFIX		=>	"gz",
		POSTOP		=>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	}
);
