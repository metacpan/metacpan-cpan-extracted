#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
my $trustme = { trustme => [qr/^(white|black|blue|navy|green|red|brown|maroon|purple|orange|olive|yellow|light_green|lime|teal|light_cyan|cyan|aqua|light_blue|royal|pink|light_purple|fuchsia|grey|light_grey|silver)$/] };
all_pod_coverage_ok($trustme);
