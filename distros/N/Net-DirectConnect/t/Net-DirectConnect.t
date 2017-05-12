# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-DirectConnect.t'
#########################
# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);


BEGIN {
  use_ok('Net::DirectConnect');
  use_ok('Net::DirectConnect::nmdc');
  use_ok('Net::DirectConnect::clihub');
  use_ok('Net::DirectConnect::clicli');
  use_ok('Net::DirectConnect::adc');
  use_ok('Net::DirectConnect::filelist');

  use_ok('Net::DirectConnect::hub');
  use_ok('Net::DirectConnect::hubcli');
  use_ok('Net::DirectConnect::hubhub');

}
#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
