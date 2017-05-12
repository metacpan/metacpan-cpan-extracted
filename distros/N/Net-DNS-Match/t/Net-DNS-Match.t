# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-DNS-Match.t'

#########################

# change 'tests => ' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Net::DNS::Match') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $obj = Net::DNS::Match->new();
ok(defined($obj));
ok($obj->isa('Net::DNS::Match'));

$obj->add([
	'yahoo.com',
    'aol.com',
    't.co',
    'example.co.uk',
    'test.aol.com',
]);
ok($obj->match('yahoo.com') eq 'yahoo.com');
ok($obj->match('abc.yahoo.com') eq 'yahoo.com');
ok($obj->match('co.uk') == 0);
ok($obj->match('t1.example.co.uk') eq 'example.co.uk');
ok($obj->match('t1.t.co') eq 't.co');
ok($obj->match('1.co') == 0);
ok($obj->match('1.3.4.example.t.co') eq 't.co');

done_testing();
