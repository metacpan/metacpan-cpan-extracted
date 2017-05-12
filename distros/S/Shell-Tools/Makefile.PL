#!/usr/bin/env perl
use ExtUtils::MakeMaker 6.52;  # need >=6.52 for CONFIGURE_REQUIRES
# and in CONFIGURE_REQUIRES, we require >=6.64 for TEST_REQUIRES
WriteMakefile(
	NAME           => 'Shell::Tools',
	AUTHOR         => 'Hauke D <haukex@zero-g.net>',
	LICENSE        => 'perl',
	VERSION_FROM   => 'lib/Shell/Tools.pm', # finds $VERSION
	ABSTRACT_FROM  => 'lib/Shell/Tools.pm',
	MIN_PERL_VERSION => '5.8.0',
	META_MERGE     => {
		'meta-spec'  => { version => 2 },
		resources    => {
			homepage    => 'https://github.com/haukex/Shell-Tools',
			repository  => {
				type       => 'git',
				url        => 'https://github.com/haukex/Shell-Tools.git',
				web        => 'https://github.com/haukex/Shell-Tools',
			},
			bugtracker  => {
				web        => 'https://github.com/haukex/Shell-Tools/issues',
				#mailto     => '',
			},
		},
		prereqs      => {
			runtime    => {
				recommends => { # "strongly encouraged and should be satisfied except in resource constrained environments"
					# CPAN
					'Try::Tiny'         => 0,
					'Path::Class'       => 0,
					'File::pushd'       => 0,
					'File::Find::Rule'  => 0,
					'IPC::Run3::Shell'  => '0.52',
				},
				suggests   => { # "optional, but are suggested for enhanced operation"
				},
			},
		},
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'    => '6.64',
	},
	PREREQ_PM      => {
		# Perl core modules
		'base'                   => 0,
		'Exporter'               => 0,
		'IO::File'               => 0,
		'IO::Handle'             => 0,
		'Carp'                   => 0,
		'Getopt::Std'            => '1.04',
		'Pod::Usage'             => 0,
		'Cwd'                    => 0,
		'File::Spec::Functions'  => 0,
		'File::Basename'         => 0,
		'File::Temp'             => 0,
		'File::Copy'             => 0,
		'File::Path'             => '2.08',
		'File::Find'             => 0,
		'Fcntl'                  => 0,
		'FindBin'                => 0,
		'Data::Dumper'           => 0,
		'Scalar::Util'           => 0,
		'List::Util'             => 0,
	},
	TEST_REQUIRES  => {
		# CPAN
		'Capture::Tiny'          => 0,
		# Perl core modules
		'Test::More'             => 0,
		'Config'                 => 0,
		# excluding any modules for author tests
	},
);
