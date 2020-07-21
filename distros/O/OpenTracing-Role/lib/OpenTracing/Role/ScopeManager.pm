package OpenTracing::Role::ScopeManager;

our $VERSION = 'v0.84.0';

use Moo::Role;

use Carp;
use OpenTracing::Types qw/Scope Span assert_Scope/;
use Role::Declare;
use Types::Standard qw/Bool CodeRef Dict Maybe/;

# The chosen design is to have only 1 active scope and use callback to change
# what the 'previous' scope would be when we close a scope.
#
# An other design could be building a stack, using 'push/pop' to keep track of
# which one to activate on close.
#
has active_scope => (
    is => 'rwp',
    isa => Scope,
    init_arg => undef,
    reader => 'get_active_scope',
    writer => 'set_active_scope',
);

sub activate_span {
    my $self = shift;
    my $span = shift or croak "Missing OpenTracing Span";
    
    my $options = { @_ };
    
    my $finish_span_on_close = 
        exists( $options->{ finish_span_on_close } ) ?
            !! delete $options->{ finish_span_on_close }
            : !undef
    ; # use 'truthness' of param if provided, or set to 'true' otherwise
    
    my $scope = $self->build_scope(
        span                 => $span,
        finish_span_on_close => $finish_span_on_close,
        %$options,
    );
    
    $self->set_active_scope( $scope );
    
    return $scope
}

instance_method build_scope (
    Span :$span,
    Bool :$finish_span_on_close
) :Return ( Scope ) { };



BEGIN {
#   use Role::Tiny::With;
    with 'OpenTracing::Interface::ScopeManager'
        if $ENV{OPENTRACING_INTERFACE};
}

1;
