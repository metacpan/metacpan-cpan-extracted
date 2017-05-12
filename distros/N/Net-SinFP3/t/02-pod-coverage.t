eval "use Test::Pod::Coverage tests => 10";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::SinFP3");
   pod_coverage_ok("Net::SinFP3::DB");
   pod_coverage_ok("Net::SinFP3::Input");
   pod_coverage_ok("Net::SinFP3::Next");
   pod_coverage_ok("Net::SinFP3::Mode");
   pod_coverage_ok("Net::SinFP3::Search");
   pod_coverage_ok("Net::SinFP3::Output");
   pod_coverage_ok("Net::SinFP3::Log");
   pod_coverage_ok("Net::SinFP3::Result");
   pod_coverage_ok("Net::SinFP3::Global");
}
