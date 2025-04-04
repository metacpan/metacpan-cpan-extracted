#!/usr/bin/perl

# Basic operational tests for SMS::AQL
# $Id$

use strict;
use Test::More tests => 3;

# This test account used to exist for testing interactions with AQL's API,
# but as of around March 2025 it appears not to exist any more.  We mock
# our interactions with their API in t/4-mock.t anyway, so it will only
# affect us if/when we need to regenerate mocks.
# (This test script used to test a live "check balance" call using that
# account, but no longer does - see GH #4)
my $test_user = 'sms-aql-test';
my $test_pass = 'sms-aql-test';


use lib '../lib/';
use_ok('SMS::AQL');



ok(my $sender = new SMS::AQL({username => $test_user, password => $test_pass}), 
    'Create instance of SMS::AQL');
    
ok(ref $sender eq 'SMS::AQL', 
    '$sender is an instance of SMS::AQL');

