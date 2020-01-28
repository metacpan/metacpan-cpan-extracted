package OpenTracing::Interface::Tracer;


use strict;
use warnings;


our $VERSION = '0.10';


use Role::MethodReturns;

use Types::Standard qw/ArrayRef Bool Dict HashRef Optional Str Undef/;
use Types::Common::Numeric qw/PositiveNum/;
use Types::Interface qw/ObjectDoesInterface/;



around get_scope_manager => instance_method ( ) {
    
    returns_maybe_object_does_interface( 'OpenTracing::Interface::ScopeManager',
        
        $original->( $instance => ( ) )
        
    )
};



around get_active_span => instance_method ( ) {
    
    returns_maybe_object_does_interface( 'OpenTracing::Interface::Span',
        
        $original->( $instance => ( ) )
        
    )
};



around start_active_span => instance_method ( Str  $operation_name, %options ) {
    
    ( Dict[
        
        child_of                => Optional[
            ObjectDoesInterface['OpenTracing::Interface::Span']        |
            ObjectDoesInterface['OpenTracing::Interface::SpanContext']
        ],
        references              => Optional[ ArrayRef[ HashRef ]],
        tags                    => Optional[ HashRef[ Str ] ],
        start_time              => Optional[ PositiveNum ],
        ignore_active_span      => Optional[ Bool ],
        finish_span_on_close    => Optional[ Bool ],
        
    ] )->assert_valid( \%options );
    
    returns_object_does_interface( 'OpenTracing::Interface::Scope',
    
        $original->( $instance => ( $operation_name, %options ) )
    )
};



around start_span => instance_method ( Str $operation_name, %options ) {
    
     ( Dict[
        
        child_of                => Optional[
            ObjectDoesInterface['OpenTracing::Interface::Span']        |
            ObjectDoesInterface['OpenTracing::Interface::SpanContext']
        ],
        references              => Optional[ ArrayRef[ HashRef ]],
        tags                    => Optional[ HashRef[ Str ] ],
        start_time              => Optional[ PositiveNum ],
        ignore_active_span      => Optional[ Bool ],
        
    ] )->assert_valid( \%options );
    
    returns_object_does_interface( 'OpenTracing::Interface::Span',
    
        $original->( $instance => ( $operation_name, %options ) )
    )
};



around inject_context => instance_method (
    (ObjectDoesInterface['OpenTracing::Interface::SpanContext']) $span_context,
    $carrier_format,
    $carrier
) {
    
    returns( Undef,
        
        $original->( $instance => ( $span_context, $carrier_format, $carrier ) )
        
    );
    
    return # we do not really want it to return undef, as perl relies on context
};



around extract_context => instance_method ( ) {
    
    returns_maybe_object_does_interface( 'OpenTracing::Interface::SpanContext',
        
        $original->( $instance => ( ) )
        
    )
};



1;
