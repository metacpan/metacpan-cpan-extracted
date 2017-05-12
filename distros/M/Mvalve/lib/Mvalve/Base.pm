# $Id: /mirror/coderepos/lang/perl/Mvalve/trunk/lib/Mvalve/Base.pm 72443 2008-09-08T14:21:42.664054Z daisuke  $

package Mvalve::Base;
use Moose;
use Mvalve;
use Mvalve::QueueSet;
use Mvalve::Logger;
use Mvalve::Types;
use Time::HiRes;
use Scalar::Util ();

with 'MooseX::KeyedMutex';

has 'logger' => (
    is       => 'rw',
    does     => 'Mvalve::Logger',
    coerce   => 1
);

has 'queue' => (
    is       => 'rw',
    does     => 'Mvalve::Queue',
    required => 1,
    coerce   => 1,
    handles => {
        map { ( "q_$_" => $_ ) }
            qw(next fetch insert clear)
    },
);

{
    my $default = sub {
        my $class = shift;
        return sub {
            Class::MOP::load_class($class);
            $class->new;
        };
    };

    has 'queue_set' => (
        is  => 'rw',
        isa => 'Mvalve::QueueSet',
        required => 1,
        default => $default->( 'Mvalve::QueueSet' )
    );

    has 'state' => (
        is => 'rw',
        does => 'Mvalve::State',
        coerce => 1,
        required => 1,
        default => $default->( 'Mvalve::State::Memory' ),
        handles => {
            map { ("state_$_" => $_) } qw(get set remove incr decr)
        }
    );
}

__PACKAGE__->meta->make_immutable;

no Moose;

sub log {
    my $self = shift;
    my $logger = $self->logger ;
    return () unless $logger;

    $logger->log(@_);
}

sub clear_all {
    my $self = shift;

    foreach my $table ($self->queue_set->all_tables) {
        $self->q_clear($table);
    }
}

sub defer
{
    my( $self, %args ) = @_;

    my $message  = $args{message};
    my $interval = $args{interval} || 0;
    my $duration = $args{duration} ||
        $message->header( &Mvalve::Const::DURATION_HEADER ) ||
        0;

    my $factor = 100_000;
    $interval *= $factor;
    $duration *= $factor;

    if ( ! Scalar::Util::blessed($message) || ! $message->isa( 'Mvalve::Message' ) ) {
        return () ;
    }

    my $qs          = $self->queue_set;
    my $destination = $message->header( &Mvalve::Const::DESTINATION_HEADER );
    my $time_key    = [ $destination, 'retry time' ];
    my $retry_key   = [ $destination, 'retry' ];

    my $done = 0;
    my $rv;
    while (! $done) {
        my $lock = $self->lock( join('.', @$time_key ) );
        next unless $lock;

        $done = 1;

        my $now    = Time::HiRes::time() * $factor;
        my $retry  = int($self->state_get($time_key) || $now);

        # we always prefer duration
        my $offset = $duration || $interval;
        my $myturn = 0;

        if ($retry > $now) {
            $myturn = $retry;
        } else {
            if ( $retry + $offset >= $now ) {
                $myturn = $retry + $offset;
            } else {
                $myturn = $now;
            }
        }
        my $next   = $myturn + $offset;

        $message->header( &Mvalve::Const::RETRY_HEADER, $myturn );

        Mvalve::trace( "defer (retry = $retry)" ) if &Mvalve::Const::MVALVE_TRACE;
        $rv = $self->q_insert( 
            table => $qs->choose_table('timed'),
            data => {
                destination => $destination,
                ready       => $myturn,
                message     => $message->serialize,
            }
        );

        Mvalve::trace( "q_insert results in $rv" ) if &Mvalve::Const::MVALVE_TRACE;

        if ($rv) {
            $self->state_set($time_key, $next);
        }
    }

    return $rv;
}

1;

__END__

=head1 NAME

Mvalve::Base - Base Class For Mvalve Reader/Writer

=head1 METHODS

=head2 defer

Inserts in the the retry_wait queue.

=head2 clear_all

Clears all known queues that are listed under the registered QueueSet

=head2 queue

C<queue> is the actual queue instance that we'll be dealing with.
While the architecture is such that you can replace the queue with
your custom object, we currently only support Q4M

  $self->queue( {
    module => "Q4M",
    connect_info => [ 'dbi:mysql:...', ..., ... ]
 } );

=cut