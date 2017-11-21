package Mojo::Redis2::Server;
use feature 'state';
use Mojo::Asset::File;
use Mojo::Base -base;
use Mojo::IOLoop;
use Time::HiRes ();
use constant SERVER_DEBUG => $ENV{MOJO_REDIS_SERVER_DEBUG} || 0;

sub config { \%{shift->{config} || {}}; }
has configure_environment => 1;
sub pid { shift->{pid} || 0; }
sub url { shift->{url} || ''; }

sub singleton { state $server = shift->new; }

sub start {
  my $self   = _instance(shift);
  my %config = @_;
  my $cfg;

  return $self if $self->pid and kill 0, $self->pid;

  $config{bind}                        ||= '127.0.0.1';
  $config{daemonize}                   ||= 'no';
  $config{databases}                   ||= 16;
  $config{loglevel}                    ||= SERVER_DEBUG ? 'verbose' : 'warning';
  $config{port}                        ||= Mojo::IOLoop::Server->generate_port;
  $config{rdbchecksum}                 ||= 'no';
  $config{requirepass}                 ||= '';
  $config{stop_writes_on_bgsave_error} ||= 'no';
  $config{syslog_enabled}              ||= 'no';

  $cfg = Mojo::Asset::File->new;
  $self->{bin} = $ENV{REDIS_SERVER_BIN} || 'redis-server';

  while (my ($key, $value) = each %config) {
    $key =~ s!_!-!g;
    warn "[Redis::Server] config $key $value\n" if SERVER_DEBUG;
    $cfg->add_chunk("$key $value\n") if length $value;
  }

  require Mojo::Redis2;

  $self->{parent_pid} = $$;
  if ($self->{pid} = fork) {    # parent
    $self->{config} = \%config;
    $self->{url} = sprintf 'redis://x:%s@%s:%s/', map { $_ // '' } @config{qw( requirepass bind port )};
    $self->_wait_for_server_to_start;
    $ENV{MOJO_REDIS_URL} //= $self->{url} if $self->configure_environment;
    return $self;
  }

  # child
  no warnings;
  exec $self->{bin}, $cfg->path;
  exit $!;
}

sub stop {
  my $self  = _instance(shift);
  my $guard = 10;
  my $pid   = $self->pid or return $self;

  while (--$guard > 0) {
    kill 15, $pid or last;
    Time::HiRes::usleep(100e3);
    waitpid $self->pid, 0;
  }

  die "Could not kill $pid ($guard)" if kill 0, $pid;
  return $self;
}

sub _instance { ref $_[0] ? $_[0] : $_[0]->singleton; }

sub _wait_for_server_to_start {
  my $self  = shift;
  my $guard = 100;
  my $e;

  while (--$guard) {
    local $@;
    Time::HiRes::usleep(10e3);
    return if eval { Mojo::Redis2->new(url => $self->url)->ping };
    $e = $@ || 'No idea why we cannot connect to Mojo::Redis2::Server';
  }

  if ($self->pid and waitpid $self->pid, 0) {
    my ($x, $s, $d) = ($? >> 8, $? & 127, $? & 128);
    die "Failed to start $self->{bin}: exit=$x, signal=$s, dump=$d";
  }

  die $e;
}

sub DESTROY { $_[0]->stop if ($_[0]{parent_pid} // 0) == $$; }

1;

=encoding utf8

=head1 NAME

Mojo::Redis2::Server - Start a test server

=head1 DESCRIPTION

L<Mojo::Redis2::Server> is a class for starting an instances of the Redis
server. The server is stopped when the instance of this class goes out of
scope.

Note: This module is only meant for unit testing. It is not good enough for
keeping a production server up and running at this point.

=head1 SYNOPSIS

  use Mojo::Redis2::Server;

  {
    my $server = Mojo::Redis2::Server->new;
    $server->start;
    # server runs here
  }

  # server is stopped here

=head1 ATTRIBUTES

=head2 config

  $hash_ref = $self->config;

Contains the full configuration of the Redis server.

=head2 configure_environment

  $bool = $self->configure_environment;
  $self = $self->configure_environment($bool);

L</start> will set the C<MOJO_REDIS_URL> environment variable unless
this attribute is set to false.

=head2 pid

  $int = $self->pid;

The pid of the Redis server.

=head2 url

  $str = $self->url;

Contains a value suitable for L<Mojo::Redis2/url>.

=head1 METHODS

=head2 singleton

  $self = $class->singleton;

Returns the singleton which is used when L</start> and L</stop> is called
as class methods, instead of instance methods.

=head2 start

  $self = $self->start(%config);

This method will try to start an instance of the Redis server or C<die()>
trying. The input config is a key/value structure with valid Redis config
file settings.

=head2 stop

  $self = $self->stop;

Will stop a running Redis server or die trying.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
