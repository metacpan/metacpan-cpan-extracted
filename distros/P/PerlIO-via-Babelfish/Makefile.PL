# $Id: Makefile.PL,v 1.2 2003/09/03 15:11:03 cvspub Exp $
use ExtUtils::MakeMaker;


WriteMakefile(
	      'NAME'		=> 'PerlIO::via::Babelfish',
	      'VERSION_FROM'	=> 'Babelfish.pm', 
	      'PREREQ_PM'		=> {
		  'WWW::Babelfish' => '0.1',
	      }, 
	      ($] >= 5.005 ?    
	       (ABSTRACT_FROM => 'Babelfish.pm', 
		AUTHOR     => 'xern <xern@cpan.org>') : ()),
	      );
