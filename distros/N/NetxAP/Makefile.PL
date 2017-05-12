#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME     => 'Net',
	      VERSION  => '0.02',
	      DISTNAME => 'NetxAP',
	      PREREQ_PM => { MIME::Base64 => 2.11,
			     MD5 => 2.01,
			   },
	      'dist'   => { COMPRESS => 'gzip', SUFFIX => '.gz' },
);
