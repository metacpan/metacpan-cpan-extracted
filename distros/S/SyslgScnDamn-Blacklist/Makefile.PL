
require 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'SyslogScan::Daemon::BlacklistDetector',
	DISTNAME	=> 'SyslgScnDamn-Blacklist',
	VERSION_FROM	=> 'lib/SyslogScan/Daemon/BlacklistDetector.pm',
	dist		=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
	PREREQ_PM	=> {
		'Mail::SendVarious'	=> 0,
		'SyslogScan::Daemon'	=> 0,
	},
);

package MY;

sub postamble {
    <<'END_OF_POSTAMBLE';

pm_to_blib: README

README: lib/SyslogScan/Daemon/BlacklistDetector.pod
	pod2text  lib/SyslogScan/Daemon/BlacklistDetector.pod > README

END_OF_POSTAMBLE
}
