#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

use SMS::Matrix;

my $x = SMS::Matrix->new
(
 username => 'testuser',
 password => 'wrongpasswd',
);

ok $x->isa( 'SMS::Matrix' ), '$x is a SMS::Matrix';

my $resp = $x->send_tts
(
 txt     => 'This is a negative test',
 phone   => '13175581325',
 language => 'en',
 gender => 'male',
);

ok $resp, 'send_sms() did return a true value';
is $x->errstr(), 'ERROR INVALID PASSWORD OR USERNAME', 'Check error string';
