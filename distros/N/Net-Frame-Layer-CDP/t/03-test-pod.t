eval "use Test::Pod 1.00";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod 1.00 required for testing");
}
else {
   all_pod_files_ok();
}
