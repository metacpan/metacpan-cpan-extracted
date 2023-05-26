package Prometheus::Collector::Custom;
use Mojo::Base -base, -signatures;
use Net::Prometheus::Types qw(MetricSamples Sample);

has called => 0;

sub collect($self, $opts) {
	$self->called($self->called + 1);
	return MetricSamples('custom', 'counter', "Status for a custom metric", [ Sample('custom', [], 1) ]);
}

1;
