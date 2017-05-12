package Sque::Worker;
$Sque::Worker::VERSION = '0.010';
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use Try::Tiny;

with 'Sque::Encoder';

# ABSTRACT: Does the hard work of babysitting Sque::Job's

has _dying => (is => 'rw', default => 0);

has logger => (is => 'rw');

has sque => (
    is => 'ro',
    required => 1,
    handles => [qw/ stomp key /]
);

has queues => (
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    default => sub {{}}
);

has verbose => ( is => 'rw', default => sub {0} );

sub BUILD {
    my ($self) = @_;

    my $die_handler = sub {
        my ($signal) = @_;
        $self->log("Received $signal signal, dying...");
        $self->_dying(1);
    };

    # Setup die handlers
    $SIG{$_} = $die_handler for qw(INT TERM KILL QUIT)
}

sub work {
    my ( $self ) = @_;
    while( my $job = $self->sque->pop ) {
        $job->worker($self);
        my $reval = $self->perform($job);
        exit 0 if $self->_dying;
    }
}

sub perform {
    my ( $self, $job ) = @_;
    my $ret;
    try {
        $ret = $job->perform;
        $self->log( sprintf( "done: %s", $job->stringify ) );
    } catch {
        $self->log( sprintf( "%s failed: %s", $job->stringify, $_ ) );
    };
    $self->stomp->ack({ frame => $job->frame });
    return $ret;
}

sub reserve {
    my ( $self ) = @_;
    return $self->sque->pop;
}

sub add_queues {
    my $self = shift;
    return unless @_;
    for my $q ( @_ ) {
        if(!$self->queues->{$q}){
            $self->queues->{$q} = 1;
            my $queue = $self->sque->key( $q );
            $self->_subscribe_queue( $queue );
        }
    }
    return $self;
}

sub log {
    my $self = shift;
    $self->logger->DEBUG(@_) if $self->verbose and $self->logger;
}

sub _subscribe_queue {
    my ( $self, $q ) = @_;
    $self->stomp->subscribe( {
        destination => $q,
        ack         => 'client',
    } );
};

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sque::Worker - Does the hard work of babysitting Sque::Job's

=head1 VERSION

version 0.010

=head1 ATTRIBUTES

=head2 sque

The L<Sque> object running this worker.

=head2 queues

Queues this worker should fetch jobs from.

=head2 verbose

Set to a true value to make this worker report what's doing while
on work().

=head1 METHODS

=head2 work

Calling this method will make this worker to start pulling & running jobs
from queues().

This is the main wheel and will run while shutdown() is false.

=head2 perform

Call perform() on the given Sque::Job capturing and reporting
any exception.

=head2 reserve

Call reserve() to return the next job popped of the queue(s)

=head2 add_queues

Add a queue this worker should listen to.

=head2 log

If verbose() is true, this will print to STDERR.

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
