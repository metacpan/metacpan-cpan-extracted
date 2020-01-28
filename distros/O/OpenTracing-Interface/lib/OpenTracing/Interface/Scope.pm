package OpenTracing::Interface::Scope;


use strict;
use warnings;


our $VERSION = '0.10';


use Role::MethodReturns;

use Types::Standard qw/Undef/;



around close => instance_method ( ) {
    
    returns( Undef,
        
        $original->( $instance => ( ) )
        
    );
    
    return # we do not really want it to return undef, as perl relies on context
};



around get_span => instance_method ( ) {
    
    returns_object_does_interface( 'OpenTracing::Interface::Span' ,
        
        $original->( $instance => ( ) )
        
    )
};



1;
