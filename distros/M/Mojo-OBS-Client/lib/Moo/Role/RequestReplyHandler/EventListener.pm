package Moo::Role::RequestReplyHandler::EventListener;
use strict;
use Moo;
use Carp 'croak';
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

our $VERSION = '0.01';

has 'target' => (
    is => 'ro',
    weak_ref => 1,
);

has 'callback' => (
    is => 'ro',
);

has 'event' => (
    is => 'ro',
);

around BUILDARGS => sub( $orig, $class, %args ) {
    croak "Need an event" unless $args{ event };
    croak "Need a callback" unless $args{ callback };
    croak "Need a target in target" unless $args{ target };
    return $class->$orig( %args )
};

sub notify( $self, @info ) {
    $self->callback->( @info )
}

sub unregister( $self ) {
    $self->target->remove_listener( $self )
        if $self->target; # it's a weak ref so it might have gone away already
    undef $self->{target};
}

sub DESTROY {
    $_[0]->unregister
}

1;
