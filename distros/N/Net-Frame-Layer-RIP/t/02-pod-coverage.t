eval "use Test::Pod::Coverage tests => 3";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::RIP");
   pod_coverage_ok("Net::Frame::Layer::RIP::v1");
   pod_coverage_ok("Net::Frame::Layer::RIP::v2");
}
