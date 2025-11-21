package Local::Caller::Implicit;

sub do { 1 }

sub die { die 'oops' }

use OpenTelemetry::Instrumentation 'caller';

1;
