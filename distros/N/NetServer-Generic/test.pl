#!/usr/bin/perl

# stage 1 - ordinary forking server
$rc = system("$^X -Iblib/lib testguts-fork.pl");
if ($rc == 15) {
    print "ok 6\n"; # the quit() method worked -- exit via signal 15
} else {
    print "not ok 6: $rc\n";
}
 # stage 2 - pre-forked server  
$rc = system("$^X -Iblib/lib testguts-prefork.pl");
print "13..13\n";
if ($rc == 15) {
    print "ok 13\n"; # the quit() method worked -- exit via signal 15
} else {
    print "not ok 13: $rc\n";
}
sleep 5;
exit 0;
