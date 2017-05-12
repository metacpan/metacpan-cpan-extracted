use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
warn <<'WARN';

This module is now *deprecared*
See NetAddr::IP::Find instead.

WARN
    ;

sleep 3;

WriteMakefile(
    'NAME'	=> 'Net::IPAddr::Find',
    'VERSION_FROM' => 'lib/Net/IPAddr/Find.pm', # finds $VERSION
    'PREREQ_PM' => {
	'NetAddr::IP' => 0,
	'NetAddr::IP::Find' => 0,
    },
);
