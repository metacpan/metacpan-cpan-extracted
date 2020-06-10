package OpenTracing::Interface::Scope;


use strict;
use warnings;


our $VERSION = '0.20';


use Role::MethodReturns;

use OpenTracing::Types qw/Span/;

use namespace::clean;


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
