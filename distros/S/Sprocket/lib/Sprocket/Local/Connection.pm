package Sprocket::Local::Connection;

use warnings;
use strict;

use Sprocket qw( Connection );
use base qw( Sprocket::Connection );
use POE::Filter::Stream;
use POE::Filter::Stackable;


sub new {
    my $class = shift;
    $class->SUPER::new(
        local_ip => '127.0.0.1',
        local_port => 0,
        peer_ip => '127.0.0.1',
        peer_hostname => '127.0.0.1',
        peer_port => 0,
        peer_addr => "127.0.0.1:0",
        _filter => POE::Filter::Stackable->new(
            Filters => [
                POE::Filter::Stream->new(),
            ]
        ),
        __buffer => [],
        @_
    );
}

*filter_out = *filter_in = *filter;

sub filter {
    my $self = shift;
    return $self->{_filter};
}

*write = *send;

# TODO use the filter!!

sub send {
    my $self = shift;
    
    if ( ref $self->{__callback} ) {
        $self->{__callback}->( @_ );
        return;
    } elsif ( $self->{__callback} ) {
        $poe_kernel->post( $self->{__callback} => @_ );
        return;
    }

    push( @{$self->{__buffer}}, @_ );

    return;
}

sub attach {
    my $self = shift;
    my $callback = shift;
    my $get_events = shift;

    if ( $callback ) {
        $self->{__callback} = $callback;
    }

    my $arr = $self->{__buffer};
    $self->{__buffer} = [];
    unless ( $get_events ) {
        if ( ref $self->{__callback} ) {
            foreach ( @$arr ) {
                $self->{__callback}->( $_ );
            }
        } else {
            foreach ( @$arr ) {
                $poe_kernel->post( $self->{__callback} => $_ );
            }
        }
        return;
    }

    return @$arr ? $arr : [];
}

sub detach {
    my $self = shift;
    my $get_events = shift;

    delete $self->{__callback};

    return unless ( $get_events );

    my $arr = $self->{__buffer};
    $self->{__buffer} = [];

    return @$arr ? $arr : [];
}

sub close {
    my $self = shift;
    $self->SUPER::close(@_);
    # XXX tell connector we closed?
}

1;
