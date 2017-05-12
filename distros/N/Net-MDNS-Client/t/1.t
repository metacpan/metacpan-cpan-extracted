# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 6;
use Net::MDNS::Client qw{:all};
BEGIN { use_ok('Net::MDNS::Client') };


my $fail = 0;
foreach my $constname (qw(
	MAX_STRING)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Net::MDNS::Client macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $q;

ok( $q = make_query("host by service", "", "local.", "perl", "tcp"), "Make query");
ok( query( "host by service", $q), "Start query");

ok (!process_network_events(), "Process network events");
ok (!get_a_result("host by service", $q), "Get a result");;
											       
