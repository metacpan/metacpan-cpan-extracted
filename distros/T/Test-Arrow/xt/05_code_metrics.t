use Test::Arrow;
eval 'require Test::Perl::Metrics::Lite';
Test::Arrow->plan(skip_all => 'Test::Perl::Metrics::Lite required for testing code metrics.') if $@;
Test::Perl::Metrics::Lite->import(
    -mccabe_complexity => 20,
    -loc => 80,
    -except_dir  => [
    ],
    -except_file => [
    ],
);
all_metrics_ok();
