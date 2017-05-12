#!/usr/local/bin/perl5 -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok (cant load)" unless $loaded;}
use Net::Hesiod  qw(:resolve);

$loaded = 1;

######################### End of black magic.

#Now test that we can initialize and close a hesiod context

#Test the raw interface functions
my $context;

#1
my $res = hesiod_init($context);
if ( $res ) { print "not ok 1\n"; } else { print "ok 1\n"; }

#2
hesiod_end($context);
print "ok 2\n";

#Now do OO stuff

#3
my $hesobj = new Net::Hesiod;
if ( defined $hesobj ) { print "ok 3\n"; } else { print "not ok 3\n"; }

#4
undef $hesobj;
print "ok 4\n";
