package StateML::Arc ;

use strict ;

use base qw(StateML::Object ) ;

use StateML::Utils qw( empty );
use Carp qw( confess );

=head1 NAME

StateML::Arc - A transition between states

=head1 DESCRIPTION

An arc is a transition between states; they occur by default or
on certain events.

A loopback arc is an arc that transits from a state back to itself.

Arcs can have handlers, either explicitly using one or more <handler>s or
by reference to an <action> using an action-id attribute (we need to
allow arcs to have multiple actions at some point).

Arcs can contain an <event>, in which case the <arc>'s event-id= is
automatically read from the <event> (which in turn may omit it and let
StateML::Machine assign one).

=head2 Default from/to state ids.

On parsing, <arc> elements may appear in <state> elements.  When they
do, the from= and/or to= attributes may be omitted; they will default to
the parent state's id.

=head1 METHODS (incomplete, see the source, luke)

=over

=cut

=item event

Returns the event for this arc, if set.

=cut

sub event {
    my $self = shift;

    $self->event_id( $_[0]->id ) if @_;

    return unless defined wantarray;

    my $event_id = $self->event_id;
    return undef unless defined $event_id;

    confess "arc is not in a machine, can't fetch the event"
        unless $self->machine;

    my $event = $self->machine->event_by_id( $event_id );

    confess "event ", as_str( $event_id ), " is not in machine"
        unless $event;

    return $event;
}

=item event_id

Returns the event_id if set.  If not set (undef), returns the default event's
ID if it is present in the machine.  Note that "" is a I<not> valid id.

=cut

sub event_id {
    my $self = shift ;

    $self->{EVENT_ID} = shift if @_ ;
    return $self->{EVENT_ID} if defined $self->{EVENT_ID};

    my $default_event =
        $self->machine && $self->machine->event_by_id( "#DEFAULT" );

    return $default_event ? $default_event->id : undef;
}

=item name

Returns the name if set.  If not set, returns the name of the event_id
event (if that's set).  Note that "" I<is> a valid name.

=cut

sub name {
    my $self = shift;

    $self->SUPER::name( @_ ) if @_;
    return $self->{NAME} if defined $self->{NAME};

    my $event = $self->event if $self->machine;

    return $event->name;
}

sub from {
    my $self = shift ;
    $self->{FROM} = shift if @_ ;
    return $self->{FROM} ;
}

sub to {
    my $self = shift ;
    $self->{TO} = shift if @_ ;
    return $self->{TO} ;
}

sub guard {
    my $self = shift ;
    $self->{GUARD} = shift if @_ ;
    return $self->{GUARD} ;
}

sub from_state {
    my $self = shift ;
    $self->{FROM} = shift()->id if @_ ;
    return $self->machine->state_by_id( $self->{FROM} ) ;
}

sub to_state {
    my $self = shift ;
    $self->{TO} = shift()->id if @_ ;
    return $self->machine->state_by_id( $self->{TO} ) ;
}

sub description {
    my $self = shift ;
    $self->{DESCRIPTION} = shift if @_ ;
    return $self->{DESCRIPTION};
}

sub handlers {
    my $self = shift ;
    $self->{HANDLERS} = @_ if @_ ;
    return map ref $_
        ? do {
            my $action = $self->machine->action_by_id( $$_ );
            die "Action $$_ for arc ",
                $self->name,
                " (id ",
                $self->id,
                ") not defined\n"
                unless $action;
            $action->handlers;
        }
        : $_,
        @{$self->{HANDLERS}} ;
}


sub handler_descriptions {
    my $self = shift ;
    return map ref $_
        ? do {
            my $action = $self->machine->action_by_id( $$_ );
            die "Action $$_ for arc ",
                $self->name,
                " (id ",
                $self->id,
                ") not defined\n"
                unless $action;
            my $desc = $action->description;
            defined $desc ? $desc : $action->handlers;
        }
        : $_,
        @{$self->{HANDLERS}} ;
}


sub add_handler {
    my $self = shift ;
    push @{$self->{HANDLERS}}, @_ ;
}


sub handler_attributes {
    my $self = shift ;
    return map ref $_
        ? do {
            my $action = $self->machine->action_by_id( $$_ );
            die "Action $$_ for arc ",
                $self->name,
                " (id ",
                $self->id,
                ") not defined\n"
                unless $action;
            $action->attributes( @_ );
        }
        : (),
        @{$self->{HANDLERS}} ;
}


=item attribute

Like StateML::Object::attribute, but inherits from the event.

=cut

sub attribute {
    my $self = shift ;

    my $a = $self->SUPER::attribute( @_ ) ;
    if ( @_ < 3 && ! defined $a ) {
        my $e = $self->machine->object_by_id( $self->event_id ) ;
        $a = $e->attribute( @_ ) if defined $e ;
    }
    return $a ;
}


=item attributes

Like StateML::Object::attributes, but inherits from all handlers and then
the event.

=cut

sub attributes {
    my $self = shift ;

    my $e = $self->machine->object_by_id( $self->event_id ) ;
    my @ea ;
    @ea = $e->attributes( @_ ) if defined $e ;
    my @ha = $self->handler_attributes( @_ );

    my %a = ( @ha, @ea, $self->SUPER::attributes( @_ ) ) ;
    return %a ;
}

=back

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut


1 ;
