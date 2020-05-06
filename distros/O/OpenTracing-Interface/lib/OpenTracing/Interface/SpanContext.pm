package OpenTracing::Interface::SpanContext;


use strict;
use warnings;


our $VERSION = '0.19';


use Role::MethodReturns;

use OpenTracing::Types qw/SpanContext/;
use Types::Standard qw/Str Value/;



around get_baggage_item => instance_method ( Str $key ) {
    
    returns_maybe( Value,
        $original->( $instance => ( $key ) )
    )
    
};



around with_baggage_item => instance_method ( Str $key, Str $value ) {
    
    returns( SpanContext ,
        $original->( $instance => ( $key, $value ) )
    )
    
};



1;
