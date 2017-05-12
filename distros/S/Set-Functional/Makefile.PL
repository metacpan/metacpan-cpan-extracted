use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Set::Functional',
	AUTHOR              => q{Aaron Cohen <aarondcohen@gmail.com>},
	VERSION_FROM        => 'lib/Set/Functional.pm',
	ABSTRACT_FROM       => 'lib/Set/Functional.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES            => {},
	PREREQ_PM => {
			'Test::More' => 0,
	},
	META_MERGE => {
		resources => {
			homepage => 'http://github.com/aarondcohen/Set-Functional',
			repository => 'git://github.com/aarondcohen/Set-Functional.git',
			bugtracker => 'http://github.com/aarondcohen/Set-Functional/issues',
		}
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Set-Functional-*' },
);
