use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A basic OpenTelemetry span processor

package OpenTelemetry::Processor::Simple;

our $VERSION = '0.100';

class OpenTelemetry::Processor::Simple :does(OpenTelemetry::Processor) {
    use Feature::Compat::Try;
    use Future::AsyncAwait;
    use OpenTelemetry::X;

    field $exporter :param;

    ADJUST {
        die OpenTelemetry::X->create(
            Invalid => "Exporter must implement the OpenTelemetry::Exporter interface: " . ( ref $exporter || $exporter )
        ) unless $exporter && $exporter->DOES('OpenTelemetry::Exporter');
    }

    method process ( @items ) {
        try {
            my $result = $exporter->export(\@items);
            $self->report_result( $result, scalar @items );
        }
        catch ($e) {
            warn $e;
        }

        return;
    }

    method report_result ( $result, $count ) { $result }

    async method shutdown ( $timeout = undef ) {
        await $exporter->shutdown( $timeout );
    }

    async method force_flush ( $timeout = undef ) {
        await $exporter->force_flush( $timeout );
    }
}
