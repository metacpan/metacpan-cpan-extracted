# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl SMS-Send-IN-Unicel.t'

#########################
#  Actual live test of sending transactional SMS via Unicel
#  Requires paid account with at least one approved message
#  template along with login credentials

use Test::More;
use SMS::Send;

if ( exists $ENV{'UNICEL_LOGIN'} && $ENV{'UNICEL_DESTP'}) {
    plan tests => 2;
} else {
    plan skip_all => 'No login information available, skipping all tests.';
}

# Get the sender and login
my $sender = SMS::Send->new( 'IN::Unicel',
                             _login    => $ENV{'UNICEL_LOGIN'},
                             _password => $ENV{'UNICEL_PASSW'},
                        );

isa_ok( $sender, 'SMS::Send' );

my $sent = $sender->send_sms( text => $ENV{'UNICEL_MSGTP'},
                              to   => $ENV{'UNICEL_DESTP'},
                         );

ok( $sent, 'message was sent' );



