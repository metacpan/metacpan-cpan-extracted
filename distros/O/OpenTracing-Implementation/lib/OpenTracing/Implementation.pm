package OpenTracing::Implementation;

use strict;
use warnings;

our $VERSION = 'v0.33.2';

sub OT_IMPLEMENTATION_NAME {
    exists $ENV{ PERL_OPENTRACING_IMPLEMENTATION } ?
        $ENV{ PERL_OPENTRACING_IMPLEMENTATION } :
    exists $ENV{ OPENTRACING_IMPLEMENTATION } ?
        $ENV{ OPENTRACING_IMPLEMENTATION } :
    'NoOp'
}

sub OT_DEBUG {
    exists $ENV{ PERL_OPENTRACING_DEBUG } ?
        $ENV{ PERL_OPENTRACING_DEBUG } :
    exists $ENV{ OPENTRACING_DEBUG } ?
        $ENV{ OPENTRACING_DEBUG } :
    exists $ENV{ DEBUG } ?
        $ENV{ DEBUG } :
    undef
}
#
# it was meant to be a constant, but during test, these seem to be dynamic



use OpenTracing::GlobalTracer;

use Carp;
use Module::Load;

our @CARP_NOT;

sub import {
    my $package = shift;
    return unless @_;
     
    __PACKAGE__->bootstrap_global_tracer( @_ )
}

sub bootstrap_tracer         { shift->_build_tracer( @_ ) }

sub bootstrap_default_tracer { shift->_build_tracer( undef, @_ ) }

sub bootstrap_global_tracer {
    OpenTracing::GlobalTracer->set_global_tracer( shift->_build_tracer( @_ ) );
    return OpenTracing::GlobalTracer->get_global_tracer
}

sub bootstrap_global_default_tracer {
    OpenTracing::GlobalTracer->set_global_tracer( shift->_build_tracer( undef, @_ ) );
    return OpenTracing::GlobalTracer->get_global_tracer
}

# _build_tracer
#
# passing undef as implementation name will cause to use the $ENV
#
sub _build_tracer {
    my $package = shift;
    my $implementation_name = shift;
    my @implementation_args = @_;
    
    my $implementation_class =
        __PACKAGE__->_get_implementation_class( $implementation_name );
    
    carp "Loading implementation $implementation_class"
        if OT_DEBUG;
    
    eval { load $implementation_class };
    croak "GlobalTracer can't load implementation [$implementation_class]"
        if $@;
    
    my $tracer = $implementation_class->bootstrap_tracer( @implementation_args);
    
    return $tracer
}

sub _get_implementation_class {
    my $class = shift;
    my $implementation_name = shift // OT_IMPLEMENTATION_NAME;
    
    my $implementation_class = substr( $implementation_name, 0, 1) eq '+' ?
        substr( $implementation_name, 1 )
        :
        'OpenTracing::Implementation::' . $implementation_name;
    
    return $implementation_class
}

1;
