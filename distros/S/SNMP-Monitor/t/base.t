# -*- perl -*-

$| = 1;

print "1..5\n";

$testNum = 0;

foreach $module (qw(SNMP::Monitor SNMP::Monitor::Install
		    SNMP::Monitor::Event::IfStatus
		    SNMP::Monitor::Event::IfLoad
		    SNMP::Monitor::EP)) {
    $@ = '';
    eval "require $module";
    if ($@) {
	print "not ok ", ++$testNum, "\n$@\n";
    } else {
	print "ok ", ++$testNum, "\n";
    }
}
