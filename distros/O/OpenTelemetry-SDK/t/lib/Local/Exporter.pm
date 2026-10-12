package Local::Exporter;

use Object::Pad ':experimental(init_expr)';

class Local::Exporter :does(OpenTelemetry::Exporter) {
    use Future::AsyncAwait;

    field $calls :reader = [];
    method $log { push @$calls, [ @_ ] }

    method export { $self->$log( export=> @_ ); 1 }

    async method shutdown    { $self->$log( shutdown    => @_ ); 1 }
    async method force_flush { $self->$log( force_flush => @_ ); 1 }
}
