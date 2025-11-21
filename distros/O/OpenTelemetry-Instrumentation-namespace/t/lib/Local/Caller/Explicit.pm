package Local::Caller::Explicit;

sub do { 1 }

sub die { die 'oops' }

sub secret { 1 }

use OpenTelemetry::Instrumentation caller => [
    do  => 1,
    die => 1,
];

1;
