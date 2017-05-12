eval "use Test::Pod::Coverage tests => 9";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Libdnet");
   pod_coverage_ok("Net::Libdnet::Arp");
   pod_coverage_ok("Net::Libdnet::Route");
   pod_coverage_ok("Net::Libdnet::Intf");
   pod_coverage_ok("Net::Libdnet::Fw");
   pod_coverage_ok("Net::Libdnet::Eth");
   pod_coverage_ok("Net::Libdnet::Ip");
   pod_coverage_ok("Net::Libdnet::Tun");
   pod_coverage_ok("Net::Libdnet::Entry::Intf");
}
