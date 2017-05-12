package Mojo::Redis;

our $VERSION = '1.02';
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::IOLoop;
use Mojo::Redis::Subscription;
use Mojo::URL;
use Scalar::Util ();
use Encode       ();
use Carp;
use constant DEBUG => $ENV{MOJO_REDIS_DEBUG} ? 1 : 0;

my %ON_SPECIAL = map { $_, "_on_$_" } qw( blpop brpop message );

sub connected {
  my $self = shift;
  return 0 unless my $ioloop = $self->ioloop;
  return 1 if $self->{connection} and $ioloop->stream($self->{connection});
  return 0;
}

has encoding => 'UTF-8';
has ioloop   => sub { Mojo::IOLoop->singleton };
has server   => '127.0.0.1:6379';

has protocol_redis => sub {
  require Protocol::Redis;
  "Protocol::Redis";
};

has protocol => sub {
  my $self = shift;
  my $protocol = $self->protocol_redis->new(api => 1) or Carp::croak('protocol_redis implementation does not support APIv1');

  Scalar::Util::weaken($self);
  $protocol->on_message(sub { shift; $self->_return_command_data(@_); });
  $protocol;
};

sub timeout {
  return $_[0]->{timeout} || 0 unless @_ > 1;
  my($self, $t) = @_;
  my $id = $self->{connection};

  if(my $id = $self->{connection}) {
    if(my $stream = $self->ioloop->stream($id)) {
      $stream->timeout($t);
    }
  }

  $self->{timeout} = $t;
  $self;
}

for my $cmd (qw/
  append auth bgrewriteaof bgsave blpop brpop brpoplpush config_get config_set
  config_resetstat dbsize debug_object debug_segfault decr decrby del discard
  echo exec exists expire expireat flushall flushdb get getbit getrange getset
  hdel hexists hget hgetall hincrby hkeys hlen hmget hmset hset hsetnx hvals
  incr incrby info keys lastsave lindex linsert llen lpop lpush lpushx lrange
  lrem lset ltrim mget monitor move mset msetnx multi persist ping
  publish quit randomkey rename renamenx rpop rpoplpush rpush
  rpushx sadd save scard sdiff sdiffstore select set setbit setex setnx
  setrange shutdown sinter sinterstore sismember slaveof smembers smove sort
  spop srandmember srem strlen sunion sunionstore sync ttl type
  unwatch watch zadd zcard zcount zincrby zinterstore zrange
  zrangebyscore zrank zrem zremrangebyrank zremrangebyscore zrevrange
  zrevrangebyscore zrevrank zscore zunionstore
/) {
  eval(
    "sub $cmd {"
   .'my $self = shift;'
   ."\$self->execute($cmd => \@_) } 1;"
  ) or die $@;
}

sub DESTROY {
  $_[0]->ioloop or return; # may be undef during global destruction
  $_[0]->disconnect;
}

sub connect {
  my $self = shift;
  my $url = $self->_server_to_url;
  my($auth, $db_index);

  Scalar::Util::weaken $self;
  $auth = (split /:/, $url->userinfo || '')[1];
  $db_index = ($url->path =~ /(\d+)/)[0] || '';

  $self->disconnect if $self->{connecting} or $self->{connection}; # drop old connection
  $self->{connecting} = 1;
  $self->{connection} = $self->ioloop->client(
    { address => $url->host,
      port    => $url->port || 6379,
    },
    sub {
      my ($loop, $error, $stream) = @_;

      if($error) {
        $self->_inform_queue(error => $error);
        return;
      }

      $stream->timeout($self->timeout);
      $stream->on(
        read => sub {
          my($stream, $chunk) = @_;
          if(DEBUG) {
            my $c2 = $chunk;
            $c2 =~ s/\r?\n/','/g;
            warn "REDIS[@{[$self->{connection}]}] >>> ['$c2']\n";
          }
          $self->protocol->parse($chunk);
        }
      );
      $stream->on(
        close => sub {
          $self or return;
          $self->_inform_queue;
          $self->emit('close');
        }
      );
      $stream->on(
        error => sub {
          $self or return; # $self may be undef during global destruction
          $self->_inform_queue(error => $_[1]);
        }
      );
      $stream->on(
        timeout => sub {
          $self or return; # $self may be undef during global destruction
          $self->_inform_queue(error => 'Timeout');
        }
      );

      my $mqueue = $self->{message_queue} ||= [];
      my $cqueue = $self->{cb_queue} ||= [];

      if($db_index =~ /^\d+/) { # need to be before defined $auth below
        unshift @$mqueue, [ SELECT => $db_index ];
        unshift @$cqueue, sub {}; # no error handling needed. got on(error => ...)
      }
      if(defined $auth) {
        unshift @$mqueue, [ AUTH => $auth ];
        unshift @$cqueue, sub {}; # no error handling needed. got on(error => ...)
      }

      delete $self->{connecting};
      $self->_send_next_message;
    }
  );

  return $self;
}

sub disconnect {
  my $self = shift;
  my $connections = $self->{connections} || {};

  for my $id (keys %$connections) {
    my $c = delete $connections->{$id};
    $c->disconnect if $c;
  }

  delete $self->{connecting};
  delete $self->{protocol};

  if(my $id = delete $self->{connection} and $self->{ioloop}) {
    $self->{ioloop}->remove($id);
  }

  $self;
}

sub on {
  my($self, $event, @args) = @_;
  my $method = @args > 1 ? $ON_SPECIAL{$event} : '';
  my $name = $event;
  my $cb = pop @args;

  if($method) {
    $name = join ':', $event, @args;
    $self->$method($name, $event, @args);
  }

  $self->SUPER::on($name, $cb);
}

sub once {
  my($self, $event, @args) = @_;
  my $method = @args > 1 ? $ON_SPECIAL{$event} : '';
  my $name = $event;
  my $cb = pop @args;

  if($method) {
    $name = join ':', $event, @args;
    $self->$method($name, $event, @args);
  }

  $self->SUPER::once($name, $cb);
}

sub unsubscribe {
  my($self, $event, @args) = @_;
  my $method = $ON_SPECIAL{$event};
  my @cb;

  $method or return $self->SUPER::unsubscribe($event, @args);
  @cb = ref $args[-1] eq 'CODE' ? (pop @args) : ();
  $event = join ':', $event, @args;
  $self->SUPER::unsubscribe($event, @cb);

  unless($self->has_subscribers($event)) {
    my $conn = delete $self->{connections}{$event};
    $conn->disconnect if $conn;
  }

  $self;
}

sub subscribe {
  my($self, @channels) = @_;
  $self->_subscribe_generic('subscribe', @channels);
}

sub psubscribe {
  my($self, @channels) = @_;
  $self->_subscribe_generic('psubscribe', @channels);
}

sub _subscribe_generic {
  my($self, $type, @channels) = @_;
  my $cb = ref $channels[-1] eq 'CODE' ? pop @channels : undef;
  my $n = 0;

  if(!$cb) {
    return $self->_clone('Mojo::Redis::Subscription' => channels => [@channels], type => $type)->connect;
  }

  # need to attach new callback to the protocol object
  Scalar::Util::weaken $self;
  push @{ $self->{cb_queue} }, ($cb) x (@channels - 1);
  $self->execute(
    [ $type => @channels ],
    sub {
      shift; # we already got $self
      $self->$cb(@_);
      $self->{protocol} = $self->protocol_redis->new(api => 1);
      $self->{protocol} or Carp::croak(q/Protocol::Redis implementation doesn't support APIv1/);
      $self->{protocol}->on_message(
        sub {
          my ($parser, $message) = @_;
          my $data = $self->_reencode_message($message) or return;
          $self->$cb($data);
        }
      );
    }
  );
}

sub execute {
  my ($self, @commands) = @_;
  my($cb, $process);

  if (ref $commands[-1] eq 'CODE') {
    $cb = pop @commands;
  }
  if (ref $commands[0] ne 'ARRAY') {
    @commands = ([@commands]);
  }

  for my $cmd (@commands) {
    $cmd->[0] = uc $cmd->[0];
    if(ref $cmd->[-1] eq 'HASH') {
        splice @$cmd, -1, 1, map { $_ => $cmd->[-1]{$_} } keys %{ $cmd->[-1] };
    }
  }

  my $mqueue = $self->{message_queue} ||= [];
  my $cqueue = $self->{cb_queue}      ||= [];

  if($cb) {
    my @res;
    my $process = sub {
      if(my $command = shift @commands) {
        push @res, $command->[0] eq 'HGETALL' ? $_[1] ? { @{ $_[1] } } : undef : $_[1];
      }
      else {
        push @res, undef;
      }
      $_[0]->$cb(@res) unless @commands;
    };
    push @$cqueue, ($process) x int @commands;
  }
  else {
    push @$cqueue, (sub {}) x int @commands;
  }

  push @$mqueue, @commands;
  $self->connect unless $self->{connection};
  $self->_send_next_message;

  return $self;
}

sub _send_next_message {
  my ($self) = @_;

  $self->{connecting} and return;

  while (my $args = shift @{$self->{message_queue}}) {
    my $cmd_arg = [];

    foreach my $token (@$args) {
      $token = Encode::encode($self->encoding, $token)
        if $self->encoding;
      push @$cmd_arg, {type => '$', data => $token};
    }

    $self->_write({ type => '*', data => $cmd_arg }) or last;
  }
}

sub _reencode_message {
  my ($self, $message) = @_;
  my ($type, $data) = @{$message}{'type', 'data'};

  # Decode data
  if ($type ne '*' and $self->encoding and $data) {
    $data = Encode::decode($self->encoding, $data);
  }

  if ($type eq '-') {
    $self->emit(error => $data);
    return;
  }
  elsif ($type ne '*') {
    return $data;
  }
  else {
    my $reencoded_data = [];
    foreach my $item (@$data) {
      my $message = $self->_reencode_message($item);
      push @$reencoded_data, $message;
    }
    return $reencoded_data;
  }
}

sub _return_command_data {
  my ($self, $message) = @_;
  my $data = $self->_reencode_message($message);
  my $cb = shift @{$self->{cb_queue}};

  eval {
    $self->$cb($data) if $cb;
    1;
  } or do {
    my $err = $@;
    $self->has_subscribers('error') ? $self->emit(error => $err) : warn $err;
  };
}

sub _clone {
  my($self, $class, @args) = @_;

  $class ||= ref $self;
  $class->new({
    encoding => $self->encoding,
    ioloop => $self->ioloop,
    protocol_redis => $self->protocol_redis,
    server => $self->server,
    timeout => $self->timeout,
    @args,
  });
}

sub _inform_queue {
  my ($self, @emit) = @_;
  my $cb_queue = delete $self->{cb_queue} || [];

  delete $self->{message_queue};
  $self->emit(@emit) if @emit;

  for my $cb (@$cb_queue) {
    eval {
      $self->$cb(undef) if $cb;
      1;
    } or do {
      my $err = $@;
      $self->has_subscribers('error') ? $self->emit(error => $err) : warn $err;
    };
  }
}

sub _on_blpop {
  my ($self, $id, $method, @args) = @_;
  my $handler;

  Scalar::Util::weaken($self);
  $self->{connections}{$id} and return;
  $self->{connections}{$id} = $self->_clone(undef, timeout => 0);

  $handler = sub {
    $self->emit($id => '', reverse @{ $_[1] });
    $self->{connections}{$id}->$method(@args, 0, $handler);
  };

  $self->{connections}{$id}->on(error => sub { $self->emit($id => $_[1], undef, undef); });
  $self->{connections}{$id}->$method(@args, 0, $handler);
}

*_on_brpop = \&_on_blpop;

sub _on_message {
  my ($self, $id, $method, @channels) = @_;

  Scalar::Util::weaken($self);
  $self->{connections}{$id} and return;
  $self->{connections}{$id} = $self->_clone(undef, timeout => 0, cb_queue => [(sub {}) x (@channels - 1)]);
  $self->{connections}{$id}->on(error => sub { $self->emit($id => $_[1], undef, undef); });
  $self->{connections}{$id}->execute(
    [ subscribe => @channels ],
    sub {
      my ($redis) = @_;
      $redis->protocol->on_message(sub {
        $self or return; # may be undef on global destruction
        my $data = $self->_reencode_message($_[1]);
        $self->emit($id => '', @$data[2, 1]);
      }),
    },
  );
}

sub _write {
  my($self, $what) = @_;
  my $ioloop = $self->ioloop;
  my($stream, $message);

  unless($stream = $ioloop->stream($self->{connection} || 0)) {
    $self->disconnect;
    return;
  }
  if(!$ioloop->is_running and $stream->is_readable) {
    $stream->close;
    $self->disconnect;
    return;
  }

  $message = $self->protocol->encode($what);
  $stream->write($message);

  if(DEBUG) {
    $message =~ s/\r?\n/','/g;
    warn "REDIS[@{[$self->{connection}]}] <<< ['$message']\n";
  }

  return 1;
}

sub _server_to_url {
  my $self = shift;
  my $url;

  if($self->server =~ m{^[^:]+(:\d+)?$}) {
    $url = Mojo::URL->new('redis://' .$self->server);
  }
  else {
    $url = Mojo::URL->new($self->server);
  }

  # I have noooooo idea why this makes sense
  # https://github.com/kraih/mango/commit/5dc6d67bb84f32aa16bbd5967650366006672747
  Mojo::URL->new($url->scheme('http'));
}

1;
__END__

=head1 NAME

Mojo::Redis - DEPRECATED Redis client

=head1 DESCRIPTION

L<Mojo::Redis> is replaced by L<Mojo::Redis2>.

THIS MODULE IS NO LONGER MAINTAINED AND WILL BE REPLACED BY A COMPLETELY NEW
API DURING 2015.

The new API is available in L<Mojo::Redis2>.

Some time during 2015, this module will be completely replaced by the code from L<Mojo::Redis2>.

YOU SHOULD NOT USE THIS MODULE. THE RISK OF MEMORY LEAKS AND MISSING OUT ON
ERRORS IS INEVITABLE.

The exact date for replacement is not yet set, but when it's replaced your
existing L<Mojo::Redis> code I<will> break.

REPLACE L<Mojo::Redis> WITH L<Mojo::Redis2> NOW.

=head1 SUPPORT

There's no support for this module.

=head1 AUTHOR

Sergey Zasenko, C<undef@cpan.org>.

Forked from MojoX::Redis and updated to new IOLoop API by
Marcus Ramberg C<mramberg@cpan.org>
and Jan Henning Thorsen C<jhthorsen@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011, Sergey Zasenko
          (C) 2012, Marcus Ramberg

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
