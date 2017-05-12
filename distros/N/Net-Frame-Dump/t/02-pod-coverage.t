eval "use Test::Pod::Coverage tests => 4";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::Frame::Dump::Online");
   pod_coverage_ok("Net::Frame::Dump::Online2");
   pod_coverage_ok("Net::Frame::Dump::Offline");
   pod_coverage_ok("Net::Frame::Dump::Writer");
}
