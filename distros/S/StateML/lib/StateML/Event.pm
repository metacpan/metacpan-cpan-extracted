package StateML::Event ;

use strict ;
use base qw(StateML::Object ) ;

sub new {
    return shift()->SUPER::new(
        API           => undef,
        PRE_HANDLERS  => [],
        POST_HANDLERS => [],
        HANDLERS      => [],
        @_
    ) ;
}


sub api {
    my $self = shift ;
    $self->{API} = shift if @_ ;
    return $self->{API} ;
}

sub description {
    my $self = shift ;
    $self->{DESCRIPTION} = shift if @_ ;
    return $self->{DESCRIPTION};
}

sub pre_handlers {
    my $self = shift ;
    $self->{PRE_HANDLERS} = @_ if @_ ;
    return @{$self->{PRE_HANDLERS}} ;
}


sub handlers {
    my $self = shift ;
    $self->{HANDLERS} = @_ if @_ ;
    return @{$self->{HANDLERS}} ;
}

sub post_handlers {
    my $self = shift ;
    $self->{POST_HANDLERS} = @_ if @_ ;
    return @{$self->{POST_HANDLERS}} ;
}


sub arcs {
    my $self = shift ;
    return $self->machine->arcs_for_event( $self ) ;
}

1 ;
