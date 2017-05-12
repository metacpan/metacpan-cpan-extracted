eval "use Test::Pod::Coverage tests => 8";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::LLTD");
   pod_coverage_ok("Net::Frame::Layer::LLTD::Discover");
   pod_coverage_ok("Net::Frame::Layer::LLTD::Hello");
   pod_coverage_ok("Net::Frame::Layer::LLTD::Emit");
   pod_coverage_ok("Net::Frame::Layer::LLTD::Tlv");
   pod_coverage_ok("Net::Frame::Layer::LLTD::EmiteeDesc");
   pod_coverage_ok("Net::Frame::Layer::LLTD::QueryResp");
   pod_coverage_ok("Net::Frame::Layer::LLTD::RecveeDesc");
}
