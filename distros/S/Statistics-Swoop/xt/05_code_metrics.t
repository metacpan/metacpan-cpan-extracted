use Test::Perl::Metrics::Lite (
    -mccabe_complexity => 12,
    -loc => 50,
    -except_dir  => [
    ],
    -except_file => [
    ],
);

all_metrics_ok();
