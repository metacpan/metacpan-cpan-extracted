#!perl -T

use Test::More;# skip_all => "Not yet\n";
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok(
                     { also_private => [ qr/^[A-Z_]+$/ ], },
                     "with all-caps functions as privates",
                   );
