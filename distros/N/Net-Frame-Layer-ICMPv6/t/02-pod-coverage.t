eval "use Test::Pod::Coverage tests => 6";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::ICMPv6");
   pod_coverage_ok("Net::Frame::Layer::ICMPv6::Echo");
   pod_coverage_ok("Net::Frame::Layer::ICMPv6::NeighborAdvertisement");
   pod_coverage_ok("Net::Frame::Layer::ICMPv6::NeighborSolicitation");
   pod_coverage_ok("Net::Frame::Layer::ICMPv6::RouterAdvertisement");
   pod_coverage_ok("Net::Frame::Layer::ICMPv6::RouterSolicitation");
}
