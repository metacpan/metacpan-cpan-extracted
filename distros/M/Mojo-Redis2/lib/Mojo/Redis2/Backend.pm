package Mojo::Redis2::Backend;
use Mojo::Base -base;

has _redis => undef;

sub config {
  my @cb = ref $_[-1] eq 'CODE' ? (pop) : ();
  my ($self, $key, $value) = @_;

  if (defined $value) {
    my $res = $self->_redis->_execute(basic => CONFIG => SET => $key => $value, @cb);
    return $self if @cb;
    return $res;
  }
  elsif (my $cb = $cb[0]) {
    $self->_redis->_execute(
      basic => CONFIG => GET => $key => sub {
        my ($redis, $err, $params) = @_;
        $params //= [];
        $_[0]->$cb($err, $key =~ /\*/ ? {@$params} : $params->[1]);
      }
    );
    return $self;
  }
  else {
    my $params = $self->_redis->_execute(basic => CONFIG => GET => $key);
    return $key =~ /\*/ ? {@$params} : $params->[1];
  }
}

sub info {
  my $cb      = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self    = shift;
  my $section = shift || '';

  if ($cb) {
    $self->_redis->_execute(
      basic => INFO => $section => sub {
        $_[0]->$cb($_[1], {map { split /:/, $_, 2 } grep {/:/} split /\r\n/, $_[2] // ''});
      }
    );
    return $self;
  }
  else {
    my $text = $self->_redis->_execute(basic => INFO => $section);
    return {map { split /:/, $_, 2 } grep {/:/} split /\r\n/, $text};
  }
}

for my $method (qw( resetstat rewrite )) {
  my $op = uc $method;
  eval
    "sub $method { my \$self = shift; my \$r = \$self->_redis->_execute(basic => CONFIG => $op => \@_); return \@_ ? \$self : \$r }; 1"
    or die $@;
}

for my $method (qw( bgrewriteaof bgsave dbsize flushall flushdb lastsave save time )) {
  my $op = uc $method;
  eval
    "sub $method { my \$self = shift; my \$r = \$self->_redis->_execute(basic => $op => \@_); return \@_ ? \$self : \$r }; 1"
    or die $@;
}

1;

=encoding utf8

=head1 NAME

Mojo::Redis2::Backend - Mojo::Redis2 server commands

=head1 DESCRIPTION

L<Mojo::Redis2::Backend> allow running L<server|http://redis.io/commands#server>
commands in a structured manner.

NOTE: All the callbacks get the C<$redis> object and not C<$self>. (This might
change in the future)

=head1 SYNOPSIS

  use Mojo::Redis2;
  my $redis = Mojo::Redis2->new;

  $res = $redis->backend->config("dbfilename");

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $redis->backend->config(dbfilename => $delay->begin);
    },
    sub {
      my ($delay, $err, $dbfilename) = @_;
      $self->render(text => $err || $dbfilename);
    },
  );

=head1 METHODS

=head2 bgrewriteaof

  $res = $self->bgrewriteaof;
  $self = $self->bgrewriteaof(sub { my ($redis, $err, $res) = @_; });

See L<http://redis.io/commands/bgrewriteaof> for details.

=head2 bgsave

  $res = $self->bgsave;
  $self = $self->bgsave(sub { my ($redis, $err, $res) = @_; });

See L<http://redis.io/commands/bgsave> for details.

=head2 config

  # CONFIG GET $key
  $res = $self->config($key);
  $self = $self->config($key => sub { my ($redis, $err, $res) = @_; });

  # CONFIG SET $key $value
  $self = $self->config($key => $value => sub { my ($redis, $err, $res) = @_; });
  $res = $self->config($key => $value);

Used to retrieve or set config parameters. C<$res> will differ dependent on
input:

  | $self->config(dbfilename => "foo.rdb") | $res = "OK"                 |
  | $self->config("dbfilename")            | "foo.rdb"                   |
  | $self->config("dbfile*")               | { dbfilename => "foo.rdb" } |

=head2 dbsize

  $res = $self->dbsize;
  $self = $self->dbsize(sub { my ($redis, $err, $res) = @_; });

See L<http://redis.io/commands/dbsize> for details.

=head2 flushall

  $res = $self->flushall;
  $self = $self->flushall(sub { my ($redis, $err, $res) = @_; });

See L<http://redis.io/commands/flushall> for details.

=head2 flushdb

  $res = $self->flushdb;
  $self = $self->flushdb(sub { my ($redis, $err, $res) = @_; });

See L<http://redis.io/commands/flushdb> for details.

=head2 info

  $res = $self->info($section);
  $self = $self->info($section => sub { my ($redis, $err, $res) = @_; });

Used to retrieve information about a given C<$section>. Example C<$res> when
C<$section> is "clients":

  {
    connected_clients => "3",
    client_longest_output_list => "30",
    client_biggest_input_buf => "100",
    blocked_clients => "0",
  }

=head2 lastsave

  $res = $self->lastsave;
  $self = $self->lastsave(sub { my ($redis, $err, $res) = @_; });

See L<http://redis.io/commands/lastsave> for details.

=head2 resetstat

  $res = $self->resetstat;
  $self = $self->resetstat(sub { my ($redis, $err, $res) = @_; });

Used to reset the statistics reported by Redis using the L</info> method.

=head2 rewrite

  $res = $self->rewrite;
  $self = $self->rewrite(sub { my ($redis, $err, $res) = @_; });

Used to rewrite the config file.

=head2 save

  $res = $self->save;
  $self = $self->save(sub { my ($redis, $err, $res) = @_; });

See L<http://redis.io/commands/save> for details.

=head2 time

  $res = $self->time;
  $self = $self->time(sub { my ($redis, $err, $res) = @_; });

See L<http://redis.io/commands/time> for details. C<$res> holds the same
format as L<Time::Hires/gettimeofday> in an array-ref:

  [ 1409045324, 311294 ];

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
