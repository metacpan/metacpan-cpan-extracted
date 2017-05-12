eval "use Test::Pod::Coverage tests => 8";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::ICMPv4");
   pod_coverage_ok("Net::Frame::Layer::ICMPv4::AddressMask");
   pod_coverage_ok("Net::Frame::Layer::ICMPv4::Echo");
   pod_coverage_ok("Net::Frame::Layer::ICMPv4::Redirect");
   pod_coverage_ok("Net::Frame::Layer::ICMPv4::Timestamp");
   pod_coverage_ok("Net::Frame::Layer::ICMPv4::DestUnreach");
   pod_coverage_ok("Net::Frame::Layer::ICMPv4::Information");
   pod_coverage_ok("Net::Frame::Layer::ICMPv4::TimeExceed");
}
