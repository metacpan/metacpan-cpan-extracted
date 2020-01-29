package OpenTracing::Interface::Span;

use strict;
use warnings;


our $VERSION = '0.10';


use Role::MethodReturns;

use Types::Standard qw/ Str Maybe Value HashRef/;
use Types::Common::Numeric qw/PositiveNum/;


around get_context => instance_method ( ) {
    
    returns_object_does_interface( 'OpenTracing::Interface::SpanContext',
        $original->( $instance => ( ) )
    )
};


around overwrite_operation_name => instance_method ( Str $operation_name ) {
    
    returns_self( $instance,
        $original->( $instance => ( $operation_name ) )
    )
};


around finish => instance_method ( Maybe[PositiveNum] $epoch_timestamp = undef ) {
    
    returns_self( $instance,
        $original->( $instance => ( $epoch_timestamp ) )
    )
};


around set_tag => instance_method ( Str $key, Value $value ) {
    
    returns_self( $instance,
        $original->( $instance => ( $key, $value ) )
    )
};


around log_data => instance_method ( %log_data ) {
    
    ( HashRef[ Value ] )->assert_valid( \%log_data );
    
    returns_self( $instance,
        $original->( $instance => ( %log_data ) )
    )
};


around set_baggage_item => instance_method ( Str $key, Value $value, ) {
    
    returns_self( $instance,
        $original->( $instance => ( $key, $value ) )
    )
};


around get_baggage_item => instance_method ( Str $key ) {
    
    returns_maybe ( Value,
        $original->( $instance => ( $key ) )
    )
};


1;