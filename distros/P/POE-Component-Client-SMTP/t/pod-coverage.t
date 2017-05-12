#!perl -T
#
#       command
#       debug
#       delete_rw_wheel
#       delete_sf_wheel
#       parameter
#       store_rw_wheel
#       store_sf_wheel

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
  if $@;
all_pod_coverage_ok(
    {
        also_private => [
qr/^(debug|command|delete_rw_wheel|delete_sf_wheel|parameter|store_rw_wheel|store_sf_wheel|delete_file_wheel|store_file_wheel)$/
        ]
    }
);

