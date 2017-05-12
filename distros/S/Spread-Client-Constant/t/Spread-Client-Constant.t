# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Spread-Client-Constant.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Spread::Client::Constant;
ok(1); # If we made it this far, we're ok.


my $fail;
foreach my $constname (qw(
	ACCEPT_SESSION AGREED_MESS BUFFER_TOO_SHORT CAUSAL_MESS
	CAUSED_BY_DISCONNECT CAUSED_BY_JOIN CAUSED_BY_LEAVE CAUSED_BY_NETWORK
	CONNECTION_CLOSED COULD_NOT_CONNECT DEFAULT_SPREAD_PORT DROP_RECV
	ENDIAN_RESERVED FIFO_MESS GROUPS_TOO_SHORT HIGH_PRIORITY ILLEGAL_GROUP
	ILLEGAL_MESSAGE ILLEGAL_SERVICE ILLEGAL_SESSION ILLEGAL_SPREAD
	LOW_PRIORITY MAX_CLIENT_SCATTER_ELEMENTS MAX_GROUP_NAME
	MAX_PRIVATE_NAME MAX_PROC_NAME MEDIUM_PRIORITY MEMBERSHIP_MESS
	MESSAGE_TOO_LONG NET_ERROR_ON_SESSION REGULAR_MESS REG_MEMB_MESS
	REJECT_AUTH REJECT_ILLEGAL_NAME REJECT_MESS REJECT_NOT_UNIQUE
	REJECT_NO_NAME REJECT_QUOTA REJECT_VERSION RELIABLE_MESS RESERVED
	SAFE_MESS SELF_DISCARD SPREAD_VERSION TRANSITION_MESS UNRELIABLE_MESS
	)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Spread::Client::Constant macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }
}
if ($fail) {
  print "not ok 2\n";
} else {
  print "ok 2\n";
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

