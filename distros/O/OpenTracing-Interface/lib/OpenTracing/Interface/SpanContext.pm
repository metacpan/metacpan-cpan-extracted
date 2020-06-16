package OpenTracing::Interface::SpanContext;


use strict;
use warnings;


our $VERSION = 'v0.203.0';


use Role::Declare;

use OpenTracing::Types qw/SpanContext/;
use Types::Standard qw/Any HashRef Str Value/;

use namespace::clean;



instance_method with_baggage_item(
    Str $key,
    Str $value
) :Return(SpanContext) {}



instance_method with_baggage_items(
    %key_values,
) :Return(SpanContext) {
    ( HashRef[Str] )->assert_valid( {%key_values} )
}



1;
