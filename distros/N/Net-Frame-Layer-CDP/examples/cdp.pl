use strict;
use warnings;

use Net::Frame::Layer::ETH;
use Net::Frame::Layer::LLC;
use Net::Frame::Layer::LLC::SNAP;
use Net::Frame::Layer::CDP qw(:consts);
use Net::Frame::Simple;

my $ether = Net::Frame::Layer::ETH->new(dst=>NF_CDP_MAC,type=>1);
my $llc   = Net::Frame::Layer::LLC->new(ig=>0,cr=>0);
my $snap  = Net::Frame::Layer::LLC::SNAP->new;
my $cdp   = Net::Frame::Layer::CDP->new;

my $cdp_device  = Net::Frame::Layer::CDP::DeviceId->new(deviceId=>'R2');

my $cdp_addr1   = Net::Frame::Layer::CDP::Address->new(address=>'192.168.100.1');
my $cdp_addr2   = Net::Frame::Layer::CDP::Address->ipv6Address(protocol=>pack('H*', 'aaaa0300000086dd'),address=>'2001:db8:192:168::1');
my $cdp_addr3   = Net::Frame::Layer::CDP::Address->ipv6Address(address=>'fe80::c800:1dff:fe4c:38');
my $cdp_address = Net::Frame::Layer::CDP::Addresses->new(addresses=>[$cdp_addr1, $cdp_addr2, $cdp_addr3]);

my $cdp_iface   = Net::Frame::Layer::CDP::PortId->new;
my $cdp_capabil = Net::Frame::Layer::CDP::Capabilities->new(capabilities=>0x29);
my $cdp_softver = Net::Frame::Layer::CDP::SoftwareVersion->new(softwareVersion=>'Cisco IOS Software, 3700 Software (C3725-ADVIPSERVICESK9-M), Version 12.4(15)T14, RELEASE SOFTWARE (fc2)
Technical Support: http://www.cisco.com/techsupport
Copyright (c) 1986-2010 by Cisco Systems, Inc.
Compiled Tue 17-Aug-10 12:08 by prod_rel_team');
my $cdp_plat    = Net::Frame::Layer::CDP::Platform->new(platform=>"Cisco 6500");
my $cdp_prefix  = Net::Frame::Layer::CDP::IPNetPrefix->new(IpNetPrefix => ['192.168.100.0/24']);
my $cdp_vtp     = Net::Frame::Layer::CDP::VTPDomain->new(VtpDomain=>'VTP_DOMAIN');
my $cdp_natvlan = Net::Frame::Layer::CDP::NativeVlan->new(nativeVlan=>100);
my $cdp_duplex  = Net::Frame::Layer::CDP::Duplex->new;
my $cdp_vvlanr  = Net::Frame::Layer::CDP::VoipVlanReply->new(voipVlan=>2);
my $cdp_vvlanq  = Net::Frame::Layer::CDP::VoipVlanQuery->new(data=>'');
my $cdp_power   = Net::Frame::Layer::CDP::Power->new(power=>4000);
my $cdp_mtu     = Net::Frame::Layer::CDP::MTU->new(mtu=>1280);
my $cdp_trustmp = Net::Frame::Layer::CDP::TrustBitmap->new(trustBitmap=>NF_CDP_TYPE_TRUST_BITMAP_TRUSTED);
my $cdp_untrust = Net::Frame::Layer::CDP::UntrustedCos->new(untrustedCos=>4);
my $cdp_mgmtadd = Net::Frame::Layer::CDP::ManagementAddresses->new(addresses=>[$cdp_addr1, $cdp_addr2, $cdp_addr3]);

my $packet = Net::Frame::Simple->new(layers=>[
   $ether,$llc,$snap,$cdp,$cdp_device,$cdp_address,$cdp_iface,$cdp_capabil,$cdp_softver,$cdp_plat,$cdp_prefix,$cdp_vtp,$cdp_natvlan,$cdp_duplex,$cdp_vvlanr,$cdp_vvlanq,$cdp_power,$cdp_mtu,$cdp_trustmp,$cdp_untrust,$cdp_mgmtadd
]);

print $packet->print . "\n";
