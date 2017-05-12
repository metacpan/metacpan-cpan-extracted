use strict;
use Test::More;

eval "use Test::Pod::Coverage;";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

pod_coverage_ok('Net::IDN::IDNA2003', {'trustme' => [qr/^to_/]});
done_testing();
