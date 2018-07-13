package Mojo::Redis::Connection;
use Mojo::Base 'Mojo::EventEmitter';

use File::Spec::Functions 'file_name_is_absolute';
use Mojo::IOLoop;
use Mojo::Promise;

use constant DEBUG => $ENV{MOJO_REDIS_DEBUG};

has encoding => sub { Carp::confess('encoding is required in constructor') };
has ioloop   => sub { Carp::confess('ioloop is required in constructor') };
has protocol => sub { Carp::confess('protocol is required in constructor') };
has url      => sub { Carp::confess('url is required in constructor') };

sub disconnect {
  my $self = shift;
  $self->{stream}->close if $self->{stream};
  return $self;
}

sub is_connected { shift->{stream} ? 1 : 0 }

sub write_p {
  my $self = shift;
  my $p = Mojo::Promise->new(ioloop => $self->ioloop);
  $self->write_q(@_, $p);
  $self->{stream} ? $self->_write : $self->_connect;
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

  $self->protocol->on_message($self->_parse_message_cb);
  my $url  = $self->url;
  my $db   = $url->path->[0];
  my %args = (address => $url->host || 'localhost');

  if (file_name_is_absolute $args{address}) {
    $args{path} = delete $args{address};
  }
  else {
    $args{port} = $url->port || 6379;
  }

  Scalar::Util::weaken($self);
  $self->{id} = $self->ioloop->client(
    \%args,
    sub {
      return unless $self;
      my ($loop, $err, $stream) = @_;
      my $close_cb = $self->_on_close_cb;
      return $self->$close_cb($err) if $err;

      $stream->timeout(0);
      $stream->on(close => $close_cb);
      $stream->on(error => $close_cb);
      $stream->on(read  => $self->_on_read_cb);

      unshift @{$self->{write}}, [$self->_encode(SELECT => $db)]            if length $db;
      unshift @{$self->{write}}, [$self->_encode(AUTH   => $url->password)] if length $url->password;
      $self->{stream} = $stream;
      $self->emit('connect');
      $self->_write;
    }
  );

  warn "[@{[$self->_id]}] CONNECTING $url (blocking=@{[$self->_loop_is_singleton ? 0 : 1]})\n" if DEBUG;
  return $self;
}

sub _id { $_[0]->{id} || '0' }

sub _loop_is_singleton { shift->ioloop eq Mojo::IOLoop->singleton }

sub _on_close_cb {
  my $self = shift;

  Scalar::Util::weaken($self);
  return sub {
    return unless $self;
    my ($stream, $err) = @_;
    delete $self->{$_} for qw(id stream);
    $self->emit(error => $err) if $err;
    warn qq([@{[$self->_id]}] @{[$err ? "ERROR $err" : "CLOSED"]}\n) if DEBUG;
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
    my (@res, @err);

    $self->_write;

    while (@messages) {
      my ($type, $data) = @{shift(@messages)}{qw(type data)};
      if    ($type eq '-') { push @err, $data }
      elsif ($type eq ':') { push @res, 0 + $data }
      elsif ($type eq '*' and ref $data) { push @messages, @$data }
      else                               { push @res,      $encoding ? Mojo::Util::decode($encoding, $data) : $data }
    }

    my $p = shift @{$self->{waiting} || []};
    return $p ? $p->reject(@err) : $self->emit(error => @err) if @err;
    return $p ? $p->resolve(@res) : $self->emit(response => @res);
  };
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
               protocol => Protocol::Redis::XS->new(api => 1),
               url      => Mojo::URL->new("redis://localhost"),
             );

  $conn->write_p("GET some_key")->then(sub { print "some_key=$_[0]" })->wait;

=head1 DESCRIPTION

L<Mojo::Redis::Connection> is a low level driver for writing and reading data
from a Redis server.

You probably want to use L<Mojo::Redis> instead of this class.

=head1 EVENTS

=head2 connect

  $cb = $self->on(connect => sub { my ($self) = @_; });

Emitted right after a connection is established to the Redis server, but
after the AUTH and SELECT commands are queued.

=head2 error

  $cb = $self->on(error => sub { my ($self, $error) = @_; });

Emitted if there's a connection error or the Redis server emits an error, and
there's not a promise to handle the message.

=head2 response

  $cb = $self->on(response => sub { my ($self, $res) = @_; });

Emitted if L</write_q> is not passed a L<Mojo::Promise> as the last argument,
or if the Redis server emits a message that is not handled.

=head1 ATTRIBUTES

=head2 encoding

  $str  = $self->encoding;
  $self = $self->encoding("UTF-8");

Holds the character encoding to use for data from/to Redis. Set to C<undef>
to disable encoding/decoding data. Without an encoding set, Redis expects and
returns bytes. See also L<Mojo::Redis/encoding>.

=head2 ioloop

  $loop = $self->ioloop;
  $self = $self->ioloop(Mojo::IOLoop->new);

Holds an instance of L<Mojo::IOLoop>.

=head2 protocol

  $protocol = $self->protocol;
  $self     = $self->protocol(Protocol::Redis::XS->new(api => 1));

Holds a protocol object, such as L<Protocol::Redis> that is used to generate
and parse Redis messages.

=head2 url

  $url  = $self->url;
  $self = $self->url(Mojo::URL->new->host("/tmp/redis.sock")->path("/5"));
  $self = $self->url("redis://localhost:6379/1");

=head1 METHODS

=head2 disconnect

  $self = $self->disconnect;

Used to disconnect from the Redis server.

=head2 is_connected

  $bool = $self->is_connected;

True if a connection to the Redis server is established.

=head2 write_p

  $promise = $self->write_p($command => @args);

Will write a command to the Redis server and establish a connection if not
already connected and returns a L<Mojo::Promise>. The arguments will be
passed on to L</write_q>.

=head2 write_q

  $self = $self->write_q(@command => @args, Mojo::Promise->new);
  $self = $self->write_q(@command => @args, undef);

Will enqueue a Redis command and either resolve/reject the L<Mojo::Promise>
or emit a L</error> or L</message> event when the Redis server responds.

This method is EXPERIMENTAL and currently meant for internal use.

=head1 SEE ALSO

L<Mojo::Redis>

=cut
