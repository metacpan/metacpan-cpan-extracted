package OpenTracing::Interface::Span;

use strict;
use warnings;


our $VERSION = '0.18';


use Role::MethodReturns;

use OpenTracing::Types qw/SpanContext/;
use Types::Standard qw/ Str Value HashRef ArrayRef/;
use Types::Common::Numeric qw/PositiveNum/;



around get_context => instance_method ( ) {
    
    returns( SpanContext,
        $original->( $instance => ( ) )
    )
    
};



around overwrite_operation_name => instance_method ( Str $operation_name ) {
    
    returns_self( $instance,
        $original->( $instance => ( $operation_name ) )
    )
    
};



around finish => instance_method ( @time_stamps ) {
    
    ( ArrayRef[PositiveNum, 0, 1 ] )->assert_valid( \@time_stamps );
    #
    # a bit narly construct, but otherwise we might have accidently introduced
    # `undef` as an argument, where there used to be none!
    
    returns_self( $instance,
        $original->( $instance => ( @time_stamps ) )
    )
    
};



around set_tag => instance_method ( Str $key, Value $value ) {
    
    returns_self( $instance,
        $original->( $instance => ( $key, $value ) )
    )
    
};



around log_data => instance_method ( @log_data ) {
    
    ( HashRef[ Value ] )->assert_valid( { @log_data } );
    
    returns_self( $instance,
        $original->( $instance => ( @log_data ) )
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