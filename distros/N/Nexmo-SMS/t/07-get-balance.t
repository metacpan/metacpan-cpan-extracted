#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

use Nexmo::SMS::MockLWP;
use Nexmo::SMS;

my $nexmo = Nexmo::SMS->new(
    server   => 'http://rest.nexmo.com/sms/json',
    username => 'testuser',
    password => 'testpasswd',
);

ok( $nexmo->isa( 'Nexmo::SMS' ), '$nexmo is a Nexmo::SMS' );

my $value = $nexmo->get_balance() or diag $nexmo->errstr;
is $value, 4.15, 'Balance is 4.15';