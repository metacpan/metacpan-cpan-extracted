use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;

use Mojo::File qw(path);
use Mojo::IOLoop::Server;
use Mojo::Server::Threaded;
use Mojo::UserAgent;

my $debug_level = $ARGV[0] || 'fatal';
my $threaded = Mojo::Server::Threaded->new;

# Manage and clean up PID file
my $file = $threaded->pid_file;
unlink($file) if -e $file;
ok !$threaded->check_pid, 'no process id';
$threaded->ensure_pid_file(-23);
ok -e $file, 'file exists';
like path($file)->slurp, qr/^-23\s+/, 'right process id';
ok !$threaded->check_pid, 'no process id';
ok !-e $file, 'file has been cleaned up';
$threaded->ensure_pid_file($$);
ok -e $file, 'file exists';
like path($file)->slurp, qr/^$$\s+/, 'right process id';
is $threaded->check_pid, $$, 'right process id';
like $threaded->check_mport, qr/^\d+$/, 'mport exists';
undef $threaded;
ok !-e $file, 'file has been cleaned up';

# Bad PID file
my $bad = path(__FILE__)->sibling('does_not_exist', 'test.pid');
$threaded = Mojo::Server::Threaded->new(pid_file => $bad);
$threaded->app->log->level($debug_level);
my $log = '';
my $cb = $threaded->app->log->on(message => sub { $log .= pop });
eval { $threaded->ensure_pid_file($$) };
like $@,     qr/Can't create process id file/, 'right error';
unlike $log, qr/Creating process id file/,     'right message';
like $log,   qr/Can't create process id file/, 'right message';
$threaded->app->log->unsubscribe(message => $cb);

# Multiple workers and graceful shutdown
my $port = Mojo::IOLoop::Server::->generate_port;
$threaded = Mojo::Server::Threaded->new(
  heartbeat_interval => 2,
  listen             => ["http://*:$port"]
);
$threaded->unsubscribe('request');
$threaded->on(
  request => sub {
    my ($thr, $tx) = @_;
    $tx->res->code(200)->body('just works!');
    $tx->resume;
  }
);
is $threaded->workers, 4, 'start with four workers';
my (@spawn, @reap, $worker, $tx, $graceful);
$threaded->on(spawn => sub { push @spawn, pop });
$threaded->on(
  heartbeat => sub {
    my ($thr, $pid) = @_;
    $worker = $pid;
    return if $thr->healthy < 4;
    $tx = Mojo::UserAgent->new->get("http://127.0.0.1:$port");
    $thr->send_command('QUIT');
  }
);
$threaded->on(reap => sub { push @reap, pop });
$threaded->on(finish => sub { $graceful = pop });
$log = '';
$cb = $threaded->app->log->on(message => sub { $log .= pop });
is $threaded->healthy, 0, 'no healthy workers';

$threaded->run;
is scalar @spawn, 4, 'four workers spawned';
is scalar @reap,  4, 'four workers reaped';
(my $wok) = grep { $worker eq $_ } @spawn;
ok $wok, 'worker has a heartbeat';
ok $graceful, 'server has been stopped gracefully';
is_deeply [sort @spawn], [sort @reap], 'same process ids';
is $tx->res->code, 200,           'right status';
is $tx->res->body, 'just works!', 'right content';
like $log, qr/Listening at/,             'right message';
like $log, qr/Manager $$ started/,       'right message';
like $log, qr/Creating process id file/, 'right message';
like $log, qr/Stopping worker $spawn[0] gracefully \(120 seconds\)/,
  'right message';
like $log, qr/Worker $spawn[0] stopped/, 'right message';
like $log, qr/Manager $$ stopped/,       'right message';
$threaded->app->log->unsubscribe(message => $cb);

# Process id file
is $threaded->check_pid, $$, 'right process id';
my $pid = $threaded->pid_file;
ok -e $pid, 'process id file has been created';
undef $threaded;
ok !-e $pid, 'process id file has been removed';

# One worker and immediate shutdown
$port    = Mojo::IOLoop::Server->generate_port;
$threaded = Mojo::Server::Threaded->new(
  accepts            => 500,
  heartbeat_interval => 2,
  listen             => ["http://*:$port"],
  workers            => 1
);
$threaded->unsubscribe('request');
$threaded->on(
  request => sub {
    my ($threaded, $tx) = @_;
    $tx->res->code(200)->body('works too!');
    $tx->resume;
  }
);
my $count = $tx = $graceful = undef;
@spawn = @reap = ();
$log = '';
$cb = $threaded->app->log->on(message => sub { $log .= pop });
$threaded->on(spawn => sub { push @spawn, pop });
$threaded->once(
  heartbeat => sub {
    $tx = Mojo::UserAgent->new->get("http://127.0.0.1:$port");
    $threaded->send_command('KILL');
  }
);
$threaded->on(reap => sub { push @reap, pop });
$threaded->on(finish => sub { $graceful = pop });

$threaded->run;
is $threaded->ioloop->max_accepts, 500, 'right value';
is scalar @spawn, 1, 'one worker spawned';
is scalar @reap,  1, 'one worker reaped';
ok !$graceful, 'server has been stopped immediately';
is $tx->res->code, 200,          'right status';
is $tx->res->body, 'works too!', 'right content';

done_testing();

