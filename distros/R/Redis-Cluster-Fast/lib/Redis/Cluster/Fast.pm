package Redis::Cluster::Fast;
use 5.008001;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = "0.088";

use constant {
    DEFAULT_COMMAND_TIMEOUT => 1.0,
    DEFAULT_CONNECT_TIMEOUT => 1.0,
    DEFAULT_MAX_RETRY_COUNT => 5,
};

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my ($class, %args) = @_;
    my $self = $class->_new;

    $self->__set_debug($args{debug} ? 1 : 0);

    croak 'need startup_nodes' unless defined $args{startup_nodes};
    if (my $servers = join(',', @{$args{startup_nodes}})) {
        $self->__set_servers($servers);
    }

    my $connect_timeout = $args{connect_timeout};
    $connect_timeout = DEFAULT_CONNECT_TIMEOUT unless defined $connect_timeout;
    $self->__set_connect_timeout($connect_timeout);

    my $command_timeout = $args{command_timeout};
    $command_timeout = DEFAULT_COMMAND_TIMEOUT unless defined $command_timeout;
    $self->__set_command_timeout($command_timeout);

    my $max_retry = $args{max_retry_count};
    $max_retry = DEFAULT_MAX_RETRY_COUNT unless defined $max_retry;
    $self->__set_max_retry($max_retry);

    my $error = $self->__connect();
    croak $error if $error;
    return $self;
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

To build this module you need at least autoconf, automake, libtool, pkg-config are installed on your system.

Recommend Redis 6 or higher.

Since Redis 6, it supports new version of Redis serialization protocol, L<RESP3|https://github.com/antirez/RESP3/blob/master/spec.md>.
This client start to connect using RESP2 and currently it has no option to upgrade all connections to RESP3.

=head2 MICROBENCHMARK

Simple microbenchmark comparing PP and XS.
The benchmark script used can be found under examples directory.

    Redis::Cluster::Fast is 0.084
    Redis::ClusterRider is 0.26
    ### mset ###
                            Rate  Redis::ClusterRider Redis::Cluster::Fast
    Redis::ClusterRider  13245/s                   --                 -34%
    Redis::Cluster::Fast 20080/s                  52%                   --
    ### mget ###
                            Rate  Redis::ClusterRider Redis::Cluster::Fast
    Redis::ClusterRider  14641/s                   --                 -40%
    Redis::Cluster::Fast 24510/s                  67%                   --
    ### incr ###
                            Rate  Redis::ClusterRider Redis::Cluster::Fast
    Redis::ClusterRider  18367/s                   --                 -44%
    Redis::Cluster::Fast 32879/s                  79%                   --
    ### new and ping ###
                           Rate  Redis::ClusterRider Redis::Cluster::Fast
    Redis::ClusterRider   146/s                   --                 -96%
    Redis::Cluster::Fast 3941/s                2598%                   --

=head1 METHODS

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

=head2 <command>(@args)

To run a Redis command with arguments.

The command can also be expressed by concatenating the subcommands with underscores.

    e.g. cluster_info

It does not support (Sharded) Pub/Sub family of commands and should not be run.

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

