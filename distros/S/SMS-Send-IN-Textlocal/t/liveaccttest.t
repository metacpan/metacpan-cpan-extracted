# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl SMS-Send-IN-Textlocal.t'
 
#########################
#  Actual live test of sending transactional SMS via Textlocal
#  Requires paid account with at least one DLT approved message
#  template along with login credentials
 
use Test::More;
use SMS::Send;
 
if ( exists $ENV{'TL_SENDID'} && $ENV{'TL_DESTPH'}) {
    plan tests => 2;
} else {
    plan skip_all => 'No login information available, skipping all tests.';
}
 
# Get the sender and login
my $sender = SMS::Send->new( 'IN::Textlocal',
                             _login    => $ENV{'TL_SENDID'},
                             _password => $ENV{'TL_APIKEY'},
                        );
 
isa_ok( $sender, 'SMS::Send' );
 
my $sent = $sender->send_sms( text => $ENV{'TL_MSGTXT'},
                              to   => $ENV{'TL_DESTPH'},
                         );
 
ok( $sent, 'message was sent' );
