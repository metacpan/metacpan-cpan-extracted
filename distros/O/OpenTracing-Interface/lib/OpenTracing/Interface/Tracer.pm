package OpenTracing::Interface::Tracer;


use strict;
use warnings;


our $VERSION = 'v0.206.1';


use Role::Declare::Should -lax; # so missing named parameters default to undef

use OpenTracing::Types qw/ContextReference Scope ScopeManager Span SpanContext/;
use Types::Standard qw/ArrayRef Bool Dict HashRef Maybe Object Str/;
use Types::Common::Numeric qw/PositiveOrZeroNum/;

use constant Carrier => Object | HashRef | ArrayRef;

use Carp;

use namespace::clean;



instance_method get_scope_manager(
) :Return(ScopeManager) {}



instance_method get_active_span(
) :ReturnMaybe(Span) {}



instance_method start_active_span(
    Str $operation_name,
    Maybe[ Span | SpanContext ]         :$child_of,
    Maybe[ ArrayRef[ContextReference] ] :$references,
    Maybe[ HashRef[Str] ]               :$tags,
    Maybe[ PositiveOrZeroNum ]          :$start_time,
    Maybe[ Bool ]                       :$ignore_active_span,
    Maybe[ Bool ]                       :$finish_span_on_close,
) :Return(Scope) {
    croak "'child_of' and 'references' are mutual exclusive options"
        if defined $child_of && defined $references;
}



instance_method start_span(
    Str $operation_name,
    Maybe[ Span | SpanContext ]         :$child_of,
    Maybe[ ArrayRef[ContextReference] ] :$references,
    Maybe[ HashRef[Str] ]               :$tags,
    Maybe[ PositiveOrZeroNum ]          :$start_time,
    Maybe[ Bool ]                       :$ignore_active_span,
) :Return(Span) {
    croak "'child_of' and 'references' are mutual exclusive options"
      if defined $child_of && defined $references;
}



instance_method inject_context(
    Carrier $carrier,
    Maybe[ SpanContext ] $span_context = undef,
) :Return(Carrier) {} # a clone preferably



instance_method extract_context(
    Carrier $carrier,
) :ReturnMaybe(SpanContext) {}



1;
