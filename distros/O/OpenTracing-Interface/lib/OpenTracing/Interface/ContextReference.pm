package OpenTracing::Interface::ContextReference;


use strict;
use warnings;


our $VERSION = '0.19';


use Role::MethodReturns;

use OpenTracing::Types qw/ContextReference SpanContext/;
use Types::Standard qw/Bool/;



around new_child_of => class_method ( SpanContext $span_context ) {
    
    returns( ContextReference ,
        $original->( $class => ( $span_context ) )
    );
    
};



around new_follows_from => class_method ( SpanContext $span_context ) {
    
    returns( ContextReference ,
        $original->( $class => ( $span_context ) )
    )
    
};



around get_referenced_context => instance_method ( ) {
    
    returns( SpanContext ,
        $original->( $instance => ( ) )
    )
    
};



around type_is_child_of => instance_method ( ) {
    
    returns( Bool ,
        $original->( $instance => ( ) )
    )
    
};



around type_is_follows_from => instance_method ( ) {
    
    returns( Bool ,
        $original->( $instance => ( ) )
    )
    
};



1;
