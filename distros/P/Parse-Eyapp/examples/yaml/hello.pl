#!/usr/bin/env perl -w
use strict;

# The only purpose of this file is to check a 'bug' in Groovy
# arguments aren't properly parsed in 'string.execute()'
# See program: thegroovyexecuteproblem.groovy

print "Hello world:\n";
my $i = 0;
for (@ARGV) {
 print ($i++.": $_\n");
}

