require 5.008_001;

package Redis::Queue;

use warnings;
use strict;

=head1 NAME

Redis::Queue - Simple work queue using Redis

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Simple work queue using Redis, tries not to lose things when processes die.

Worker should call receiveMessage to get a unit of work, and deleteMessage once
the work is completed.  If the message isn't deleted within a given timeout,
other workers can retrieve the message again.

The queue object should be kept around for a while, because of the 'id' state
that it keeps when generating new entries.  If you have concerns about the
redis connection dropping, pass a constructor as the $redis parameter isntead
of a connection.

    use Redis::Queue;

    my $foo = Redis::Queue->new();
    ...

=head1 CONSTRUCTOR

=head2 new

 Required parameters:
  redis => handle to Redis || coderef to generate a handle to Redis
  queue => name for queue
 Optional parameters:
  timeout => length of time (in seconds) to treat received messages as reserved

=cut

sub new {
    my $class = shift;
    my $self = {@_};

    $class = ref($class) if ref($class);
    bless($self, $class);

    if ($self->{redis} and ref $self->{redis} eq 'CODE') {
        $self->{redis_constructor} = delete $self->{redis};
        $self->{redis} = $self->{redis_constructor}->();
    }

    $self->{redis} or die "Missing handle to redis\n";
    $self->{queue} or die "Missing name for queue\n";
    $self->{timeout} ||= 300;
    return $self;
}

=head1 THREADSAFE METHODS

Atomic thread-safe methods.

=head2 sendMessage

Put a message on the queue.
Returns the generated message id.

=cut
sub sendMessage {
    my $self = shift;
    my $message = shift;

    my $base = $self->_queue_base($self->{queue});

    # used for making multiple sends in a second unique
    our $unique;
    my $id = ++$unique;
    my $key = join('.', time(), $$, $id);

    $self->_call_redis('set', "$base:value:$key", $message);
    $self->_call_redis('set', "$base:fetched:$key", 0);
    $self->_call_redis('lpush',"$base:primary", $key);
    return $key;
}

=head2 receiveMessage

Get a message from the queue.
Returns (id,value).  You must use the id to delete the message when done.

=cut
sub receiveMessage {
    my $self = shift;

    my $base = $self->_queue_base($self->{queue});
    my $threshold = time() - $self->{timeout};

    # Find out (approximately) how long the list is.
    # Sure, it could change while we're walking the list,
    # but this is just to keep us from walking forever.
    my $count = $self->_call_redis('llen', "$base:primary");
    while ($count--) {
        # Iterate through all the keys.
        # It doesn't matter if we miss a couple because other workers are grabbing them...
        # that just means that somebody else will do the work.
        my $key = $self->_call_redis('rpoplpush', "$base:primary", "$base:primary");

        # Quit if there aren't any keys left.
        return unless $key;

        # Check the timestamp, to make sure nobody else is processing the message.
        my $now = time();
        my $fetched = $self->_call_redis('getset', "$base:fetched:$key", $now);
        if ($fetched < $threshold) {
            my $message = $self->_call_redis('get', "$base:value:$key");
            return ($key, $message);
        }

        # Restore the original fetched timestamp (if different from what we put in).
        # The conditional is important if there's a bunch of workers hammering the queue.
        $self->_call_redis('set', "$base:fetched:$key", $fetched) if $fetched < $now;
    }

    # Didn't find anything workable in the queue.  Oh, well.
    return;
}

=head2 deleteMessage

Delete a message from the queue by id.

=cut
sub deleteMessage {
    my $self = shift;
    my $key = shift;

    my $base = $self->_queue_base($self->{queue});
    $self->_call_redis('lrem', "$base:primary", 0, $key);
    $self->_call_redis('del', "$base:fetched:$key");
    $self->_call_redis('del', "$base:value:$key");
}

=head1 NON-THREADSAFE METHODS

These methods return results that may not accurately represent the state of
the queue by the time you read their results.

=head2 length

Get the length of the queue.  It may have changed by the time you read it
but it's good for a general idea of how big the queue is.

=cut
sub length {
    my $self = shift;

    my $base = $self->_queue_base($self->{queue});

    return $self->_call_redis('llen', "$base:primary");
}

=head2 nuke

Delete all storage associated with the queue.  Messy things may happen if
something else is trying to use the queue at the same time this runs.  On the
other hand, it shouldn't be fatal, but still leaves the the possibility of
leaving some stuff behind.

=cut
sub nuke {
    my $self = shift;

    my $base = $self->_queue_base($self->{queue});

    my @keys = $self->_call_redis('keys', "$base:*");

    # Do the primary first, to try to avoid issues if someone uses/recreates the queue while we're nuking it.
    $self->_call_redis('del', "$base:primary");
    # Nuke everything other than the primary.
    # May still miss some entries if stuff was added between the keys listing and the nuking of the primary...
    for my $key (grep($_ ne "$base:primary", @keys)) {
        $self->_call_redis('del', $key);
    }
}

=head2 peekMessages

Peek at some number of messages on the queue (defaults to 10).  In particular,
if there are workers deleting entries, this may return fewer entries than
requested, even if there are more messages on the queue.

=cut
sub peekMessages {
    my $self = shift;
    my $max = shift || 10;

    my $base = $self->_queue_base($self->{queue});

    my @result;
    my @keys = $self->_call_redis('lrange', "$base:primary", 0, $max - 1);
    for my $key (@keys) {
        my $message = $self->_call_redis('get', "$base:value:$key");
        push(@result, $message) if $message;
    }
    return @result;
}

=head2 queues

Get the list of queues hosted on the redis server.

=cut
sub queues {
    my $redis = shift;
    $redis = shift if $redis eq 'Redis::Queue';
    $redis = $redis->{redis} if ref($redis) eq 'Redis::Queue';

    my @queues;
    if (@_) {
        for my $pattern (@_) {
            push(@queues, $redis->keys("queue:$pattern:primary"));
        }
    }
    else {
        push(@queues, $redis->keys("queue:*:primary"));
    }

    s/queue:(.*):primary/$1/
        for @queues;

    return @queues;
}

=head1 PRIVATE METHODS

Documentation here provided for developer reference.

=head2 _queue_base

Accessor method for the queue key-name prefix

=cut
sub _queue_base {
    my ($self, $queue) = @_;
    return "queue:$queue";
}

=head2 _call_redis

Send a request to Redis

=cut
sub _call_redis {
    my ($self, $method, @args) = @_;

    my @return;
    for (1..3) {
        @return = eval {
            return $self->{redis}->$method(@args);
        };
        last unless $@;

        warn "Error while calling redis: $@";

        if ($_ < 3) {
            if ($self->{redis_constructor}) {
                $self->{redis} = $self->{redis_constructor}->();
            }
            else {
                die "No constructor, can't reconnect to redis.\n";
            }
        } else {
            die "ETOOMANYERRORS\n";
        }
    }

    return wantarray ? @return : $return[0];
}

=head1 AUTHOR

Alex Popiel, C<< <tapopiel+redisqueue at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-redis-queue at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Redis-Queue>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Redis::Queue

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/Redis-Queue/>

=item * AnnoCPAN: Annotated CPAN documentation

=back

=head1 ACKNOWLEDGEMENTS

Thank you to Marchex L<http://www.marchex.com/> for allowing time to be spent
developing and maintaining this library.
Thanks also to Chris Petersen for major assistance in packaging of this library.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alex Popiel.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for more information.

=cut

1; # End of Redis::Queue
