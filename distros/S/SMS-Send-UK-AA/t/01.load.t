use strict;
use Test::More 0.87; # done_testing
use SMS::Send;

my %params = (_login => "testlogin", _password => "t3s+pass");

use_ok "SMS::Send::UK::AA";
new_ok "SMS::Send", ["UK::AA", %params];

eval {
  SMS::Send->new("UK::AA", _meh => 2);
};
like $@, qr/Unknown arguments: _meh/;

done_testing;
