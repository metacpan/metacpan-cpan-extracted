use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'SMB',
	DISTNAME => 'SMB',
	dist => {
		COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		# default CP 'ln' is buggy, it changes source file permissions
		DIST_CP => 'cp',
	},
	EXE_FILES => [ glob("bin/smb-*") ],
	VERSION_FROM => 'lib/SMB.pm',
	ABSTRACT_FROM => 'lib/SMB.pm',
	AUTHOR => 'Mikhael Goikhman <migo@cpan.org>',
	LICENSE => 'gpl',
	MIN_PERL_VERSION => 5.010,  # mainly to use '//'
	PREREQ_PM => {
		# usually distributed with perl
		'Exporter' => 0,
		'Fcntl' => 0,
		'File::Basename' => 0,
		'File::Glob' => 0,
		'IO::Select' => 0,
		'IO::Socket' => 0,
		'POSIX' => 0,
		'Sys::Hostname' => 0,
		# less standard
		'Time::HiRes' => 0,
	},
);
