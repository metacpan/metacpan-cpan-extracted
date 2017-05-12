eval "use Test::Pod::Coverage tests => 1";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Net::SinFP3::Plugin::Signature");
}
