eval "use Test::Pod::Coverage tests => 10";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::IPv4");
   pod_coverage_ok("Net::Frame::Layer::TCP");
   pod_coverage_ok("Net::Frame::Layer::UDP");
   pod_coverage_ok("Net::Frame::Layer::ARP");
   pod_coverage_ok("Net::Frame::Layer::ETH");
   pod_coverage_ok("Net::Frame::Layer::NULL");
   pod_coverage_ok("Net::Frame::Layer::PPP");
   pod_coverage_ok("Net::Frame::Layer::RAW");
   pod_coverage_ok("Net::Frame::Layer::SLL");
   pod_coverage_ok("Net::Frame::Layer");
}
