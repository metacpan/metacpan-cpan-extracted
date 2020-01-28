package OpenTracing::Interface::ScopeManager;

use strict;
use warnings;


our $VERSION = '0.10';


use Role::MethodReturns;

use Types::Interface qw/ObjectDoesInterface/;
use Types::Standard qw/Bool Dict Optional/;



around activate_span => instance_method (
    (ObjectDoesInterface['OpenTracing::Interface::Span']) $span,
    %options,
) {
    (
        Dict[
            finish_span_on_close => Optional[ Bool ],
        ]
    )->assert_valid( \%options );
    
    returns_object_does_interface( 'OpenTracing::Interface::Scope',
        $original->( $instance => %options )
    )

};



around get_active_scope => instance_method ( ) {
    
    returns_object_does_interface( 'OpenTracing::Interface::Scope',
        $original->( $instance => ( ) )
    )
};


1;
