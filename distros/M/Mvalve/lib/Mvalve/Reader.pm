# $Id$

package Mvalve::Reader;
use Moose;
use Mvalve;
use Mvalve::Const;
use Mvalve::Types;

extends 'Mvalve::Base';

has 'timeout' => (
    is => 'rw',
    isa => 'Num',
    required => 1,
    default => 60
);

has 'throttler' => (
    is       => 'rw',
    does     => 'Mvalve::Throttler',
    required => 1,
    coerce   => 1,
    handles  => [ qw(try_push fill) ],
);

has 'drop_on_emergency' => (
    is => 'rw',
    isa => 'Bool',
    required => 1,
    default => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub next
{
    my $self = shift;

    my $qs    = $self->queue_set;
    my @names = $qs->as_q4m_args;

    Mvalve::trace("queue_wait with @names") if &Mvalve::Const::MVALVE_TRACE;
    my $table = $self->q_next(
        table_conds => \@names, 
        timeout     => $self->timeout + 0
    );

    if (! $table) {
        Mvalve::trace( "q_next did not return a table name, simply returning" ) if &Mvalve::Const::MVALVE_TRACE;
        return ();
    }

    Mvalve::trace( "issueing fetch on table '$table'") if &Mvalve::Const::MVALVE_TRACE;

    my $message = $self->q_fetch(table => $table);
    if (! $message) {
        Mvalve::trace( "q_fetch did not return a message, simply returning" ) if &Mvalve::Const::MVALVE_TRACE;
        return ();
    }

    my $destination = $message->header( &Mvalve::Const::DESTINATION_HEADER );

    if (&Mvalve::Const::MVALVE_TRACE && $qs->is_timed( $table )) {
        Mvalve::trace( "we should have dispatched at " . 
            scalar( localtime( $message->header( &Mvalve::Const::RETRY_HEADER )  /100_000 ) ) );
    }

    # destination is an abstract symbol representing the endpoint
    # service name. this /could/ be used by the queue consumer, but it
    # is *not* a

    my $emerg_key = [ $destination, 'emergency' ];
    if ( $qs->is_emergency( $table ) ) {
        if ($self->drop_on_emergency) {
            my $duration = $message->header(&Mvalve::Const::DURATION_HEADER)
                || $self->throttler->interval;
            $self->state_set($emerg_key, time + $duration);
        }
        else {
            $self->fill( key => $destination ) 
        }

        goto RETURN_MESSAGE;
    }

    my $avail_time = $self->state_get($emerg_key);
    if ($avail_time && time < $avail_time) {
        return (); # drop message!
    }

    if ( $qs->is_timed( $table ) ) {
        # if this is from an emergency queue or a timed queue, we go ahead
        # and allow the message, but we also update the throttler's count
        # so the next message from a normal queue would be throttled correctly
        if ($message->header(&Mvalve::Const::RETRY_HEADER)) {
            $self->state_decr( [ $destination, 'retry' ] );
        }
        $self->fill( key => $destination );

        # XXX - This is bad practive, but oh well
        goto RETURN_MESSAGE;
    }

    # otherwise, we need to check if this message is going to be throttled
    my $is_pending   = $self->is_pending( $destination );
    my $is_throttled = ! $self->try_push( key => $destination );
    Mvalve::trace( "checking if message to $destination should be throttled (pending: $is_pending, throttled: $is_throttled)" ) if &Mvalve::Const::MVALVE_TRACE;

    if ($is_throttled || $is_pending) {
        Mvalve::trace( "message", $message->id, "is being throttled") if &Mvalve::Const::MVALVE_TRACE;
        $self->defer( 
            message => $message,
            interval => $self->throttler->interval,
        );
        $self->log(
            action => "throttle",
            destination => $destination
        );
        return (); # no data for you!
    }

RETURN_MESSAGE:
    # if we got here, we can just return the data
    Mvalve::trace( "message", $message->id, "being returned") if &Mvalve::Const::MVALVE_TRACE;
    $self->log(
        action => "dequeue",
        destination => $destination,
    );
    return $message;
}

sub is_pending {
    my( $self, $destination ) = @_;

    my $retry_key = [ $destination, 'retry' ];
    my $count = $self->state_get($retry_key);
    return $count ? 1 : 0;
}

1;

__END__

=head1 NAME

Mvalve::Reader - Mvalve Reader

=head1 METHODS

=head2 next

Fetches the next available message. 

=head2 is_pending( $destination )

Checks whethere there are pending retries for that particular destination.

=head2 throttler

C<throttler> holds the Data::Throttler instance that does the dirty work of
determining if a message needs to be throttled or not

  $self->throttler( {
    module => "Data::Throttler::Memcached",
  } );

=head2 timeout

C<timeout> specifies the timeout value while we wait to read from the queue.

=head2 drop_on_emergency

C<drop_on_emergency> specifies if given a emergency message, other messages
should be dropped while the emergency message is being displayed.

By default this is C<true>.

=cut

