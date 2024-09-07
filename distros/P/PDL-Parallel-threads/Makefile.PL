use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'PDL::Parallel::threads',
	VERSION_FROM => 'lib/PDL/Parallel/threads.pm',
	LICENSE  => 'perl',
	MIN_PERL_VERSION => '5.14.0',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '7.14',
	},
	PREREQ_PM => {
		'PDL'             => '2.091', # new_around_datasv etc
		'threads::shared' => '1.21',  # shared_clone
	},
	TEST_REQUIRES => {
		'Test::Warn' => 0,
		'Test::Exception' => 0,
	},
	META_MERGE => {
		"meta-spec" => { version => 2 },
		resources => {
			repository => {
				web => 'http://github.com/PDLPorters/PDL-Parallel-threads',
				url => 'git://github.com/PDLPorters/PDL-Parallel-threads.git',
				type => 'git',
			},
			bugtracker => {
				web => 'http://github.com/PDLPorters/PDL-Parallel-threads/issues',
			},
		},
		no_index => {
			file => ['README.pod'],
			directory => [qw(examples t)],
		},
	},
);
