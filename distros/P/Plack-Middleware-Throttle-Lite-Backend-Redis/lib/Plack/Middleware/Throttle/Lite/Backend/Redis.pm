package Plack::Middleware::Throttle::Lite::Backend::Redis;

# ABSTRACT: Redis-driven storage backend for Throttle-Lite

use strict;
use warnings;
use Carp ();
use parent 'Plack::Middleware::Throttle::Lite::Backend::Abstract';
use Redis 1.955;

our $VERSION = '0.04'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

__PACKAGE__->mk_attrs(qw(redis rdb));

sub init {
    my ($self, $args) = @_;

    my $croak = sub { Carp::croak $_[0] };

    my %options = (
        debug     => $args->{debug}     || 0,
        reconnect => $args->{reconnect} || 10,
        every     => $args->{every}     || 100,
    );

    $options{password} = $args->{password} if $args->{password};

    my $instance = $self->_parse_instance($args->{instance});

    if ($instance->{unix}) {
        $croak->("Nonexistent redis socket ($instance->{thru})!") unless -e $instance->{thru} && -S _;
    }

    $options{ $instance->{unix} ? 'sock' : 'server' } = $instance->{thru};

    $self->rdb($args->{database} || 0);

    my $_handle = eval { Redis->new(%options) };
    $croak->("Cannot get redis handle: ". ($@ || $instance->{thru})) unless ref($_handle) eq 'Redis';

    $self->redis($_handle);
}

sub _parse_instance {
    my ($self, $instance) = @_;

    my $params = { unix => 0, thru => '127.0.0.1:6379' };

    # slightly improved piece of code from Redis.pm by Pedro Melo (cpan:MELO)
    CHANCE: {
        last CHANCE unless $instance;

        if ($instance =~ m,^(unix:)?(/.+)$,i) {
            $params->{thru} = $2;
            $params->{unix} = 1;
            last CHANCE;
        }
        if ($instance =~ m,^((tcp|inet):)?(.+)$,i) {
            my ($server, $port) = ($3, undef);
            ($server, $port)    = split /:/, $server;
            $params->{thru}     = lc($server) . ':' . (($port && ($port > 0 && $port <= 65535)) ? $port : '6379');
        }
    }

    $params;
}

sub increment {
    my ($self) = @_;

    $self->redis->select($self->rdb);
    $self->redis->incr($self->cache_key);
    $self->redis->expire($self->cache_key, 1 + $self->expire_in);

}

sub reqs_done {
    my ($self) = @_;

    $self->redis->select($self->rdb);
    $self->redis->get($self->cache_key) || 0;
}

1; # End of Plack::Middleware::Throttle::Lite::Backend::Redis

__END__

=pod

=head1 NAME

Plack::Middleware::Throttle::Lite::Backend::Redis - Redis-driven storage backend for Throttle-Lite

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This is implemetation of the storage backend for B<Plack::Middleware::Throttle::Lite>. It uses redis-server
to hold throttling data, automatically sets expiration time for stored keys to save memory consumption.

=encoding utf8

=head1 SYNOPSYS

    # inside your app.psgi
    enable 'Throttle::Lite',
        backend => [
            'Redis' => {
                instance => 'redis.example.com:6379',
                database => 1,
                password => 'VaspUtnuNeQuiHesGapbootsewWeonJadacVebEe'
            }
        ];

=head1 OPTIONS

This storage backend must be configured in order to use. All options should be passed as a hash reference. The
following options are available to tune it for your needs.

=head2 instance

A string consist of a hostname (or an IP address) and port number (delimited with a colon) or unix socket path
of the redis-server instance to connect to. Not required. Default value is B<127.0.0.1:6379>. Some usage examples

    # tcp/ip redis-servers
    instance => '';                          # treats as '127.0.0.1:6379'
    instance => 'TCP:example.com:11230';     # ..as 'example.com:11230'
    instance => 'tcp:redis.example.org';     # ..as 'redis.example.org:6379'
    instance => 'redis-db.example.com';      # ..as 'redis-db.example.com:6379'
    instance => 'tcp:127.0.0.1';             # ..as '127.0.0.1:6379'
    instance => 'tcp:10.90.90.90:5000';      # ..as '10.90.90.90:5000'
    instance => '192.168.100.230';           # ..as '192.168.100.230:6379'
    instance => 'bogus:0'                    # ..as 'bogus:6379' (allowed > 0 and < 65536)
    instance => 'Inet:172.16.5.4:65000';     # ..as '172.16.5.4:65000'
    instance => 'bar:-100';                  # ..as 'bar:6379' (allowed > 0 and < 65536)
    instance => 'baz:70000';                 # ..as 'baz:6379' (allowed > 0 and < 65536) and so on..

    # unix sockets might be passed like this
    instance => 'Unix:/var/foo/Redis.sock';  # this socket path '/var/foo/Redis.sock'
    instance => '/bar/tmp/redis/sock';       # ..as '/bar/tmp/redis/sock',
    instance => 'unix:/var/foo/redis.sock';  # ..as '/var/foo/redis.sock',

=head2 database

A redis-server database number to store throttling data. Not obligatory option. If this one omitted then value B<0> will
be assigned.

=head2 password

Password string for redis-server's AUTH command to processing any other commands. Optional. Check the redis-server
manual for directive I<requirepass> if you would to use redis internal authentication.

=head2 reconnect

A time (in seconds) to re-establish connection to the redis-server before an exception will be raised. Not required.
Default value is B<10> sec.

=head2 every

Interval (in milliseconds) after which will be an attempt to re-establish lost connection to the redis-server. Not required.
Default value is B<100> ms.

=head2 debug

Enables debug information to STDERR, including all interactions with the redis-server. Not required.
Default value is B<0> (disabled).

=head1 METHODS

=head2 redis

Returns a redis connection handle.

=head2 rdb

A redis database number to store data.

=head2 init

See L<Plack::Middleware::Throttle::Lite::Backend::Abstract/"ABSTRACT METHODS">

=head2 reqs_done

See L<Plack::Middleware::Throttle::Lite::Backend::Abstract/"ABSTRACT METHODS">

=head2 increment

See L<Plack::Middleware::Throttle::Lite::Backend::Abstract/"ABSTRACT METHODS">

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Throttle-Lite-Backend-Redis/issues>

=head1 SEE ALSO

L<Redis>

L<Plack::Middleware::Throttle::Lite>

L<Plack::Middleware::Throttle::Lite::Backend::Abstract>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
