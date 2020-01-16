package OpenTracing::Implementation::DataDog::Scope;

=head1 NAME

OpenTracing::Implementation::DataDog::Scope - Formailzing active spans

=head SYNOPSIS

    duno

=cut

use Moo;

with 'OpenTracing::Role::Scope';

use OpenTracing::Implementation::DataDog::Utils qw/epoch_floatingpoint/;

use Carp;
use Types::Interface qw/ObjectDoesInterface/;
use Types::Standard qw/CodeRef Num/;



has closed_time => (
    is              => 'rwp',
    isa             => Num,
    predicate       => 'has_closed',
#   trigger         => 1,
    init_arg        => undef,
);

sub _trigger_closed_time {
    my $self = shift;
    
    croak "Can't close an already closed scope"
            if $self->has_closed;
}



has after_close => (
    is              => 'ro',
    isa             => CodeRef,
    default         => sub { sub { } },
);



sub close {
    my $self = shift;
    
    croak "Can't close an already closed scope"
        if $self->has_closed;
    
    $self->_set_closed_time( epoch_floatingpoint() );
    
    return $self->after_close->( $self )
    
}



sub DEMOLISH {
    my $self = shift;
    my $in_global_destruction = shift;
    
    return if $self->has_closed;
    
    croak "Scope not programmatically closed before being demolished";
    #
    # below might be appreciated behaviour, but you should close yourself
    #
    $self->close( )
        unless $in_global_destruction;
    
    return
}



1;