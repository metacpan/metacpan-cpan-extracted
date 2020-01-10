package OpenTracing::Implementation::Interface::Bootstrap;

use Role::MethodReturns;



around bootstrap => class_method ( @args ) {
    
    returns_object_does_interface( 'OpenTracing::Interface::Tracer' =>
        $original->( $class => @args )
    )
    
};



1;