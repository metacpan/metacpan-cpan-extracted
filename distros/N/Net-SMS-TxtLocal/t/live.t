use strict;
use warnings;

use Test::More;
use Net::SMS::TxtLocal;

plan skip_all =>
  "Set the 'NET_SMS_TEST_UNAME', 'NET_SMS_TEST_PWORD' and 'NET_SMS_TEST_NUMBER'"
  . " env variables to run live tests"
  unless $ENV{NET_SMS_TEST_UNAME}
      && $ENV{NET_SMS_TEST_PWORD}
      && $ENV{NET_SMS_TEST_NUMBER};

plan tests => 4;

# create the object
my $txtlocal = Net::SMS::TxtLocal->new(
    uname => $ENV{NET_SMS_TEST_UNAME},
    pword => $ENV{NET_SMS_TEST_PWORD},
    from  => 'TxtLocal',
);
ok $txtlocal, "created txtlocal object";

# get the current balance
my $balance = $txtlocal->get_credit_balance();
ok $balance, "got your current balance: '$balance'";

# send a message
ok $txtlocal->send_message(
    {
        message => "This is a test message from Net::SMS::TxtLocal",
        to      => [ $ENV{NET_SMS_TEST_NUMBER} ],
    }
  ),
  "sent test message";

# get the new balance
my $new_balance = $txtlocal->get_credit_balance();
is $new_balance, $balance - 1,
  "balance has gone down one: from $balance to $new_balance";
