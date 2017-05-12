# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 1;
#BEGIN { use_ok('Net::Radius::Client') };

use Test;
BEGIN { plan tests => 3 };
use Net::Radius::Client;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my ($code, $rsp) = query( {
    '127.0.0.1' => { 1812 => undef }
    }, "Access-Request", {
    0 => { 'User-Name' => ['anus'], 'User-Password' => ['vulgaris'] }
    } );
    
ok(1); # don't expect any response

my ($code, $rsp) = query( {
    '127.0.0.1' => { 1813 => undef }
    }, "Accounting-Request", {
    0 => { 'User-Name' => ['anus'] }
    } );
    
ok(1); # don't expect any response
