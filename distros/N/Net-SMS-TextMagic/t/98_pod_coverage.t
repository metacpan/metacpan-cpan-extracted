use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.00";

plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

my $params = { trustme => [qr/^(new|add_constant|get_constant|get_c)$/] };
all_pod_coverage_ok($params);
