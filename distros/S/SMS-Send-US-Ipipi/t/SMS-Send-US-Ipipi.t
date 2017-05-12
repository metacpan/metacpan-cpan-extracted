# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SMS-Send-Ipipi.t'

use Test::More;
use SMS::Send;

if ( exists $ENV{'IPIPI_LOGIN'} && $ENV{'IPIPI_DESTINATION'}) {
    plan tests => 2;
} else {
    plan skip_all => 'No login information available, skipping all tests.';
}

# Get the sender and login
my $sender = SMS::Send->new( 'US::Ipipi',
                             _login    => $ENV{'IPIPI_LOGIN'},
                             _password => $ENV{'IPIPI_PASSWORD'},
                        );

isa_ok( $sender, 'SMS::Send' );

my $sent = $sender->send_sms( text => 'Test of SMS::Send::US::Ipipi',
                              to   => $ENV{'IPIPI_DESTINATION'},
                         );

ok( $sent, 'message was sent' );



