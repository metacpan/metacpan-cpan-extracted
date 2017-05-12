# -*- perl -*-

require 5.008;
use strict;
require ExtUtils::MakeMaker;

eval { require 5.008 } or die << 'EOD';
#######################################
#	This module requires a minimum Perl version of 5.008
#	Please upgrade!
#######################################
EOD

ExtUtils::MakeMaker::WriteMakefile(
	'NAME' => 'Net::NTPTime',
	'VERSION_FROM' => 'lib/Net/NTPTime.pm',
	'dist'         => { 
	 			'DIST_DEFAULT' => 'all tardist',
     				'SUFFIX'       => 'gz',
	 			'COMPRESS'     => 'gzip -9vf' 
	 },
   	'AUTHOR' => 'phatWares, USA (phantomsea2005@yahoo.com)',
   	'ABSTRACT' => 'Returns time as UNIX or NTP timestamp (unsigned integer)',
   	'PREREQ_PM' => {
   		'Socket' => '0.0'
   	}
);
