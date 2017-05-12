use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "SyslogScan",
	DISTNAME => "SyslogScan",
	VERSION => "0.32",
#	EXE_FILES => [ qw( bin/read_mail_log.pl ) ],
#     'clean'       => { FILES => '$(EXE_FILES)' },
	dist => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
);
