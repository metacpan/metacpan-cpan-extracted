package OpenTracing::Interface::SpanContext;


use strict;
use warnings;

use Role::MethodReturns;

use Types::Standard qw/Str Value/;



around get_baggage_item => instance_method ( Str $key ) {
    
    maybe_returns( Value,
        
        $original->( $instance => ( $key ) )
        
    )
};



around with_baggage_item => instance_method ( Str $key, Str $value ) {
    
    returns_object_does_interface( __PACKAGE__ ,
        
        $original->( $instance => ( $key, $value ) )
        
    )
};



1;

