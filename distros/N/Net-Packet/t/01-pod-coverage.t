eval "use Test::Pod::Coverage tests => 34";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };

   pod_coverage_ok("Net::Packet", $trustparents);

   pod_coverage_ok("Net::Packet::Consts", $trustparents);
   pod_coverage_ok("Net::Packet::Env",    $trustparents);
   pod_coverage_ok("Net::Packet::Frame",  $trustparents);
   pod_coverage_ok("Net::Packet::Dump",   $trustparents);
   pod_coverage_ok("Net::Packet::Utils",  $trustparents);

   pod_coverage_ok("Net::Packet::Desc",   $trustparents);
   pod_coverage_ok("Net::Packet::DescL2", $trustparents);
   pod_coverage_ok("Net::Packet::DescL3", $trustparents);
   pod_coverage_ok("Net::Packet::DescL4", $trustparents);

   pod_coverage_ok("Net::Packet::Layer",  $trustparents);
   pod_coverage_ok("Net::Packet::Layer2", $trustparents);
   pod_coverage_ok("Net::Packet::Layer3", $trustparents);
   pod_coverage_ok("Net::Packet::Layer4", $trustparents);
   pod_coverage_ok("Net::Packet::Layer7", $trustparents);

   # Layer 2
   pod_coverage_ok("Net::Packet::ETH",  $trustparents);
   pod_coverage_ok("Net::Packet::NULL", $trustparents);
   pod_coverage_ok("Net::Packet::PPP",  $trustparents);
   pod_coverage_ok("Net::Packet::RAW",  $trustparents);
   pod_coverage_ok("Net::Packet::SLL",  $trustparents);

   # Layer 3
   pod_coverage_ok("Net::Packet::ARP",    $trustparents);
   pod_coverage_ok("Net::Packet::IPv4",   $trustparents);
   pod_coverage_ok("Net::Packet::IPv6",   $trustparents);
   pod_coverage_ok("Net::Packet::LLC",    $trustparents);
   pod_coverage_ok("Net::Packet::PPPLCP", $trustparents);
   pod_coverage_ok("Net::Packet::PPPoE",  $trustparents);
   pod_coverage_ok("Net::Packet::VLAN",   $trustparents);

   # Layer 4
   pod_coverage_ok("Net::Packet::CDP",    $trustparents);
   pod_coverage_ok("Net::Packet::ICMPv4", $trustparents);
   pod_coverage_ok("Net::Packet::IGMPv4", $trustparents);
   pod_coverage_ok("Net::Packet::OSPF",   $trustparents);
   pod_coverage_ok("Net::Packet::STP",    $trustparents);
   pod_coverage_ok("Net::Packet::TCP",    $trustparents);
   pod_coverage_ok("Net::Packet::UDP",    $trustparents);
}
