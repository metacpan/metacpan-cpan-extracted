## -*- Perl -*-
use ExtUtils::MakeMaker qw(WriteMakefile);
WriteMakefile( 
	       NAME           => "TFTP",
	       DISTNAME       => "TFTP",
	       VERSION_FROM   => "TFTP.pm",
	       dist           => { COMPRESS => "gzip", SUFFIX => "gz" },
	       );
