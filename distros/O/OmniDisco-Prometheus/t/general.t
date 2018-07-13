use warnings;
use strict;
use Test::More qw(no_plan);

BEGIN {
	use_ok('OmniDisco::Prometheus');
}


my $b = OD::Prometheus::Metric->new(
        line => 'http_request_duration_microseconds{plain="prometheus",backslash="\\\\",newline="\n",quote="\"",quantile="0.5"} NaN',
        comments => [
                '#    HELP  http_request_duration_microseconds      one line\nsecond line and backslash:\\\\\nthird item',
                '# TYPE http_request_duration_microseconds gauge',
                '# And when the entire mountain is chiseled away, the first second of eternity will have passed',
        ]
);

p $b;

say STDERR $b->labels->{ quote };

say STDERR $b->to_string;


# my $c = OD::Prometheus::Client->new(host=>'test.server',port=>9100);
# ok( ref $c->get  eq 'ARRAY', 'get returns an array' );
