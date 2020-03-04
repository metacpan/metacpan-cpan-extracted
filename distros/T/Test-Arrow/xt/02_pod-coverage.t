use Test::Arrow;
eval "use Test::Pod::Coverage 1.04";
Test::Arrow->plan(skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage") if $@;
all_pod_coverage_ok({ trustme => [qr/^(warn_ok|warning_ok|warning)$/] });
