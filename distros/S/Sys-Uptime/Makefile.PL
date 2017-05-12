#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Sys::Uptime',
	VERSION_FROM => "Uptime.pm",

	'dist'    => {COMPRESS => 'gzip -9f',
	SUFFIX   => '.gz',
	DIST_DEFAULT => 'all tardist',
	},
);
