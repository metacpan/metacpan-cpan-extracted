package OpenTracing::Role::Tracer;

our $VERSION = 'v0.86.1';

use syntax qw/maybe/;

use Moo::Role;
use MooX::HandlesVia;
use MooX::Should;

use Carp;
use List::Util qw/first/;
use OpenTracing::Types qw/ScopeManager Span SpanContext is_Span is_SpanContext/;
use Ref::Util qw/is_plain_hashref/;
use Role::Declare::Should -lax;
use Try::Tiny;
use Types::Common::Numeric qw/PositiveOrZeroNum/;
use Types::Standard qw/ArrayRef CodeRef Dict HashRef InstanceOf Maybe Object Str Undef/;
use Types::TypeTiny qw/TypeTiny/;

our @CARP_NOT;

has scope_manager => (
    is              => 'ro',
    should          => ScopeManager,
    reader          => 'get_scope_manager',
    default => sub {
        require 'OpenTracing::Implementation::NoOp::ScopeManager';
        return OpenTracing::Implementation::NoOp::ScopeManager->new
    },
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
    
    $context = $self->build_context( )
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



sub extract_context {
    my $self = shift;
    my $carrier = shift;
    my $context = shift;
    
    my $context_formatter =
        $self->_first_context_formatter_for_carrier( $carrier );
    
    my $formatter = $context_formatter->{extractor};
    return $self->$formatter( $carrier );
}



sub inject_context {
    my $self = shift;
    my $carrier = shift;
    my $context = shift;
    
    my $context_formatter =
        $self->_first_context_formatter_for_carrier( $carrier );
    
    $context //= $self->get_active_context();
    return $carrier unless defined $context;
    my $formatter = $context_formatter->{injector};
    return $self->$formatter( $carrier, $context );
}



# XXX this is not a OpenTracing API method
#
sub get_active_context {
    my $self = shift;
    
    my $active_span = $self->get_active_span
        or return;
    
    return $active_span->get_context
}



use constant ContextFormatter => Dict[
    type      => TypeTiny,
    injector  => CodeRef,
    extractor => CodeRef,
];



has context_formatters => (
    is          => 'rw',
    should      => ArrayRef[ContextFormatter],
    handles_via => 'Array',
    handles     => {
        register_context_formatter  => 'unshift',
        known_context_formatters    => 'elements',
    },
    default     => \&_default_context_formatters,
);

sub _default_context_formatters {
    [
        {
            type      => Undef,
            injector  => sub {undef                                          },
            extractor => sub {undef                                          },
        },
        {
            type      => ArrayRef,
            injector  => sub {shift->inject_context_into_array_reference(@_) },
            extractor => sub {shift->extract_context_from_array_reference(@_)},
        },
        {
            type      => HashRef,
            injector  => sub {shift->inject_context_into_hash_reference(@_)  },
            extractor => sub {shift->extract_context_from_hash_reference(@_) },
        },
        {
            type      => InstanceOf['HTTP::Headers'],
            injector  => sub {shift->inject_context_into_http_headers(@_)    },
            extractor => sub {shift->extract_context_from_http_headers(@_)   },
        },
    ]
}

sub _first_context_formatter_for_carrier {
    my $self = shift;
    my $carrier = shift;
    
    my $context_formatter = first { $_->{type}->check($carrier) }
        $self->known_context_formatters;
    
    my $type = ref($carrier) || 'Scalar';
    croak "Unsupported carrier format [$type]"
        unless defined $context_formatter;
    
    return $context_formatter
}



instance_method extract_context_from_array_reference(
    ArrayRef                    $carrier,
) :ReturnMaybe(SpanContext) {};

instance_method extract_context_from_hash_reference(
    HashRef                     $carrier,
) :ReturnMaybe(SpanContext) {};

instance_method extract_context_from_http_headers(
    Object                      $carrier,
) :ReturnMaybe(SpanContext) {
    ( InstanceOf['HTTP::Headers'] )->assert_valid( $carrier )
};

instance_method inject_context_into_array_reference(
    ArrayRef                    $carrier,
    Maybe[ SpanContext ]        $span_context = undef,
) :Return(ArrayRef) {};

instance_method inject_context_into_hash_reference(
    HashRef                     $carrier,
    Maybe[ SpanContext ]        $span_context = undef,
) :Return(HashRef) {};

instance_method inject_context_into_http_headers(
    Object                      $carrier,
    Maybe[ SpanContext ]        $span_context = undef,
) :Return(InstanceOf['HTTP::Headers']) {
    ( InstanceOf['HTTP::Headers'] )->assert_valid( $carrier )
};


instance_method build_span (
    Str                         :$operation_name,
    SpanContext                 :$context,
    Maybe[ SpanContext | Span ] :$child_of,
    Maybe[ PositiveOrZeroNum ]  :$start_time,
    Maybe[ HashRef[Str] ]       :$tags,
) :Return (Span) { };


instance_method build_context (
    %span_context_args,
) :Return (SpanContext) {
    ( HashRef[Str] )->assert_valid( { %span_context_args } );
};


BEGIN {
#   use Role::Tiny::With;
    with 'OpenTracing::Interface::Tracer'
}



1;
