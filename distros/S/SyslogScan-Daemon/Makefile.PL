
require 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'SyslogScan::Daemon',
	DISTNAME	=> 'SyslogScan-Daemon',
	VERSION_FROM	=> 'lib/SyslogScan/Daemon.pm',
	EXE_FILES	=> [ 'syslogscand' ],
	dist		=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
	PREREQ_PM	=> {
		'Daemon::Generic'	=> 0,
		'Plugins'		=> 0,
		'Sys::Hostname'		=> 0,
		'Mail::SendVarious'	=> 0,
	},
);


package MY;

sub postamble {
    <<'END_OF_POSTAMBLE';

pm_to_blib: README

README: lib/SyslogScan/Daemon.pod
	pod2text lib/SyslogScan/Daemon.pod >README

#syslogscand: syslogscand.pl
#	grep -v II::Develop syslogscand.pl > syslogscand
#	chmod +x syslogscand

clean::
	$(RM) syslogscand README

END_OF_POSTAMBLE
}
