#!perl -w
use strict;
if (my $child = fork()) {
    waitpid $child, 0;
    print "child exited with code ", $? >> 8, "\n";
}
else {
    print "I'm the child\n";
    exit 20;
}
