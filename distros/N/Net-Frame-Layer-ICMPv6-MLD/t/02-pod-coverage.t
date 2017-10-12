eval "use Test::Pod::Coverage tests => 4";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::ICMPv6::MLD");
   pod_coverage_ok("Net::Frame::Layer::ICMPv6::MLD::Query");
   pod_coverage_ok("Net::Frame::Layer::ICMPv6::MLD::Report");
   pod_coverage_ok("Net::Frame::Layer::ICMPv6::MLD::Report::Record");
}
