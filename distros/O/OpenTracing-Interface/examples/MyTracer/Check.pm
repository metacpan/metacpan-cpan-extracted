package MyTracer::Check;

use MyTracer::Span;
use MyTracer::Tracer;

my $span = MyTracer::Span->new( oops => 'here' );

$span->set_tag( hello => "world" );

$span->get_baggage_item( "geel" );

$span->get_context( );

$span->log_data ( what => 7.5 );

my $tracer = MyTracer::Tracer->new( some_args => 'here' );

$tracer->start_active_span( "Hello Babe" =>
    start_time => 300,
    tags => {
        foo => 42,
        bar => 2,
    },
    child_of => $span ,
);

my $scope_manager = $tracer->get_scope_manager();

my $scope_guard = $scope_manager->activate_span($span, finish_span_on_close => 0);


1;
