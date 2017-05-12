
use Config;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'SOAP',
	DISTNAME	=> 'SOAP-Lite-SmartProxy',
	VERSION 	=> '0.11',
	PREREQ_PM 	=> { 'SOAP::Lite' => '0.46' },
	dist		=>	{ 
		COMPRESS	=>	"gzip -9f",
		SUFFIX		=>	"gz",
		POSTOP		=>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
   ($] ge '5.005')
    ? (
     'AUTHOR' => 'Daniel Yacob (Yacob@RCN.Com)',
     'ABSTRACT' => 'URI Redirection and Forwarding for SOAP-Lite.',
    )
    : (),
);
