package Mojo::Redis2::Client;
use Mojo::Base -base;

has _redis => undef;

sub kill {
  my @cb = ref $_[-1] eq 'CODE' ? (pop) : ();
  my $self = shift;
  $self->_execute(basic => CLIENT => KILL => @_ => @cb);
}

sub list {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift;

  # non-blocking
  if ($cb) {
    return $self->_execute(
      qw( basic CLIENT LIST ),
      sub {
        my ($redis, $err, $res) = @_;
        return $redis->$cb($err, {}) if $err;
        return $redis->$cb('', _parse_list($redis, $res));
      }
    );
  }

  # blocking
  return _parse_list($self->_redis, $self->_execute(qw( basic CLIENT LIST )));
}

sub name {
  my @cb = ref $_[-1] eq 'CODE' ? (pop) : ();
  $_[0]->_execute(basic => CLIENT => $_[1] ? ('SETNAME', $_[1]) : ('GETNAME'), @cb);
}

sub _execute {
  my ($self, @args) = @_;
  my $res = $self->_redis->_execute(@args);
  return UNIVERSAL::isa($res, 'Mojo::Redis2') ? $self : $res;
}

sub _parse_list {
  my ($redis, $res) = @_;
  my %list;

  # $res = addr=1.1.3.4:12345 fd=5 idle=107 flags=N db=3 sub=0 psub=0 qbuf=0 obl=0 oll=0 events=r cmd=incr
  for my $line (split /\r?\n/, $res) {
    my %client = map { split '=', $_, 2 } split ' ', $line;
    $list{$client{addr}} = \%client;
  }

  return \%list;
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis2::Client - Mojo::Redis2 CLIENT commands

=head1 DESCRIPTION

L<Mojo::Redis2::Client> allow running L<CLIENT|http://redis.io/commands#server>
commands in a structured manner.

NOTE: All the callbacks get the C<$redis> object and not C<$self>. (This might
change in the future)

=head1 SYNOPSIS

  use Mojo::Redis2;
  my $redis = Mojo::Redis2->new;

  $res = $redis->client->kill("127.0.0.1:12345");

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $redis->client->name($delay->begin);
    },
    sub {
      my ($delay, $err, $name) = @_;
      $self->render(text => $err || $name);
    },
  );

=head1 METHODS

=head2 kill

  $res = $self->kill(@args);
  $self = $self->kill(@args => sub { my ($redis, $err, $res) = @_; });

Will run C<CLIENT KILL ...> command. Example:

  $self->kill("1.2.3.4:12345");
  $self->kill(ID => "foo-connection-123");
  $self->kill(TYPE => "normal", SKIPME => "yes");

=head2 list

  $list = $self->list;
  $self = $self->list(sub { my ($redis, $err, $list) = @_; });

Runs C<CLIENT LIST> and retrieves the client data in a structured format:

  {
    "1.2.3.4:12345" => {
      addr => "1.2.3.4:12345",
      db => "3",
      flags => "N",
      idle => "107",
      ...
    },
    ...
  }

The data will differ by Redis version. Look at L<http://redis.io/commands/client-list>
for details.

NOTE: The values might be forced into real integers in future versions, but
they are strings now.

=head2 name

  # CLIENT GETNAME
  $name = $self->name;
  $self = $self->name(sub { my ($redis, $err, $name) = @_; });

  # CLIENT SETNAME $name
  $res = $self->name($str);
  $self = $self->name($str => sub { my ($redis, $err, $res) = @_; });

Used to set or get the connection name. Note: This will only set the
connection name for the "basic" operations (not SUBSCRIBE, BLPOP and
friends). Also, setting the connection in blocking mode, will not
change the non-blocking and visa versa.

TODO: Support setting name for SUBSCRIBE, BLPOP, ... connections.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
