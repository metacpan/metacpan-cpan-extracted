use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
	NAME          => 'Sub::IsEqual',
	AUTHOR        => q{Aaron Cohen <aaarondcohen@gmail.com>},
	VERSION_FROM  => 'lib/Sub/IsEqual.pm',
	ABSTRACT_FROM => 'lib/Sub/IsEqual.pm',
	LICENSE       => 'perl',
	META_MERGE => {
		resources => {
			homepage   => 'http://github.com/aarondcohen/perl-sub-isequal',
			repository => 'git://github.com/aarondcohen/perl-sub-isequal.git',
			bugtracker => 'http://github.com/aarondcohen/perl-sub-isequal/issues',
		},
	},
);
