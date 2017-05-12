eval "use Test::Pod::Coverage tests => 15";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::DNS");
   pod_coverage_ok("Net::Frame::Layer::DNS::Constants");
   pod_coverage_ok("Net::Frame::Layer::DNS::Question");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::A");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::AAAA");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::CNAME");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::HINFO");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::MX");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::NS");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::PTR");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::rdata");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::SOA");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::SRV");
   pod_coverage_ok("Net::Frame::Layer::DNS::RR::TXT");
}
