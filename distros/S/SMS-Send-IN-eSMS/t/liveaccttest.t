# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl SMS-Send-IN-eSMS.t'

#########################
#  Actual live test of sending transactional SMS via eSMS
#  Requires paid account with at least one approved message
#  template along with login credentials

use Test::More;
use SMS::Send;

if ( exists $ENV{'eSMS_LOGIN'} && $ENV{'eSMS_DESTP'}) {
    plan tests => 2;
} else {
    plan skip_all => 'No login information available, skipping all tests.';
}

# Get the sender and login
my $sender = SMS::Send->new( 'IN::eSMS',
                             _login    => $ENV{'eSMS_LOGIN'},
                             _password => $ENV{'eSMS_PASSW'},
                             _senderid => $ENV{'eSMS_SENDR'},
                        );

isa_ok( $sender, 'SMS::Send' );

my $sent = $sender->send_sms( text => $ENV{'eSMS_MSGTP'},
                              to   => $ENV{'eSMS_DESTP'},
                         );

ok($sent, 'message was sent');
