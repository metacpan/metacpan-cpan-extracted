eval "use Test::Pod::Coverage tests => 6";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::IPv6");
   pod_coverage_ok("Net::Frame::Layer::IPv6::Fragment");
   pod_coverage_ok("Net::Frame::Layer::IPv6::Routing");
   pod_coverage_ok("Net::Frame::Layer::IPv6::HopByHop");
   pod_coverage_ok("Net::Frame::Layer::IPv6::Destination");
   pod_coverage_ok("Net::Frame::Layer::IPv6::Option");
}
