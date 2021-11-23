package OpenTracing::Implementation;

use strict;
use warnings;

our $VERSION = 'v0.32.0';

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
    my $package = shift;
    my $tracer = $package->_build_tracer( @_ );
    
    OpenTracing::GlobalTracer->set_global_tracer( $tracer );
    
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
        if $ENV{OPENTRACING_DEBUG};
    
    load $implementation_class;
    
    eval { load $implementation_class };
    croak "GlobalTracer can't load implementation [$implementation_class]"
        if $@;
    
    my $tracer = $implementation_class->bootstrap_tracer( @implementation_args);
    
    return $tracer
}

sub _get_implementation_class {
    my $class = shift;
    my $implementation_name = shift;
    
    $implementation_name = $ENV{OPENTRACING_IMPLEMENTATION} || 'NoOp'
        unless defined $implementation_name;

    my $implementation_class = substr( $implementation_name, 0, 1) eq '+' ?
        substr( $implementation_name, 1 )
        :
        'OpenTracing::Implementation::' . $implementation_name;
    
    return $implementation_class
}

1;
