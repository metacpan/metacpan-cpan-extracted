package Mojo::Redis::Connection;
use Mojo::Base 'Mojo::EventEmitter';

use File::Spec::Functions 'file_name_is_absolute';
use Mojo::IOLoop;
use Mojo::Promise;

use constant DEBUG                     => $ENV{MOJO_REDIS_DEBUG};
use constant CONNECT_TIMEOUT           => $ENV{MOJO_REDIS_CONNECT_TIMEOUT} || 10;
use constant SENTINELS_CONNECT_TIMEOUT => $ENV{MOJO_REDIS_SENTINELS_CONNECT_TIMEOUT} || CONNECT_TIMEOUT;

has encoding => sub { Carp::confess('encoding is required in constructor') };
has ioloop   => sub { Carp::confess('ioloop is required in constructor') };
has protocol => sub { Carp::confess('protocol is required in constructor') };
has url      => sub { Carp::confess('url is required in constructor') };

sub DESTROY {
  my $self = shift;
  $self->disconnect if defined $self->{pid} and $self->{pid} == $$;
}

sub disconnect {
  my $self = shift;
  $self->_reject_queue;
  $self->{stream}->close if $self->{stream};
  $self->{gone_away} = 1;
  return $self;
}

sub is_connected { $_[0]->{stream} && !$_[0]->{gone_away} ? 1 : 0 }

sub write_p {
  my $self = shift;
  my $p    = Mojo::Promise->new->ioloop($self->ioloop);
  $self->write_q(@_, $p);
  $self->is_connected ? $self->_write : $self->_connect;
  return $p;
}

sub write_q {
  my $p    = pop;
  my $self = shift;
  push @{$self->{write}}, [$self->_encode(@_), $p];
  return $self;
}

sub _encode {
  my $self     = shift;
  my $encoding = $self->encoding;
  return $self->protocol->encode({
    type => '*', data => [map { +{type => '$', data => $encoding ? Mojo::Util::encode($encoding, $_) : $_} } @_]
  });
}

sub _connect {
  my $self = shift;
  return $self if $self->{id};    # Connecting

  # Cannot reuse a connection because of transaction state and other state
  return $self->_reject_queue('Redis server has gone away') if $self->{gone_away};

  my $url = $self->{master_url} || $self->url;
  return $self->_discover_master if !$self->{master_url} and $url->query->param('sentinel');

  Scalar::Util::weaken($self);
  delete $self->{master_url};     # Make sure we forget master_url so we can reconnect
  $self->protocol->on_message($self->_parse_message_cb);
  $self->{id} = $self->ioloop->client(
    $self->_connect_args($url, {port => 6379, timeout => CONNECT_TIMEOUT}),
    sub {
      return unless $self;
      my ($loop, $err, $stream) = @_;
      my $close_cb = $self->_on_close_cb;
      return $self->$close_cb($err) if $err;

      $stream->timeout(0);
      $stream->on(close => $close_cb);
      $stream->on(error => $close_cb);
      $stream->on(read  => $self->_on_read_cb);

      unshift @{$self->{write}}, [$self->_encode(SELECT => $url->path->[0])] if length $url->path->[0];
      unshift @{$self->{write}}, [$self->_encode(AUTH   => $url->password)]  if length $url->password;
      $self->{pid}    = $$;
      $self->{stream} = $stream;
      $self->emit('connect');
      $self->_write;
    }
  );

  warn "[@{[$self->_id]}] CONNECTING $url (blocking=@{[$self->_is_blocking]})\n" if DEBUG;
  return $self;
}

sub _connect_args {
  my ($self, $url, $defaults) = @_;
  my %args = (address => $url->host || 'localhost');

  if (file_name_is_absolute $args{address}) {
    $args{path} = delete $args{address};
  }
  else {
    $args{port} = $url->port || $defaults->{port};
  }

  $args{timeout} = $defaults->{timeout} || CONNECT_TIMEOUT;
  return \%args;
}

sub _discover_master {
  my $self      = shift;
  my $url       = $self->url->clone;
  my $sentinels = $url->query->every_param('sentinel');
  my $timeout   = $url->query->param('sentinel_connect_timeout') || SENTINELS_CONNECT_TIMEOUT;

  $url->host_port(shift @$sentinels);
  $self->url->query->param(sentinel => [@$sentinels, $url->host_port]);    # Round-robin sentinel list
  $self->protocol->on_message($self->_parse_message_cb);
  $self->{id} = $self->ioloop->client(
    $self->_connect_args($url, {port => 16379, timeout => $timeout}),
    sub {
      my ($loop, $err, $stream) = @_;
      return unless $self;
      return $self->_discover_master if $err;

      $stream->timeout(0);
      $stream->on(close => sub { $self->_discover_master unless $self->{master_url} });
      $stream->on(error => sub { $self->_discover_master });
      $stream->on(read  => $self->_on_read_cb);

      $self->{stream} = $stream;
      unshift @{$self->{write}}, [$self->_encode(AUTH => $url->password)] if length $url->password;
      $self->write_p(SENTINEL => 'get-master-addr-by-name' => $self->url->host)->then(sub {
        my $host_port = shift;
        delete $self->{id};
        return $self->_discover_master unless ref $host_port and @$host_port == 2;
        $self->{master_url} = $self->url->clone->host($host_port->[0])->port($host_port->[1]);
        $self->{stream}->close;
        $self->_connect;
      })->catch(sub { $self->_discover_master });
    }
  );

  warn "[@{[$self->_id]}] SENTINEL DISCOVERY $url (blocking=@{[$self->_is_blocking]})\n" if DEBUG;
  return $self;
}

sub _id { $_[0]->{id} || '0' }

sub _is_blocking { shift->ioloop eq Mojo::IOLoop->singleton ? 0 : 1 }

sub _on_close_cb {
  my $self = shift;

  Scalar::Util::weaken($self);
  return sub {
    return unless $self;
    my ($stream, $err) = @_;
    delete $self->{$_} for qw(id stream);
    $self->{gone_away} = 1;
    $self->_reject_queue($err);
    $self->emit('close') if @_ == 1;
    warn qq([@{[$self->_id]}] @{[$err ? "ERROR $err" : "CLOSED"]}\n) if $self and DEBUG;
  };
}

sub _on_read_cb {
  my $self = shift;

  Scalar::Util::weaken($self);
  return sub {
    return unless $self;
    my ($stream, $chunk) = @_;
    do { local $_ = $chunk; s!\r\n!\\r\\n!g; warn "[@{[$self->_id]}] >>> ($_)\n" } if DEBUG;
    $self->protocol->parse($chunk);
  };
}

sub _parse_message_cb {
  my $self = shift;

  Scalar::Util::weaken($self);
  return sub {
    my ($protocol, @messages) = @_;
    my $encoding = $self->encoding;
    $self->_write;

    my $unpack;
    $unpack = sub {
      my @res;

      while (my $m = shift @_) {
        if ($m->{type} eq '-') {
          return $m->{data}, undef;
        }
        elsif ($m->{type} eq ':') {
          push @res, 0 + $m->{data};
        }
        elsif ($m->{type} eq '*' and ref $m->{data} eq 'ARRAY') {
          my ($err, $res) = $unpack->(@{$m->{data}});
          return $err if defined $err;
          push @res, $res;
        }

        # Only bulk string replies can contain binary-safe encoded data
        elsif ($m->{type} eq '$' and $encoding and defined $m->{data}) {
          push @res, Mojo::Util::decode($encoding, $m->{data});
        }
        else {
          push @res, $m->{data};
        }
      }

      return undef, \@res;
    };

    my ($err, $res) = $unpack->(@messages);
    my $p = shift @{$self->{waiting} || []};
    return $p ? $p->reject($err) : $self->emit(error => $err) unless $res;
    return $p ? $p->resolve($res->[0]) : $self->emit(response => $res->[0]);
  };
}

sub _reject_queue {
  my ($self, $err) = @_;
  state $default = 'Premature connection close';
  for my $p (@{delete $self->{waiting} || []}) { $p      and $p->reject($err      || $default) }
  for my $i (@{delete $self->{write}   || []}) { $i->[1] and $i->[1]->reject($err || $default) }
  return $self;
}

sub _write {
  my $self = shift;

  while (my $op = shift @{$self->{write}}) {
    my $loop = $self->ioloop;
    do { local $_ = $op->[0]; s!\r\n!\\r\\n!g; warn "[@{[$self->_id]}] <<< ($_)\n" } if DEBUG;
    push @{$self->{waiting}}, $op->[1];
    $self->{stream}->write($op->[0]);
  }
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis::Connection - Low level connection class for talking to Redis

=head1 SYNOPSIS

  use Mojo::Redis::Connection;

  my $conn = Mojo::Redis::Connection->new(
               ioloop   => Mojo::IOLoop->singleton,
               protocol => Protocol::Redis::Faster->new(api => 1),
               url      => Mojo::URL->new("redis://localhost"),
             );

  $conn->write_p("GET some_key")->then(sub { print "some_key=$_[0]" })->wait;

=head1 DESCRIPTION

L<Mojo::Redis::Connection> is a low level driver for writing and reading data
from a Redis server.

You probably want to use L<Mojo::Redis> instead of this class.

=head1 EVENTS

=head2 close

  $cb = $conn->on(close => sub { my ($conn) = @_; });

Emitted when the connection to the redis server gets closed.

=head2 connect

  $cb = $conn->on(connect => sub { my ($conn) = @_; });

Emitted right after a connection is established to the Redis server, but
after the AUTH and SELECT commands are queued.

=head2 error

  $cb = $conn->on(error => sub { my ($conn, $error) = @_; });

Emitted if there's a connection error or the Redis server emits an error, and
there's not a promise to handle the message.

=head2 response

  $cb = $conn->on(response => sub { my ($conn, $res) = @_; });

Emitted if L</write_q> is not passed a L<Mojo::Promise> as the last argument,
or if the Redis server emits a message that is not handled.

=head1 ATTRIBUTES

=head2 encoding

  $str  = $conn->encoding;
  $conn = $conn->encoding("UTF-8");

Holds the character encoding to use for data from/to Redis. Set to C<undef>
to disable encoding/decoding data. Without an encoding set, Redis expects and
returns bytes. See also L<Mojo::Redis/encoding>.

=head2 ioloop

  $loop = $conn->ioloop;
  $conn = $conn->ioloop(Mojo::IOLoop->new);

Holds an instance of L<Mojo::IOLoop>.

=head2 protocol

  $protocol = $conn->protocol;
  $conn     = $conn->protocol(Protocol::Redis::XS->new(api => 1));

Holds a protocol object, such as L<Protocol::Redis::Faster> that is used to
generate and parse Redis messages.

=head2 url

  $url  = $conn->url;
  $conn = $conn->url(Mojo::URL->new->host("/tmp/redis.sock")->path("/5"));
  $conn = $conn->url("redis://localhost:6379/1");

=head1 METHODS

=head2 disconnect

  $conn = $conn->disconnect;

Used to disconnect from the Redis server.

=head2 is_connected

  $bool = $conn->is_connected;

True if a connection to the Redis server is established.

=head2 write_p

  $promise = $conn->write_p($command => @args);

Will write a command to the Redis server and establish a connection if not
already connected and returns a L<Mojo::Promise>. The arguments will be
passed on to L</write_q>.

=head2 write_q

  $conn = $conn->write_q(@command => @args, Mojo::Promise->new);
  $conn = $conn->write_q(@command => @args, undef);

Will enqueue a Redis command and either resolve/reject the L<Mojo::Promise>
or emit a L</error> or L</response> event when the Redis server responds.

This method is EXPERIMENTAL and currently meant for internal use.

=head1 SEE ALSO

L<Mojo::Redis>

=cut
