#!/usr/bin/perl
# Simple DHCP client - sending a broadcasted DHCP Discover request

use IO::Socket::INET;
use Net::DHCP::Packet;
use Net::DHCP::Constants;

use POSIX qw(setsid strftime);

# sample logger
sub logger {
    my $str = shift;
    print STDOUT strftime "[%d/%b/%Y:%H:%M:%S] ", localtime;
    print STDOUT "$str\n";
}

logger("DHCPd tester - dummy client");

logger("Opening socket");
$handle = IO::Socket::INET->new(
    Proto     => 'udp',
    Broadcast => 1,
    PeerPort  => '67',
    LocalPort => '68',
    PeerAddr  => '127.0.0.1'
) || die "Socket creation error: $@\n";    # yes, it uses $@ here

# create DHCP Packet DISCOVER
$discover = Net::DHCP::Packet->new(
    Xid                           => 0x12345678,
    DHO_DHCP_MESSAGE_TYPE()       => DHCPDISCOVER(),
    DHO_VENDOR_CLASS_IDENTIFIER() => 'foo',
);

logger("Sending DISCOVER to 127.0.0.1:67");
logger( $discover->toString() );
$handle->send( $discover->serialize() )
  or die "Error sending:$!\n";

logger("Waiting for response from server");
$handle->recv( $buf, 4096 ) || die("recv:$!");
logger("Got response");
$response = Net::DHCP::Packet->new($buf);
logger( $response->toString() );

# create DHCP Packet REQUEST
$request = Net::DHCP::Packet->new(
    Xid                           => 0x12345678,
    Ciaddr                        => $response->yiaddr(),
    DHO_DHCP_MESSAGE_TYPE()       => DHCPREQUEST(),
    DHO_VENDOR_CLASS_IDENTIFIER() => 'foo',
    DHO_DHCP_REQUESTED_ADDRESS()  => $response->yiaddr(),
);

logger("Sending REQUEST to 127.0.0.1:67");
logger( $request->toString() );

$handle->send( $request->serialize() )
  or die "Error sending:$!\n";
logger("Waiting for response from server");
$handle->recv( $buf, 4096 ) || die("recv:$!");
logger("Got response");
$response = Net::DHCP::Packet->new($buf);
logger( $response->toString() );
