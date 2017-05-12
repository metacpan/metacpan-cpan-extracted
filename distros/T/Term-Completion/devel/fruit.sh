#!/bin/sh
perl -Mblib -MTerm::Completion=Complete -e 'print "Result=",Complete("Fruit: ",qw(Apple Banana Cherry Coconut Duriam)),"\n";'
