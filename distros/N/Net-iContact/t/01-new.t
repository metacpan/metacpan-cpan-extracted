#!perl -T
use strict;

use Test::More tests => 3;
use Net::iContact;

### This should work..
my $api = Net::iContact->new('user', 'pass', 'key', 'secret');
ok(ref($api) eq "Net::iContact", 'create API object');

### Some basic accessors
ok($api->username eq 'user', 'get_user');
ok($api->password eq '1a1dc91c907325c69271ddf0c944bc72', 'get_pass');
