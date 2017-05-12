#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

use SMS::Matrix;

my $x = SMS::Matrix->new
(
 username => 'testuser',
 password => 'testpasswd',
);

ok $x->isa( 'SMS::Matrix' ), '$x is a SMS::Matrix';

my $resp = $x->get_balance();

ok $resp, 'send_sms() did return a true value';
ok $x->is_success(), 'Get Balance was successful';
