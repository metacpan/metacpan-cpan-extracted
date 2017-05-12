use 5.001000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::FTP::Versioning',
    'VERSION_FROM'	=> 'Versioning.pm', # finds $VERSION
    'PREREQ_PM'		=> {Net::FTP => 2.72}, 
    ($] >= 5.005 	?
		( 
		ABSTRACT_FROM => 'Versioning.pm', # retrieve abstract from module
		AUTHOR     => 'Bruno Negrao http://www.qmailwiki.org/User:Bnegrao'
		) 			: 	() 
	),
);
