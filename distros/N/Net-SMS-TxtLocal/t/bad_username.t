use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use Net::SMS::TxtLocal;

# check that no details dies
dies_ok    #
  sub { Net::SMS::TxtLocal->new(); },    #
  "dies with no username or password";
dies_ok                                  #
  sub { Net::SMS::TxtLocal->new( uname => 'foo' ); },    #
  "dies with no username";
dies_ok                                                  #
  sub { Net::SMS::TxtLocal->new( pword => 'bar' ); },    #
  "dies with no password";

# create an object with bad username and passwords
my $txtlocal = Net::SMS::TxtLocal->new(
    uname => 'bad_uname_for_testing',
    pword => 'bad_pword_for_testing'
);
ok $txtlocal, "created an object";

# try to get the credit level
throws_ok                                                #
  sub { $txtlocal->get_credit_balance },                 #
  qr{Invalid login},                                     #
  "died trying to get credit balance";

# try to get the credit level and check that it dies with a helpful message
# about bad user/pass.
throws_ok                                                #
  sub {
    $txtlocal->send_message(
        {
            message => "This is a test message",
            to      => ['447903420689'],
        }
    );
  },                                                     #
  qr{Error with request},                                #
  "died trying to send a message";
