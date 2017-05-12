
use Config;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'SOAP',
	DISTNAME	=> 'SOAP-AutoInvoke',
	VERSION 	=> '0.25',
	PREREQ_PM 	=> { 'SOAP' => 1, 'Data::Dumper' => 1 },
	dist		=>	{ 
		COMPRESS	=>	"gzip -9f",
		SUFFIX		=>	"gz",
		POSTOP		=>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	}
);
