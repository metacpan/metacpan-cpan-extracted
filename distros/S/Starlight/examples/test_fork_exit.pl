#!perl

# should print "outer1"
$s='outer'; { local $s; exit if fork } print $s, defined($s);
