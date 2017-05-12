
use blib;
do "t/config" or die $@;
die "configuration failure" unless  defined $dhcpCONFIG{host};
use Net::DHCP::Control::Failover 'failover_statename';
use Net::DHCP::Control '$STATUS';
use MIME::Base64;
# use Test::More skip_all => "Callbacks don't work";
use Test::More tests => 6;

ok(1, "Partial credit for showing up");


my %auth = (key_name => $dhcpCONFIG{keyname},
	    key_type => $dhcpCONFIG{keytype},
	    key => $dhcpCONFIG{key},
	   );

my $host = $dhcpCONFIG{host};
my $name = $dhcpCONFIG{'failover-name'};
my $ZZZ = 5;

my $CALLBACK_OK = 0;
sub callback {
  my ($object, $remote_status, $data) = @_;
  print "In callback\n";
  warn "In callback\n";
  ok(Net::DHCP::Control::is_success($remote_status), "remote status in callback");
  is($object, $data->{object}, "object in callback");
  is($data->{number}, 119, "data value in callback");
  $CALLBACK_OK = $data->{number};
}

#
# Test raw Net::DHCP::Control interface 
#

TEST: {
  my $authenticator = Net::DHCP::Control::new_authenticator($dhcpCONFIG{keyname},
						 $dhcpCONFIG{keytype},
						 $dhcpCONFIG{key},
						 )
    or last;
  print "Made authenticator.\n";
  my $handle = Net::DHCP::Control::connect($host, Net::DHCP::Control::DHCP_PORT, $authenticator) 
    or last;
  print "Made connection handle.\n";
  my $object = Net::DHCP::Control::new_object($handle, 'failover-state') or last;

  print "Made object.\n";

  Net::DHCP::Control::set_value($object, "failover-name", "dhcp.net.isc.upenn.edu")
    or last;
        
  print "Set failover state.\n";

  my $res  = Net::DHCP::Control::set_callback($object, \&callback, 
                                   {object => $object, number => 119}
                                  ) ;

  print "Set callback says $res ($Net::DHCP::Control::STATUS)\n";
  last unless $res;

  Net::DHCP::Control::open_object($object, $handle) or last;
  print "Opened object.\n";
}
is($CALLBACK_OK, 119, "callback invoked (raw) [$STATUS]");



