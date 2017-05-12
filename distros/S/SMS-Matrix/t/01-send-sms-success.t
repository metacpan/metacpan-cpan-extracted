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

my $resp = $x->send_sms
(
 txt     => 'This is a test',
 phone   => '13475511325',
);

ok $resp, 'send_sms() did return a true value';
ok $x->is_success(), 'Send SMS was successful';
