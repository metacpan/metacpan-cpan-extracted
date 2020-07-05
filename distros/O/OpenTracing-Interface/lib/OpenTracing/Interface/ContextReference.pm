package OpenTracing::Interface::ContextReference;


use strict;
use warnings;


our $VERSION = 'v0.204.0';


use Role::Declare;

use OpenTracing::Types qw/ContextReference SpanContext/;
use Types::Standard qw/Bool/;

use namespace::clean;

class_method new_child_of(
    SpanContext $span_context
) :Return(ContextReference) {}



class_method new_follows_from(
    SpanContext $span_context
) :Return(ContextReference) {}



instance_method get_referenced_context(
) :Return(SpanContext) {}



instance_method type_is_child_of(
) :Return(Bool) {}



instance_method type_is_follows_from(
) :Return(Bool) {}



1;
