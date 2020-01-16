package OpenTracing::Role::Scope;

=head1 NAME

OpenTracing::Role::Scope - Role for OpenTracing implementations.

=head1 SYNOPSIS

    package OpenTracing::Implementation::MyBackendService::Scope;
    
    use Moo;
    
    with 'OpenTracing::Role::Scope'
    
    sub close => { ... }
    
    1;

=cut

use Moo::Role;

use Types::Interface qw/ObjectDoesInterface/;
use Types::Standard qw/Bool/;

=head1 DESCRIPTION

This is a Role for OpenTracing implenetations that are compliant with the
L<OpenTracing::Interface>.

=cut



has span => (
    is => 'ro',
    isa => ObjectDoesInterface['OpenTracing::Role::Span'],
    reader => 'get_span',
);



has finish_span_on_close => (
    is => 'ro',
    isa => Bool,
);



around close => sub {
    my $orig = shift;
    my $self = shift;
    
#   croak "Can't close an already closed scope"
#       if $self->_has_closed;
#   
#   $self->_set_closed_time( epoch_floatingpoint() );
    
    $self->get_span->finish
        if $self->finish_span_on_close;
    
    $orig->( $self => @_ );
#   return $self->get_scope_manager()->deactivate_scope( $self );
    
    
};



BEGIN {
#   use Role::Tiny::With;
    with 'OpenTracing::Interface::Scope'
        if $ENV{OPENTRACING_INTERFACE};
}



1;
