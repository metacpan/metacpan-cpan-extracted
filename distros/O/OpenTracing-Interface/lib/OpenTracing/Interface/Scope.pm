package OpenTracing::Interface::Scope;


use strict;
use warnings;


our $VERSION = '0.18';


use Role::MethodReturns;

use OpenTracing::Types qw/Span/;



around close => instance_method ( ) {
    
    returns_self( $instance,
        
        $original->( $instance => ( ) )
        
    );
    
};



around get_span => instance_method ( ) {
    
    returns( Span ,
        
        $original->( $instance => ( ) )
        
    )
};



1;
