package Plack::Session::Store::RedisFast;

use strict;
use warnings;

use 5.008_005;

use Carp qw( carp );
use Plack::Util::Accessor qw( prefix redis encoder expire );
use Time::Seconds qw( ONE_MONTH );

use parent 'Plack::Session::Store';

use constant SESSIONS_PER_SCAN => 100;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:AKZHAN';

sub new {
    my ( $class, %param ) = @_;
    $param{prefix} = __PACKAGE__ . ':' unless defined $param{prefix};
    $param{expire} = ONE_MONTH         unless exists $param{expire};

    unless ( $param{redis} ) {
        my $builder = ( delete $param{builder} ) || \&_build_redis;
        $param{redis} = $builder->();
    }

    $param{encoder} ||=
      _build_encoder( ( delete $param{inflate} ), ( delete $param{deflate} ) );

    $param{encoder} = $param{encoder}->new()
      unless ref( $param{encoder} );

    bless {%param} => $class;
}

sub _build_redis {
    my $instance;
    eval {
        require Redis::Fast;
        $instance = Redis::Fast->new;
        1;
    } or do {
        require Redis;
        $instance = Redis->new;
    };
    $instance;
}

sub _build_encoder {
    my ( $inflate, $deflate ) = @_;
    if ( $inflate && $deflate ) {
        require Plack::Session::Store::RedisFast::Encoder::Custom;
        return Plack::Session::Store::RedisFast::Encoder::Custom->new( $inflate,
            $deflate );
    }
    my $instance;
    eval {
        require Plack::Session::Store::RedisFast::Encoder::JSONXS;
        $instance = Plack::Session::Store::RedisFast::Encoder::JSONXS->new;
        1;
    } or do {
        require Plack::Session::Store::RedisFast::Encoder::MojoJSON;
        $instance = Plack::Session::Store::RedisFast::Encoder::MojoJSON->new;
      }
      or do {
        require Plack::Session::Store::RedisFast::Encoder::JSON;
        $instance = Plack::Session::Store::RedisFast::Encoder::JSON->new;
      };
    $instance;
}

sub fetch {
    my ( $self, $session_id ) = @_;
    my $data = $self->redis->get( $self->prefix . $session_id );
    return undef unless defined $data;
    $self->encoder->decode($data);
}

sub store {
    my ( $self, $session_id, $session ) = @_;
    unless ( defined $session ) {
        carp "store: no session provided";
        return;
    }
    my $data = $self->encoder->encode($session);
    $self->redis->set(
        $self->prefix . $session_id => $data,
        ( defined( $self->expire ) ? ( EX => $self->expire ) : () ),
    );
    1;
}

sub remove {
    my ( $self, $session_id ) = @_;
    $self->redis->del( $self->prefix . $session_id );
    1;
}

sub each_session {
    my ( $self, $cb ) = @_;
    return if ref($cb) ne 'CODE';

    my $prefix = $self->prefix;

    my $cursor = 0;
    for ( ; ; ) {
        ( $cursor, my $keys ) = $self->redis->scan(
            $cursor,
            MATCH => $self->prefix . '*',
            COUNT => SESSIONS_PER_SCAN
        );
        if ( scalar(@$keys) > 0 ) {
            my @sessions = $self->redis->mget(@$keys);

            for ( my $i = 0 ; $i < scalar(@sessions) ; $i++ ) {
                next unless $sessions[$i];

                next if $keys->[$i] !~ m/^\Q$prefix\E(.+)$/;
                my $session_id = $1;

                $cb->(
                    $self->redis, $prefix, $session_id,
                    $self->encoder->decode( $sessions[$i] ),
                );
            }
        }

        last if $cursor == 0;
    }
    1;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plack::Session::Store::RedisFast - Redis session store.

=head1 DESCRIPTION

Default implementation of Redis handle is L<Redis::Fast>; otherwise L<Redis>.

May be overriden through L</redis> or  L</builder> param.

Default implementation of serializer handle is L<JSON::XS>; otherwise L<Mojo::JSON> or L<JSON>.

May be overriden through L</inflate> and L</deflate> param.

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Session::Store::RedisFast;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session',
          store => Plack::Session::Store::RedisFast->new;
      $app;
  };

=head1 DESCRIPTION

This will persist session data using L<Redis::Fast> or L<Redis>.

This is a subclass of L<Plack::Session::Store> and implements
its full interface.

=head1 METHODS

=head2 new

    Plack::Session::Store::RedisFast->new( %param );

Parameters:

=over 4

=item redis

A simple accessor for the Redis handle.

=item builder

A simple builder for the Redis handle if L</redis> not set.

=item inflate

A simple serializer, requires L</deflate> param.

=item deflate

A simple deserializer, requires L</inflate> param.

=item encoder

A simple encoder (encode/decode implementation), class or instance. JSON/utf8 by default.

=item prefix

A prefix for Redis session ids. 'Plack::Session::Store::RedisFast:' by default.

=item expire

An expire for Redis sessions. L<Time::Seconds/ONE_MONTH> by default.

=back

=head2 each_session

    $store->each_session(sub {
        my ( $redis_instance, $redis_prefix, $session_id, $session ) = @_;
    });

Enumerates all stored sessions using SCAN, see L<https://redis.io/commands/scan> for limitations.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please fill in GitHub issues.

=head1 AUTHOR

Akzhan Abdulin E<lt>akzhan.abdulin@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Akzhan Abdulin

=head1 LICENSE

MIT License

=cut
