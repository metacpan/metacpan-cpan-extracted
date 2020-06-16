package OpenTracing::Role::Tracer;

our $VERSION = 'v0.81.1';

use Moo::Role;
use syntax qw/maybe/;

use Carp;
use OpenTracing::Types qw/ScopeManager Span SpanContext is_Span is_SpanContext/;
use Ref::Util qw/is_plain_hashref/;
use Role::Declare -lax;
use Try::Tiny;
use Types::Common::Numeric qw/PositiveOrZeroNum/;
use Types::Standard qw/Maybe HashRef Object Str/;

has scope_manager => (
    is              => 'ro',
    isa             => ScopeManager,
    reader          => 'get_scope_manager',
    default => sub {
        require 'OpenTracing::Implementation::NoOp::ScopeManager';
        return OpenTracing::Implementation::NoOp::ScopeManager->new
    },
);

has default_span_context_args => (
    is              => 'ro',
    isa             => HashRef[Str],
    default         => sub{ {} },
);

sub get_active_span {
    my $self = shift;
    
    my $scope_manager = $self->get_scope_manager
        or croak "Can't get a 'ScopeManager'";
    
    my $scope = $scope_manager->get_active_scope
        or return;
    
    return $scope->get_span;
}

sub start_active_span {
    my $self = shift;
    my $operation_name = shift
        or croak "Missing required operation_name";
    my $opts = { @_ };
    
    my $finish_span_on_close = 
        exists( $opts->{ finish_span_on_close } ) ?
            !! delete $opts->{ finish_span_on_close }
            : !undef
    ; # use 'truthness' of param if provided, or set to 'true' otherwise
    
    my $span = $self->start_span( $operation_name => %$opts );
    
    my $scope_manager = $self->get_scope_manager();
    my $scope = $scope_manager->activate_span( $span,
        finish_span_on_close => $finish_span_on_close
    );
    
    return $scope
}

sub start_span {
    my $self = shift;
    
    my $operation_name = shift
        or croak "Missing required operation_name";
    my $opts = { @_ };
    
    my $start_time         = delete $opts->{ start_time };
    my $ignore_active_span = delete $opts->{ ignore_active_span };
    my $child_of           = delete $opts->{ child_of };
    my $tags               = delete $opts->{ tags };
    
    $child_of //= $self->get_active_span()
        unless $ignore_active_span;
    
    my $context;

    $context = $child_of
        if is_SpanContext($child_of);
    
    $context = $child_of->get_context
        if is_Span($child_of);
    
    $context = $context->new_clone->with_trace_id( $context->trace_id )
        if is_SpanContext($context);
    
    $context = $self->build_context( %{$self->default_span_context_args} )
        unless defined $context;
    
    my $span = $self->build_span(
        operation_name => $operation_name,
        context        => $context,

        maybe
        child_of       => $child_of,

        maybe
        start_time     => $start_time,

        maybe
        tags           => $tags,
    );
    #
    # we should get rid of passing 'child_of' or the not exisitng 'follows_from'
    # these are merely helpers to define 'references'.
    
    return $span
}

instance_method extract_context(
    Str    $carrier_format,
    Object $carrier
) :ReturnMaybe(SpanContext) {}


instance_method inject_context(
    Str    $carrier_format,
    Object $carrier,
    SpanContext $span_context
) :Return(Object) {}


instance_method build_span (
    Str                         :$operation_name,
    SpanContext                 :$context,
    Maybe[ SpanContext | Span ] :$child_of,
    Maybe[ PositiveOrZeroNum ]  :$start_time,
    Maybe[ HashRef[Str] ]       :$tags,
) :Return (Span) { };

instance_method build_context (
    %default_span_context_args,
) :Return (SpanContext) {
    ( HashRef[Str] )->assert_valid( { %default_span_context_args } );
};



BEGIN {
#   use Role::Tiny::With;
    with 'OpenTracing::Interface::Tracer'
        if $ENV{OPENTRACING_INTERFACE};
}



1;
