eval "use Test::Pod::Coverage tests => 3";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::IGMP");
   pod_coverage_ok("Net::Frame::Layer::IGMP::v3Query");
   pod_coverage_ok("Net::Frame::Layer::IGMP::v3Report");
}
