#!/usr/bin/perl

# Basic operational tests for SMS::AQL
# $Id$

use strict;
use Test::More tests => 4;

# NOTE - the test username and password is for testing SMS::AQL *only*,
# not to be used for any other purpose.  It is given a small amount of
# credit now and then, if you try to abuse it, it just won't get given
# any more credit.  So don't.
my $test_user = 'sms-aql-test';
my $test_pass = 'sms-aql-test';


use lib '../lib/';
use_ok('SMS::AQL');



ok(my $sender = new SMS::AQL({username => $test_user, password => $test_pass}), 
    'Create instance of SMS::AQL');
    
ok(ref $sender eq 'SMS::AQL', 
    '$sender is an instance of SMS::AQL');

my $balance = $sender->credit();

ok($balance =~ /^[0-9]+$/, 'got account balance');


=begin

TODO: refactor this bigtime!  I've disabled the sending test because I don't
want to demand the destination number here if it's an automated install


my $test_to;
if ($balance) {
    # have to send it to STDERR, as Test::Harness swallows our STDOUT...
    print STDERR qq[
To properly test SMS::AQL, I need a test number to send a text message to.
Please supply a mobile number, and I will try to send a text message to it.
If you'd rather not and wish to skip the tests, just leave it blank (or
enter any "non-true" value).

Mobile number: ?> ];

    $test_to = <>;
} else {
    print STDERR "Skipping sending test - test account has no credit left\n";
    $test_to = '';
}

# OK, a little crufty here with the double skip blocks, but we want
# to skip the sending test if the destination number isn't given, and 
# also if the result of the send attempt is out of credit, we want to
# skip rather than fail.
my ($ok, $why);
SKIP: {
    skip "No destination number given" unless $test_to;
    
    # now call in list context to check it definately worked:
    ($ok, $why) = $sender->send_sms($test_to, 'Test message from SMS::AQL ' .
                                    'test suite',
                                    { sender => 'SMS::AQL' });
    
    SKIP: {
        skip "No credit in testing account" if $why eq 'Out of credits';
        skip "Invalid destination entered"  if $why eq 'Invalid destination';
        is($why, 'OK', 'Test message sent OK');          
    }

}
    
=cut

