use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Sys::Config::Manage',
	AUTHOR              => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM        => 'lib/Sys/Config/Manage.pm',
	ABSTRACT_FROM       => 'lib/Sys/Config/Manage.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
	 ? ('LICENSE'=> 'perl')
	 : ()),
	PL_FILES            => {},
			  INST_SCRIPT => 'bin',
	PREREQ_PM => {
		'Test::More' => 0,
		'Sys::Hostname'=>0,
		'File::Copy'=>0,
		'File::Find'=>0,
		'File::Basename'=>0,
		'File::Path'=>0,
		'Cwd'=>0,
		'String::ShellQuote'=>0,
		'Error::Helper'=>0,
		'File::Spec'=>0,
		'Term::CallEditor'=>0,
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Sys-Config-Manage-*' },
	);
