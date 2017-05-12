#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok 'SMS::API::SMSC';

my $sms = new_ok 'SMS::API::SMSC', [login => 'login', password => 'password'];

done_testing;
