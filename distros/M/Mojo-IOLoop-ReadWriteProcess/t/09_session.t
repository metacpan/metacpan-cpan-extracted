#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use POSIX;
use FindBin;
use Mojo::File qw(tempfile path);
use lib ("$FindBin::Bin/lib", "../lib", "lib");

use Mojo::IOLoop::ReadWriteProcess qw(process);
use Mojo::IOLoop::ReadWriteProcess::Test::Utils qw(attempt);
use Mojo::IOLoop;

use Mojo::IOLoop::ReadWriteProcess::Session qw(session);

subtest register => sub {
  my $s = session;
  my $p = process(sub { });
  $s->register(1 => $p);

  is_deeply ${$s->process_table()->{1}}, $p, 'Equal' or die diag explain $s;

  ${$s->process_table()->{1}}->{foo} = 'bar';

  is $p->{foo}, 'bar';

  session->resolve(1)->{foo} = 'kaboom';

  is $p->{foo}, 'kaboom';
};

subtest unregister => sub {
  session->clean();

  my $p = process(sub { });
  session->register(1 => $p);

  is_deeply ${session->process_table()->{1}}, $p, 'Equal'
    or die diag explain session();

  session->unregister(1);
  is session->all()->size, 0;
  is session->resolve(1), undef;

  session->register(1 => $p);
  is session->all()->size, 1;

  session->clean();
  is session->all()->size, 0;
};

subtest disable => sub {
  local $SIG{CHLD} = 'DEFAULT';

  session->enable();
  is session->handler, 'DEFAULT', 'previous handler saved';

  isnt $SIG{CHLD}, 'DEFAULT', 'Handler has changed';
  session->disable();
  is $SIG{CHLD}, 'DEFAULT', 'handler restored';
};

subtest reset => sub {
  session->reset;

  session->register(1 => process(sub { }));
  session->register(2 => process(sub { }));
  session->register(3 => process(sub { }));
  session->orphans->{5} = 1;

  is session->all->size, 4, 'There are 4 processes';
  session->reset();

  is session->all->size, 0, 'Reset cleaned up processes';

  session->on(foo => sub { 'bar' });

  is((values %{session->{events}}), 1, '1 event is present');
  session->reset();
  is((values %{session->{events}}), 0, '0 events are present');

};

subtest protect => sub {

  my $handler;
  session->on(protect => sub { shift; $handler = pop @{shift()} });
  session->protect(sub { });
  is $handler, SIGCHLD;

  Mojo::IOLoop::ReadWriteProcess::Session->new->protect(sub { });
  is $handler, SIGCHLD;

  Mojo::IOLoop::ReadWriteProcess::Session::protect(sub { });
  is $handler, SIGCHLD;

  session->protect(sub { } => SIGTERM);
  is $handler, SIGTERM;

  Mojo::IOLoop::ReadWriteProcess::Session->new->protect(sub { } => SIGTERM);
  is $handler, SIGTERM;

  Mojo::IOLoop::ReadWriteProcess::Session::protect(sub { } => SIGTERM);
  is $handler, SIGTERM;

};

done_testing();
