
use Test::More tests => 13;
use MIME::Base64;
do "t/config" or die $@;
die "configuration failure" unless  defined $dhcpCONFIG{host};
use Net::DHCP::Control;
ok(1, "Partial credit for showing up");

Net::DHCP::Control::initialize();
ok(1, "initialize");

my $auth =
  Net::DHCP::Control::new_authenticator(@dhcpCONFIG{'keyname', 'keytype', 'key'});
ok($auth, "authenticator created");

my $handle = 
  Net::DHCP::Control::connect($dhcpCONFIG{host}, 7911, $auth);
ok($handle, "handle connected");
warn $handle ? "# <<$handle>>\n" : "<<<$Net::DHCP::Control::STATUS>>>\n";


# These test various sorts of connection failures
{ my $fakehandle;

 SKIP: {
    skip  "This test causes OMAPI library to dump core", 1;
    $fakehandle = Net::DHCP::Control::connect('nosuchhost', 7911, $auth);
    ok(! defined $fakehandle, "bad host connect");
  }

  $fakehandle = Net::DHCP::Control::connect($dhcpCONFIG{host}, 119, $auth);
  ok(! defined $fakehandle, "bad port connect");

  SKIP: { 
    skip("noc-2003-dmr doesn't seem to require authentication", 1);
    $fakehandle = Net::DHCP::Control::connect($dhcpCONFIG{host}, 7911);
    ok(! defined $fakehandle, "no auth connect");
  }

 SKIP: {
    skip("Bad authentication keys are not diagnosed immediately.", 1);
    my $badauth =
      Net::DHCP::Control::new_authenticator(@dhcpCONFIG{'keyname', 'keytype'},
				 $dhcpCONFIG{'key'}."carrots",
				);

    $fakehandle = Net::DHCP::Control::connect($dhcpCONFIG{host}, 7911, $badauth);
    ok(!	 defined $fakehandle, "bad auth connect");
  }
}

my $object = Net::DHCP::Control::new_object($handle, "failover-state");
ok($object, "failover-state object created");
print "# <<$object>>\n";

my $result;
$result = Net::DHCP::Control::set_value($object, "name", $dhcpCONFIG{'failover-name'});
printf("# set_value: %s\n", $Net::DHCP::Control::STATUS) unless $result;
ok($result, "set name value");

$result = Net::DHCP::Control::open_object($object, $handle);
printf("# obj open: %s\n", $Net::DHCP::Control::STATUS) unless $result;
ok($result, "object opened");

$result = Net::DHCP::Control::wait_for_completion($object);
printf("# wait: %s\n", $Net::DHCP::Control::STATUS) unless $result;
ok($result, "waited for completion");

my $value = Net::DHCP::Control::get_value($object, "local-state");
printf("# local-state value: %d\n", $value);
print "# get value: $Net::DHCP::Control::STATUS" unless defined $value;
is($value, 2, "got value");  # '2' means 'normal'

