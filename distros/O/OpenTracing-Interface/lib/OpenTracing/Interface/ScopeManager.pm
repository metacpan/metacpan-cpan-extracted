package OpenTracing::Interface::ScopeManager;

use strict;
use warnings;


our $VERSION = '0.18';


use Role::MethodReturns;

use OpenTracing::Types qw/Scope Span/;
use Types::Standard qw/Bool Dict Optional/;



around activate_span => instance_method ( Span $span, @options, ) {
    
    (
        Dict[
            finish_span_on_close => Optional[ Bool ],
        ]
    )->assert_valid( { @options } );
    
    returns( Scope,
        $original->( $instance => ( $span, @options ) )
    )
    
};



around get_active_scope => instance_method ( ) {
    
    returns( Scope,
        $original->( $instance => ( ) )
    )
    
};


1;
