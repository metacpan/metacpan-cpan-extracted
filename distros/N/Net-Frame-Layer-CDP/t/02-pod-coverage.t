eval "use Test::Pod::Coverage tests => 21";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Layer::CDP");
   pod_coverage_ok("Net::Frame::Layer::CDP::Constants");
   pod_coverage_ok("Net::Frame::Layer::CDP::DeviceId");
   pod_coverage_ok("Net::Frame::Layer::CDP::Addresses");
   pod_coverage_ok("Net::Frame::Layer::CDP::Address");
   pod_coverage_ok("Net::Frame::Layer::CDP::PortId");
   pod_coverage_ok("Net::Frame::Layer::CDP::Capabilities");
   pod_coverage_ok("Net::Frame::Layer::CDP::SoftwareVersion");
   pod_coverage_ok("Net::Frame::Layer::CDP::Platform");
   pod_coverage_ok("Net::Frame::Layer::CDP::IPNetPrefix");
   pod_coverage_ok("Net::Frame::Layer::CDP::VTPDomain");
   pod_coverage_ok("Net::Frame::Layer::CDP::NativeVlan");
   pod_coverage_ok("Net::Frame::Layer::CDP::Duplex");
   pod_coverage_ok("Net::Frame::Layer::CDP::VoipVlanReply");
   pod_coverage_ok("Net::Frame::Layer::CDP::VoipVlanQuery");
   pod_coverage_ok("Net::Frame::Layer::CDP::Power");
   pod_coverage_ok("Net::Frame::Layer::CDP::MTU");
   pod_coverage_ok("Net::Frame::Layer::CDP::TrustBitmap");
   pod_coverage_ok("Net::Frame::Layer::CDP::UntrustedCos");
   pod_coverage_ok("Net::Frame::Layer::CDP::ManagementAddresses");
   pod_coverage_ok("Net::Frame::Layer::CDP::Unknown");
}
