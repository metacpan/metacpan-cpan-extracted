eval "use Test::Pod::Coverage tests => 5";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };

   pod_coverage_ok("Net::Write",         $trustparents);
   pod_coverage_ok("Net::Write::Layer",  $trustparents);
   pod_coverage_ok("Net::Write::Layer2", $trustparents);
   pod_coverage_ok("Net::Write::Layer3", $trustparents);
   pod_coverage_ok("Net::Write::Layer4", $trustparents);
}
