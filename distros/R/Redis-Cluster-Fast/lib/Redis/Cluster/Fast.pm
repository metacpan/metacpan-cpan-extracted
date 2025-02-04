package Redis::Cluster::Fast;
use 5.008001;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = "0.095";

use constant {
    DEFAULT_COMMAND_TIMEOUT => 1.0,
    DEFAULT_CONNECT_TIMEOUT => 1.0,
    DEFAULT_CLUSTER_DISCOVERY_RETRY_TIMEOUT => 1.0,
    DEFAULT_MAX_RETRY_COUNT => 5,
    DEBUG_REDIS_CLUSTER_FAST => $ENV{DEBUG_PERL_REDIS_CLUSTER_FAST} ? 1 : 0,
};

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub srandom {
    my $seed = shift;
    __PACKAGE__->__srandom($seed);
}

sub new {
    my ($class, %args) = @_;
    my $self = $class->_new;

    $self->__set_debug(DEBUG_REDIS_CLUSTER_FAST);

    croak 'need startup_nodes' unless defined $args{startup_nodes} && @{$args{startup_nodes}};
    if (my $servers = join(',', @{$args{startup_nodes}})) {
        $self->__set_servers($servers);
    }

    my $connect_timeout = $args{connect_timeout};
    $connect_timeout = DEFAULT_CONNECT_TIMEOUT unless defined $connect_timeout;
    $self->__set_connect_timeout($connect_timeout);

    my $command_timeout = $args{command_timeout};
    $command_timeout = DEFAULT_COMMAND_TIMEOUT unless defined $command_timeout;
    $self->__set_command_timeout($command_timeout);

    my $discovery_timeout = $args{cluster_discovery_retry_timeout};
    $discovery_timeout = DEFAULT_CLUSTER_DISCOVERY_RETRY_TIMEOUT unless defined $discovery_timeout;
    $self->__set_cluster_discovery_retry_timeout($discovery_timeout);

    my $max_retry = $args{max_retry_count};
    $max_retry = DEFAULT_MAX_RETRY_COUNT unless defined $max_retry;
    $self->__set_max_retry($max_retry);

    $self->__set_route_use_slots($args{route_use_slots} ? 1 : 0);

    $self->connect();
    return $self;
}

sub run_event_loop {
    my $self = shift;
    my $result = $self->__run_event_loop();
    return undef if $result == -1;
    return $result;
}

sub wait_one_response {
    my $self = shift;
    my $result = $self->__wait_one_response();
    return undef if $result == -1;
    return $result;
}

sub wait_all_responses {
    my $self = shift;
    my $result = $self->__wait_all_responses();
    return undef if $result == -1;
    return $result;
}

sub disconnect {
    my $self = shift;
    my $error = $self->__disconnect();
    croak $error if $error;
}

sub connect {
    my $self = shift;
    my $error = $self->__connect();
    croak $error if $error;
    $error = $self->__wait_until_event_ready();
    croak $error if $error;
}

### Deal with common, general case, Redis commands
our $AUTOLOAD;

sub AUTOLOAD {
    my $command = $AUTOLOAD;
    $command =~ s/.*://;
    my @command = split /_/, $command;

    my $method = sub {
        my $self = shift;
        my @arguments = @_;
        for my $index (0 .. $#arguments) {
            next if ref $arguments[$index] eq 'CODE';

            utf8::downgrade($arguments[$index], 1)
                or croak 'command sent is not an octet sequence in the native encoding (Latin-1).';
        }

        my ($reply, $error) = $self->__std_cmd(@command, @arguments);
        croak "[$command] $error" if defined $error;
        if (wantarray) {
            my $type = ref $reply;
            if ($type eq 'ARRAY') {
                return @$reply;
            } elsif ($type eq 'HASH') {
                return %$reply;
            }
        }
        return $reply;
    };

    # Save this method for future calls
    no strict 'refs';
    *$AUTOLOAD = $method;

    goto $method;
}

1;
__END__

=encoding utf-8

=head1 NAME

Redis::Cluster::Fast - A fast perl binding for Redis Cluster

=head1 SYNOPSIS

    use Redis::Cluster::Fast;

    Redis::Cluster::Fast::srandom(100);

    my $redis = Redis::Cluster::Fast->new(
        startup_nodes => [
            'localhost:9000',
            'localhost:9001',
            'localhost:9002',
            'localhost:9003',
            'localhost:9004',
            'localhost:9005',
        ],
        connect_timeout => 0.05,
        command_timeout => 0.05,
        max_retry_count => 10,
    );

    $redis->set('test', 123);

    # '123'
    my $str = $redis->get('test');

    $redis->mset('{my}foo', 'hoge', '{my}bar', 'fuga');

    # get as array-ref
    my $array_ref = $redis->mget('{my}foo', '{my}bar');
    # get as array
    my @array = $redis->mget('{my}foo', '{my}bar');

    $redis->hset('mymap', 'field1', 'Hello');
    $redis->hset('mymap', 'field2', 'ByeBye');

    # get as hash-ref
    my $hash_ref = { $redis->hgetall('mymap') };
    # get as hash
    my %hash = $redis->hgetall('mymap');

=head1 DESCRIPTION

Redis::Cluster::Fast is like L<Redis::Fast|https://github.com/shogo82148/Redis-Fast> but support Redis Cluster by L<hiredis-cluster|https://github.com/Nordix/hiredis-cluster>.

To build and use this module you need libevent-dev >= 2.x is installed on your system.

Recommend Redis 6 or higher.

Since Redis 6, it supports new version of Redis serialization protocol, L<RESP3|https://github.com/antirez/RESP3/blob/master/spec.md>.
This client start to connect using RESP2 and currently it has no option to upgrade all connections to RESP3.

=head2 MICROBENCHMARK

Simple microbenchmark comparing PP and XS.
The benchmark script used can be found under examples directory.
Each operation was executed 100,000 times, and the execution time was measured in milliseconds.

    +--------------------------------+-------+-------+-------+-------+-------+
    | Operation                      | P50   | P80   | P95   | P99   | P100  |
    +--------------------------------+-------+-------+-------+-------+-------+
    | get_pp                         | 0.028 | 0.032 | 0.036 | 0.050 | 0.880 |
    | get_xs                         | 0.020 | 0.023 | 0.025 | 0.044 | 0.881 |
    | get_xs_pipeline                | 0.014 | 0.015 | 0.018 | 0.021 | 0.472 |
    | get_xs_pipeline_batched_100    | 0.003 | 0.003 | 0.004 | 0.074 | 0.323 |
    | set_pp                         | 0.028 | 0.032 | 0.037 | 0.051 | 2.014 |
    | set_xs                         | 0.021 | 0.024 | 0.027 | 0.047 | 0.729 |
    | set_xs_pipeline                | 0.014 | 0.016 | 0.018 | 0.021 | 0.393 |
    | set_xs_pipeline_batched_100    | 0.003 | 0.004 | 0.005 | 0.073 | 0.379 |
    +--------------------------------+-------+-------+-------+-------+-------+

c.f. https://github.com/plainbanana/Redis-Cluster-Fast-Benchmarks

=head1 METHODS

=head2 srandom($seed)

hiredis-cluster uses L<random()|https://linux.die.net/man/3/random> to select a node used for requesting cluster topology.

C<$seed> is expected to be an unsigned integer value,
and is used as an argument for L<srandom()|https://linux.die.net/man/3/srandom>.

These are different implementations of Perl's rand and srand.
In this client, Perl's Drand01 is also used to determine the destination node for executing a command that is not a cluster command.

=head2 new(%args)

Following arguments are available.

=head3 startup_nodes

Specifies the list of Redis Cluster nodes.

=head3 connect_timeout

A fractional seconds. (default: 1.0)

Connection timeout to connect to a Redis node.

=head3 command_timeout

A fractional seconds. (default: 1.0)

Specifies the timeout value for each read/write event to execute a Redis Command.

=head3 max_retry_count

A integer value. (default: 5)

The client will retry calling the Redis Command only if it successfully get one of the following error responses.
MOVED, ASK, TRYAGAIN, CLUSTERDOWN.

C<max_retry_count> is the maximum number of retries and must be 1 or above.

=head3 cluster_discovery_retry_timeout

A fractional value. (default: 1.0)

Specify the number of seconds to treat a series of cluster topology requests as timed out without retrying the operation.
At least one operation will be attempted, and the time taken for the initial operation will also be measured.

=head3 route_use_slots

A value used as boolean. (default: undef)

The client will call CLUSTER SLOTS instead of CLUSTER NODES.

=head2 <command>(@args)

To run a Redis command with arguments.

The command can also be expressed by concatenating the subcommands with underscores.

    e.g. cluster_info

It does not support (Sharded) Pub/Sub family of commands and should not be run.

It is recommended to issue C<disconnect> in advance just to be safe when executing fork() after issuing the command.

=head2 <command>(@args, sub {})

To run a Redis command in pipeline with arguments and a callback.

The command can also be expressed by concatenating the subcommands with underscores.

Commands issued to the same node are sent and received in pipeline mode.
In pipeline mode, commands are not sent to Redis until C<run_event_loop>, C<wait_one_response> or C<wait_all_responses> is issued.

The callback is executed with two arguments.
The first is the result of the command, and the second is the error message.
C<$result> will be a scalar value or an array reference, and C<$error> will be an undefined value if no errors occur.
Also, C<$error> may contain an error returned from Redis or an error that occurred on the client (e.g. Timeout).

You cannot call any client methods or exceptions inside the callback.

After issuing a command in pipeline mode,
do not execute fork() without issuing C<disconnect> if all callbacks are not executed completely.

    $redis->get('test', sub {
        my ($result, $error) = @_;
        # some operations...
    });

=head2 run_event_loop()

This method allows you to issue commands without waiting for their responses.
You can then perform a blocking wait for those responses later, if needed.

Executes one iteration of the event loop to process any pending commands that have not yet been sent
and any incoming responses from Redis.

If there are events that can be triggered immediately, they will all be processed.
In other words, if there are unsent commands, they will be pipelined and sent,
and if there are already-received responses, their corresponding callbacks will be executed.

If there are no events that can be triggered immediately: there are neither unsent commands nor any Redis responses available to read,
but unprocessed callbacks remain, then this method will block for up to C<command_timeout> while waiting for a response from Redis.
When a timeout occurs, an error will be propagated to the corresponding callback(s).

The return value can be either 1 for success (e.g., commands sent or responses read),
0 for no callbacks remained, or undef for other errors.

=head3 Notes

=over 4

=item *

Be aware that the timeout check will only be triggered when there are neither unsent commands nor Redis responses available to read.
If a timeout occurs, all remaining commands on that node will time out as well.

=item *

Internally, this method calls C<event_base_loop(..., EVLOOP_ONCE)>, which
performs a single iteration of the event loop. A command will not be fully processed in a single call.

=item *

If you need to process multiple commands or wait for all responses, call
this method repeatedly or use C<wait_all_responses>.

=item *

For a simpler, synchronous-like usage where you need at least one response,
refer to C<wait_one_response>. If you only need to block until all
pending commands are processed, see C<wait_all_responses>.

=back

=head3 Example

  # Queue multiple commands in pipeline mode
  $redis->set('key1', 'value1', sub {});
  $redis->get('key2', sub {});

  # Send commands to Redis without waiting for responses
  $redis->run_event_loop();

  # Possibly wait for responses
  $redis->run_event_loop();

=head2 wait_one_response()

If there are any unexcuted callbacks, it will block until at least one is executed.
The return value can be either 1 for success, 0 for no callbacks remained, or undef for other errors.

=head2 wait_all_responses()

If there are any unexcuted callbacks, it will block until all of them are executed.
The return value can be either 1 for success, 0 for no callbacks remained, or undef for other errors.

=head2 disconnect()

Normally you should not call C<disconnect> manually.
If you want to call fork(), C<disconnect> should be call before fork().

It will be blocked until all unexecuted commands are executed, and then it will disconnect.

=head2 connect()

Normally you should not call C<connect> manually.
If you want to call fork(), C<connect> should be call after fork().

=head1 LICENSE

Copyright (C) plainbanana.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

plainbanana E<lt>plainbanana@mustardon.tokyoE<gt>

=head1 SEE ALSO

=over 4

=item L<Redis::ClusterRider|https://github.com/iph0/Redis-ClusterRider>

=item L<Redis::Fast|https://github.com/shogo82148/Redis-Fast>

=back

=cut

