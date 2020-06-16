package OpenTracing::Interface::Span;

use strict;
use warnings;


our $VERSION = 'v0.203.0';


use Role::Declare -lax;

use OpenTracing::Types qw/SpanContext/;
use Time::HiRes qw/time/;
use Types::Standard qw/Any Str Value HashRef ArrayRef Maybe Str Value/;
use Types::Common::Numeric qw/PositiveNum PositiveOrZeroNum/;

use namespace::clean;


instance_method overwrite_operation_name(
    Str $operation_name
) :ReturnSelf {}



instance_method finish(
    PositiveOrZeroNum $time_stamp = time(),
) :ReturnSelf {}



instance_method add_tag(
    Str $key,
    Value $value
) :ReturnSelf {}



instance_method add_tags(
    %key_values,
) :ReturnSelf {
    ( HashRef[Value] )->assert_valid( {%key_values} )
}



instance_method log_data(
    %key_values
) :ReturnSelf {
    ( HashRef[ Value ] )->assert_valid( { %key_values } );
}



instance_method add_baggage_item(
    Str $key,
    Value $value
) :ReturnSelf {}



instance_method add_baggage_items(
    %key_values,
) :ReturnSelf {
    ( HashRef[Value] )->assert_valid( {%key_values} )
}



1;
