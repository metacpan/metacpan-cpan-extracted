package OpenTelemetry::Instrumentation::caller;
# ABSTRACT: OpenTelemetry instrumentation for the current namespace

our $VERSION = '0.033';

use v5.38;

use parent 'OpenTelemetry::Instrumentation::namespace';

sub install {
    my $class = shift;
    my ( $rules, $options ) = $class->parse_options(@_);

    $rules = [ qr/.*/ => 1 ] unless @$rules;

    $class->wrap_subroutines( scalar caller(2), $rules, $options );
}

1;
