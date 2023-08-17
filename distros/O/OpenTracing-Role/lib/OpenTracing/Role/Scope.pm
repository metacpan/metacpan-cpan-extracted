package OpenTracing::Role::Scope;

our $VERSION = 'v0.86.1';

use Moo::Role;
use MooX::Should;

use Carp;
use OpenTracing::Types qw/Span/;
use Types::Standard qw/Bool CodeRef Maybe/;

has span => (
    is => 'ro',
    should => Span,
    reader => 'get_span',
);

has finish_span_on_close => (
    is => 'ro',
    should => Bool,
);

has closed => (
    is              => 'rwp',
    should          => Bool,
    init_arg        => undef,
    default         => !!undef,
);

has on_close => (
    is              => 'ro',
    should          => Maybe[CodeRef],
    predicate       => 1,
);

sub close {
    my $self = shift;
    
    carp "Can't close an already closed scope" and return $self
        if $self->closed;
    
    $self->_set_closed( !undef );
    
    $self->get_span->finish
        if $self->finish_span_on_close;
    
    $self->on_close->( $self )
        if $self->has_on_close;
    
#   return $self->get_scope_manager()->deactivate_scope( $self );
    
    return $self
    
};

sub DEMOLISH {
    my $self = shift;
    my $in_global_destruction = shift;
    
    return if $self->closed;
    
    croak "Scope not programmatically closed before being demolished";
    #
    # below might be appreciated behaviour, but you should close yourself
    #
    $self->close( )
        unless $in_global_destruction;
    
    return
}



BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Interface::Scope'
}



1;
