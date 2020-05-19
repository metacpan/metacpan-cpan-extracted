use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use IO::Socket::INET;
use Mojo::File 'tempdir';
use Mojo::IOLoop::Server;
use Mojo::Server::Elzar;
use Mojo::UserAgent;
use Win32::Process qw(:DEFAULT STILL_ACTIVE);

# Configure
{
  my $elzar = Mojo::Server::Elzar->new;
  $elzar->threaded->app->config->{test}     = {};
  $elzar->threaded->app->config->{myserver} = {
    accepts            => 13,
    backlog            => 43,
    clients            => 1,
    graceful_timeout   => 23,
    heartbeat_interval => 7,
    heartbeat_timeout  => 9,
    inactivity_timeout => 5,
    listen             => ['http://*:8081'],
    pid_file           => '/foo/bar.pid',
    proxy              => 1,
    requests           => 3,
    spare              => 4,
    upgrade_timeout    => 45,
    workers            => 7
  };
  is $elzar->upgrade_timeout, 180, 'right default';
  $elzar->configure('test');
  is_deeply $elzar->threaded->listen, ['http://*:8080'], 'right value';
  $elzar->configure('myserver');
  is $elzar->threaded->accepts,            13, 'right value';
  is $elzar->threaded->backlog,            43, 'right value';
  is $elzar->threaded->graceful_timeout,   23, 'right value';
  is $elzar->threaded->heartbeat_interval, 7,  'right value';
  is $elzar->threaded->heartbeat_timeout,  9,  'right value';
  is $elzar->threaded->inactivity_timeout, 5,  'right value';
  is_deeply $elzar->threaded->listen, ['http://*:8081'], 'right value';
  is $elzar->threaded->max_clients,  1,              'right value';
  is $elzar->threaded->max_requests, 3,              'right value';
  is $elzar->threaded->pid_file,     '/foo/bar.pid', 'right value';
  ok $elzar->threaded->reverse_proxy, 'reverse proxy enabled';
  is $elzar->threaded->spare,         4, 'right value';
  is $elzar->threaded->workers,       7, 'right value';
  is $elzar->upgrade_timeout, 45, 'right value';
}

# Prepare script
my $dir    = tempdir('elzXXXXX', CLEANUP => 1);
my $script = $dir->child('myapp.pl');
my $log    = $dir->child('mojo.log');
my $port1  = Mojo::IOLoop::Server->generate_port;
my $port2  = Mojo::IOLoop::Server->generate_port;
my @spawned;

my $head = <<EOF;
use Mojolicious::Lite;
use Mojo::IOLoop;
use POSIX qw(strftime);

app->log->path('$log');
app->log->level('debug');

app->log->format(
    sub {
        return join(' ', strftime('%Y-%m-%d %H:%M:%S', localtime(shift)), uc(shift), \$\$, join('', \@_) . "\\n");
    }
);
EOF


my $body = <<EOF;
plugin Config => {
  default => {
    elzar => {
      listen => ['http://127.0.0.1:$port1', 'http://127.0.0.1:$port2'],
      workers => 1,
      upgrade_timeout => 10,
      inactivity_timeout => 60,
    }
  }
};

get '/hello' => {text => 'Hello Elzar!'};

my \$graceful;
Mojo::IOLoop->singleton->on(finish => sub { \$graceful++ });

get '/graceful' => sub {
  my \$c = shift;
  my \$id;
  \$id = Mojo::IOLoop->recurring(0 => sub {
    return unless \$graceful;
    \$c->render(text => 'Graceful shutdown!');
    Mojo::IOLoop->remove(\$id);
  });
};

app->start;
EOF

$script->spurt($head . $body);

# Start

push @spawned, _spawn($script) || BAIL_OUT("couldn't spawn script");

sleep 1;

my $i = 0;
while (!_port($port2)) {
  diag "wait for server startup, " . ++$i;
  sleep 1;
}

my ($old_pid, $old_port);
$i = 0;
while (!$old_port) {
  diag "wait for server startup, " . ++$i;
  ($old_pid, $old_port) = _pid();
  sleep 1;
}

# Application is alive
my $ua = Mojo::UserAgent->new();

my $tx = $ua->get("http://127.0.0.1:$port1/hello");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok !$tx->kept_alive, 'connection was not kept alive';
is $tx->res->code, 200,            'right status';
is $tx->res->body, 'Hello Elzar!', 'right content';

# Application is alive (second port)
$tx = $ua->get("http://127.0.0.1:$port2/hello");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok !$tx->kept_alive, 'connection was not kept alive';
is $tx->res->code, 200,            'right status';
is $tx->res->body, 'Hello Elzar!', 'right content';

# Same result
$tx = $ua->get("http://127.0.0.1:$port1/hello");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok $tx->kept_alive,  'connection was kept alive';
is $tx->res->code, 200,            'right status';
is $tx->res->body, 'Hello Elzar!', 'right content';

# Same result (second port)
$tx = $ua->get("http://127.0.0.1:$port2/hello");
ok $tx->is_finished, 'transaction is finished';
ok $tx->keep_alive,  'connection will be kept alive';
ok $tx->kept_alive,  'connection was kept alive';
is $tx->res->code, 200,            'right status';
is $tx->res->body, 'Hello Elzar!', 'right content';

SKIP: {
  skip "skipping developer only tests" unless $ENV{TEST_ELZAR_HOT_DEPLOY};

  # Update script (broken)
  $script->spurt(<<'EOF');
use Mojolicious::Lite;

die if $ENV{ELZAR_PORT};

app->start;
EOF

  push @spawned, _spawn($script) || BAIL_OUT("couldn't spawn script");

  # Wait for hot deployment to fail
  $i = 0;
  while (1) {
    diag "wait for upgrade to fail, " . ++$i;
    my $ltxt = eval { $log->slurp };
    last if $ltxt and $ltxt =~ qr/Zero downtime software upgrade failed/;
    sleep 1;
  }

  sleep 2;

  # Connection did not get lost
  $tx = $ua->get("http://127.0.0.1:$port1/hello");
  ok $tx->is_finished, 'transaction is finished';
  ok $tx->keep_alive,  'connection will be kept alive';
  ok $tx->kept_alive,  'connection was kept alive';
  is $tx->res->code, 200,            'right status';
  is $tx->res->body, 'Hello Elzar!', 'right content';

  # Connection did not get lost (second port)
  $tx = $ua->get("http://127.0.0.1:$port2/hello");
  ok $tx->is_finished, 'transaction is finished';
  ok $tx->keep_alive,  'connection will be kept alive';
  ok $tx->kept_alive,  'connection was kept alive';
  is $tx->res->code, 200,            'right status';
  is $tx->res->body, 'Hello Elzar!', 'right content';

  # Request that will be served after graceful shutdown has been initiated
  $tx = $ua->build_tx(GET => "http://127.0.0.1:$port1/graceful");
  $ua->start($tx => sub { });
  Mojo::IOLoop->one_tick until $tx->req->is_finished;

  # Update script
  $body = <<EOF;
plugin Config => {
  default => {
    hypnotoad => {
      accepts => 2,
      inactivity_timeout => 3,
      listen => ['http://127.0.0.1:$port1', 'http://127.0.0.1:$port2'],
      requests => 1,
      workers => 1
    }
  }
};

app->log->level('debug');

get '/hello' => sub { shift->render(text => "Hello World \$\$:" . threads->tid() . "!") };

app->start;
EOF

  $script->spurt($head . $body);

  push @spawned, _spawn($script) || BAIL_OUT("couldn't spawn script");

  $i = 0;
  while (1) {
    diag "wait for hot deploy to finish, " . ++$i;
    sleep 1;
    my ($new_pid, $new_port) = _pid();
    last if $new_pid and $new_pid ne $old_pid;
  }

  sleep 2;

  # Request that will be served by an old worker that is still running
  Mojo::IOLoop->one_tick until $tx->is_finished;
  ok !$tx->keep_alive, 'connection will not be kept alive';
  ok !$tx->kept_alive, 'connection was not kept alive';
  is $tx->res->code, 200,                  'right status';
  is $tx->res->body, 'Graceful shutdown!', 'right content';

  sleep 1;

  # One uncertain request that may or may not be served by the old worker
  $tx = $ua->get("http://127.0.0.1:$port1/hello");
  is $tx->res->code, 200, 'right status';
  $tx = $ua->get("http://127.0.0.1:$port2/hello");
  is $tx->res->code, 200, 'right status';

  sleep 1;

  # Application has been reloaded
  $tx = $ua->get("http://127.0.0.1:$port1/hello");
  ok $tx->is_finished, 'transaction is finished';
  ok !$tx->keep_alive, 'connection will not be kept alive';
  ok !$tx->kept_alive, 'connection was not kept alive';
  is $tx->res->code, 200, 'right status';
  my $first = $tx->res->body;
  like $first, qr/Hello World \d+:\d+!/, 'right content';

  # Application has been reloaded (second port)
  $tx = $ua->get("http://127.0.0.1:$port2/hello");
  ok $tx->is_finished, 'transaction is finished';
  ok !$tx->keep_alive, 'connection will not be kept alive';
  ok !$tx->kept_alive, 'connection was not kept alive';
  is $tx->res->code, 200, 'right status';
  is $tx->res->body, $first, 'same content';

  sleep 2;

  # Same result
  $tx = $ua->get("http://127.0.0.1:$port1/hello");
  ok $tx->is_finished, 'transaction is finished';
  ok !$tx->keep_alive, 'connection will not be kept alive';
  ok !$tx->kept_alive, 'connection was not kept alive';
  is $tx->res->code, 200, 'right status';
  my $second = $tx->res->body;
  isnt $first, $second, 'different content';
  like $second, qr/Hello World \d+:\d+!/, 'right content';

  # Same result (second port)
  $tx = $ua->get("http://127.0.0.1:$port2/hello");
  ok $tx->is_finished, 'transaction is finished';
  ok !$tx->keep_alive, 'connection will not be kept alive';
  ok !$tx->kept_alive, 'connection was not kept alive';
  is $tx->res->code, 200, 'right status';
  is $tx->res->body, $second, 'same content';

  # Stop
  push @spawned, _spawn($script, '-s') || BAIL_OUT("couldn't spawn script");

  $i = 0;
  while (_port($port2)) {
    diag "wait for server shutdown, " . ++$i;
    sleep 1;
  }

  sleep 2;

  # Check log
  $log = $log->slurp;
  like $log, qr/Worker \d+ started/, 'right message';
  like $log, qr/Starting zero downtime software upgrade \(10 seconds\)/,
    'right message';
  like $log, qr/Upgrade successful, stopping server with port $old_port/,
    'right message';
}

# cleanup
_kill(@spawned);

sub _pid {
  local $/ = undef;
  return unless open my $file, '<', $dir->child('elzar.pid');
  return split(/\s+/, <$file>);
}

sub _port { IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => shift) }

sub _spawn {
  my $script = shift;
  my $prefix = "$FindBin::Bin/../script";
  my $cmd    = qq("$^X" "$prefix/elzar" "$script" ) . join(' ', @_);
  diag("running >>$cmd<<");
  Win32::Process::Create(my $obj, $^X, $cmd, 0, NORMAL_PRIORITY_CLASS, '.');
  warn Win32::FormatMessage(Win32::GetLastError()) unless $obj;
  return $obj;
}

sub _kill {
  for my $obj (@_) {
    $obj->GetExitCode(my $ec);
    $obj->Kill(0) if $ec == STILL_ACTIVE;
  }
}

done_testing();

