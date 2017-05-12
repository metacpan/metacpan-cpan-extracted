#!perl -T

use strict;
use warnings;

use Test::More tests => 3;

use Nexmo::SMS::MockLWP;
use Nexmo::SMS;

my $nexmo = Nexmo::SMS->new(
    server   => 'http://rest.nexmo.com/sms/json',
    username => 'testuser',
    password => 'testpasswd',
);

ok( $nexmo->isa( 'Nexmo::SMS' ), '$nexmo is a Nexmo::SMS' );

my $sms = $nexmo->sms(
    text => 'This is a test',
    from => 'Test03',
    to   => 'asdfasdf',
);

ok $sms->isa( 'Nexmo::SMS::TextMessage' ), '$sms is a Nexmo::SMS::TextMessage';

my $response = $sms->send;

is $sms->errstr, 'Invalid credentials (The username / password you supplied is either invalid or disabled)', 'Check error string';