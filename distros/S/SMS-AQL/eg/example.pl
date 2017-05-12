#!/usr/bin/perl

# $Id$

# Simple usage example for SMS::AQL

# NOTE - the test username and password is for testing SMS::AQL *only*,
# not to be used for any other purpose.  It is given a small amount of
# credit now and then, if you try to abuse it, it just won't get given
# any more credit.  So don't.
my $test_user = 'sms-aql-test';
my $test_pass = 'sms-aql-test';

use warnings;
use lib '../lib/';
use SMS::AQL;

my $sender = new SMS::AQL({username => $test_user, password => $test_pass});

if (!$sender || ! ref $sender) { die('Failed to instantiate SMS::AQL'); }


print "SMS::AQL $SMS::AQL::VERSION loaded OK\n";

my $credits = $sender->credit();

print "Account $test_user has $credits credits.\n";

print "Destination: ?> ";
my $test_to = <>;

print "Message: ?> ";
my $message = <>;

my ($ok, $why) = $sender->send_sms($test_to, $message, 
                                   { sender => 'SMS-AQL' });

printf "Status: %s,  Reason: %s, Server response: %s\n", 
    ($ok? 'Successful' : 'Failed'), 
    $why,
    $sender->{last_response};


# note: we could also have specified the sender when we created an instance of
# SMS::AQL, to save passing it to the send_sms() call - see the POD docs.
