require 5.002;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME     => 'No',
	VERSION  => '1.08',
	DISTNAME => 'Norge',
 	dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
