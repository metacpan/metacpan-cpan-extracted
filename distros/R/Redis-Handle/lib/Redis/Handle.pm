package Redis::Handle;
use strict;
use warnings;
use Carp;
use Redis;
use AnyEvent::Redis;

our $VERSION = '0.2.0'; # VERSION
# ABSTRACT: Tie::Handle interface for Redis queues

# use Data::Dump qw(pp);

=head1 NAME

Redis::Handle - A filehandle tie for a Redis queue

=head1 SYNOPSIS

    tie *REDIS, 'Redis::Handle';
    print REDIS "Foo bar baz\n";
    print while <REDIS>;        # Prints "Foo bar baz\n"
    
    print REDIS "Foo", "Bar";
    my @baz = <REDIS>;          # @baz is now ("Foo","Bar")
    
    print REDIS "Foo", "Bar";
    print <REDIS>;              # Prints "Foo"

=head1 DESCRIPTION

C<Redis::Handle> implements a tie interface to a Redis queue so that you can
treat said queue as a filehandle. Pushing to the front of the queue is the same
as a C<print>, and popping off the end of the queue is like a C<readline>.

=cut

{
    my $timeout = 30;   # For BLPOPs, in seconds
    my $redis;          # We want only a single Redis connection
    my %redis;          # Connection information

=head1 METHODS

=head2 TIEHANDLE

Ties the filehandle to the clientId in Redis.

=head3 Usage

    tie *CLIENT, "Redis::Handle", $clientId;
    
    tie *CLIENT, 'Redis::Handle', $clientId,
        timeout => 100,
        host => 'example.com',
        port => 5800;
    
    # pass an existing Redis connection
    tie *CLIENT, 'Redis::Handle', $clientId, $redis;

=cut

    sub TIEHANDLE {
        my ($class,$clientId) = (+shift,+shift);
        $redis = shift if ref $_[0];
        %redis = @_;
        $redis ||= Redis->new(%redis);

        if ($redis{timeout}) {
            $timeout = $redis{timeout};
            delete $redis{timeout};
        }

        bless \$clientId, $class;
    }

=head2 PRINT

Sends the message(s) to the client. Since we're using an AnyEvent connection,
events are still processed while waiting on Redis to process the push,
including asynchronously pushing _other_ messages.

=head3 Usage

    print CLIENT nfreeze({ text => "foo", from => "bar" });
    print CLIENT nfreeze({ text => "foo" }), nfreeze({ text => "bar" }), "System message";

=cut
    sub PRINT {
        my $this = shift;
        $redis->ping or $redis = Redis->new(%redis);
        foreach (@_) {
            $redis->lpush($$this, $_) or
                croak qq{Failed to push message [$_] to [$$this]: $!};
        }
        return 1;
    }

=head2 READLINE

Reads the next message or flushes the message queue (depending on context).
This is a "blocking" operation, but, because we're using AnyEvent::Redis, other
events are still processed while we wait. Since Redis's C<BLPOP> operation
blocks the whole connection, this spawns a separate AnyEvent::Redis connection
to deal with the blocking operation.

=head3 Usage

    my $message = <CLIENT>;     # Reads only the next one
    my @messages = <CLIENT>;    # Flushes the message queue into @messages

=cut
    sub READLINE {
        my $this = shift;
        $redis->ping or $redis = Redis->new(%redis);
        my $r = AnyEvent::Redis->new(%redis) or
            croak qq(Couldn't create AnyEvent::Redis connection to [@{[%redis]}]: $!);
        my $message;
        until ($message) {
            my $cv = $r->brpop($$this, $timeout, sub {
                $message = $_[0][1];
            }) or croak qq{Couldn't BRPOP from [$$this]: $!};
            $cv->recv;
        }
        $r->quit; undef $r;
        return $message unless wantarray;
        return ($message, _flush($this));
    }

=for READLINE

Helper methods for READLINE

If you pass C<_flush> a nonzero number, it will read that many messages. An
explicit "0" means "read nothing", while an C<undef> means "read everything".

=cut
    sub _flush {
        my ($this,$count) = @_;
        my @messages;
        while (my $m = $redis->rpop($$this)) {
            last if defined $count && --$count < 0;
            push @messages, $m;
        }
        return @messages;
    }

=head2 EOF

Just like the regular C<eof> call. Returns 1 if the next read will be the end
of the queue or if the queue isn't open.

=cut
    sub EOF {
        my $this = shift;
        return not _len($this);
    }

=for EOF,READLINE

Returns the length of the buffer.

=cut
    sub _len {
        my $this = shift;
        return $redis->llen($$this);
    }

=head2 poll_once

Returns the C<AnyEvent::Condvar> of the a blocking pop operation on a Redis queue.
This is useful if, for example, you want to handle a C<BLPOP> as an asynchronous
PSGI handler, since a standard C<READLINE> operation throws a "recursive blocking
wait" exception (because you're waiting on a C<CondVar> that's waiting on a
C<CondVar>). It takes a C<tied> variable, an optional C<count> of the maximum
number of messages to return, and a callback as its arguments.

=head3 Usage

    sub get {
        my ($self,$clientId) = (+shift,+shift);
        my $output = tie local *CLIENT, 'Redis::MessageQueue', "$clientId:out";
        $output->poll_once(sub {
            $self->write(+shift);
            $self->finish;
        });
    }

=cut
    sub poll_once {
        my $fn = pop;
        my ($this,$count) = @_;
        my $r = AnyEvent::Redis->new(%redis);
        $r->brpop($$this, $timeout, sub {
            my $message = $_[0][1];
            $r->quit; undef $r;
            return $fn->($message, _flush($this,$count));
        });
    }

=head2 CLOSE

Cleanup code so that we don't end up with a bunch of open filehandles.

=cut
    sub CLOSE {
        # The elements of @_ are *aliases*, not copies, so undefing $_[0] marks
        # the caller's typeglob as empty.
        $redis->ping;
        undef $_[0];
    }

}
1;
