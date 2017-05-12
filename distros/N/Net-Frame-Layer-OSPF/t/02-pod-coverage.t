eval "use Test::Pod::Coverage tests => 13";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::OSPF");
   pod_coverage_ok("Net::Frame::Layer::OSPF::Hello");
   pod_coverage_ok("Net::Frame::Layer::OSPF::DatabaseDesc");
   pod_coverage_ok("Net::Frame::Layer::OSPF::Lsa");
   pod_coverage_ok("Net::Frame::Layer::OSPF::Lsa::Router");
   pod_coverage_ok("Net::Frame::Layer::OSPF::Lsa::Router::Link");
   pod_coverage_ok("Net::Frame::Layer::OSPF::Lsa::Network");
   pod_coverage_ok("Net::Frame::Layer::OSPF::Lsa::SummaryIp");
   pod_coverage_ok("Net::Frame::Layer::OSPF::Lsa::Opaque");
   pod_coverage_ok("Net::Frame::Layer::OSPF::Lls");
   pod_coverage_ok("Net::Frame::Layer::OSPF::LinkStateUpdate");
   pod_coverage_ok("Net::Frame::Layer::OSPF::LinkStateAck");
   pod_coverage_ok("Net::Frame::Layer::OSPF::LinkStateRequest");
}
