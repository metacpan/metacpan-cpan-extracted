
require 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'SyslogScan::Daemon::SpamDetector',
	DISTNAME	=> 'SyslogScan-Daemon-SpamDetector',
	VERSION_FROM	=> 'lib/SyslogScan/Daemon/SpamDetector.pm',
	dist		=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
	PREREQ_PM	=> {
		'SyslogScan::Daemon'	=> 0,
		'Net::Netmask'		=> 0,
		'Tie::Cache::LRU'	=> 0,
	},
);

package MY;

sub postamble {
    <<'END_OF_POSTAMBLE';

pm_to_blib: README 

README: lib/SyslogScan/Daemon/SpamDetector.pm
	pod2text  lib/SyslogScan/Daemon/SpamDetector.pm >README

END_OF_POSTAMBLE
}
