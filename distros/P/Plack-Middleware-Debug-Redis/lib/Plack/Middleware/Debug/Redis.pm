package Plack::Middleware::Debug::Redis;

# ABSTRACT: Extend Plack::Middleware::Debug with Redis panels

use strict;
use warnings;
use Carp ();
use Redis 1.955;
use Plack::Util::Accessor qw/instance password db reconnect every debug redis/;

our $VERSION = '0.03'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

sub redis_connect {
    my ($self, $args) = @_;

    my $croak = sub { Carp::croak $_[0] };

    my %options = (
        debug     => $self->debug     || 0,
        reconnect => $self->reconnect || 10,
        every     => $self->every     || 100,
    );

    $options{password} = $self->password if $self->password;

    my $instance = $self->_parse_instance($self->instance);

    if ($instance->{unix}) {
        $croak->("Nonexistent redis socket ($instance->{thru})!") unless -e $instance->{thru} && -S _;
    }

    $options{ $instance->{unix} ? 'sock' : 'server' } = $instance->{thru};

    $self->db($self->db || 0);

    my $_handle;
    eval { $_handle = Redis->new(%options) };
    $croak->("Cannot get redis handle: $@") if $@;

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

1; # End of Plack::Middleware::Debug::Redis

__END__

=pod

=head1 NAME

Plack::Middleware::Debug::Redis - Extend Plack::Middleware::Debug with Redis panels

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    # inside your psgi app
    use Plack::Builder;

    my $app = sub {[
        200,
        [ 'Content-Type' => 'text/html' ],
        [ '<html><body>OK</body></html>' ]
    ]};
    my $redis_host = 'redi.example.com:6379';

    builder {
        mount '/' => builder {
            enable 'Debug',
                panels => [
                    [ 'Redis::Info', instance => $redis_host ],
                    [ 'Redis::Keys', instance => $redis_host, db => 3 ],
                ];
            $app;
        };
    };

=head1 DESCRIPTION

This distribution extends Plack::Middleware::Debug with some Redis panels. At the moment, the following panels
available:

=head1 PANELS

=head2 Redis::Info

Diplay panel with generic Redis server information which is available by the command INFO.
See L<Plack::Middleware::Debug::Redis::Info> for additional information.

=head2 Redis::Keys

Diplay panel with keys Redis server information. See L<Plack::Middleware::Debug::Redis::Keys>
for additional information.

=head1 METHODS

=head2 redis_connect

Checks passed parameters and connects to redis server instance. Returns redis handle or croaks.

=head2 redis

Redis handle to operate with.

=head1 OPTIONS

All options should be passed as a hash reference. The following options are available to tune it for your needs.

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

=head2 password

Password string for redis-server's AUTH command to processing any other commands. Optional. Check the redis-server
manual for directive I<requirepass> if you would to use redis internal authentication.

=head2 db

A redis-server database number to use. Not obligatory option. If this one omitted then value B<0> will
be assigned.

=head2 reconnect

A time (in seconds) to re-establish connection to the redis-server before an exception will be raised. Not required.
Default value is B<10> sec.

=head2 every

Interval (in milliseconds) after which will be an attempt to re-establish lost connection to the redis-server. Not required.
Default value is B<100> ms.

=head2 debug

Enables debug information to STDERR, including all interactions with the redis-server. Not required.
Default value is B<0> (disabled).

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Debug-Redis/issues>

=head1 SEE ALSO

L<Plack::Middleware::Debug::Redis::Info>

L<Plack::Middleware::Debug::Redis::Keys>

L<Plack::Middleware::Debug>

L<Redis>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
