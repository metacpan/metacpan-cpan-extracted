use Mojo::Base -strict;
use Test2::V0;
use Mojo::File qw(tempfile);
use Mojo::Server::DaemonControl;

subtest basics => sub {
  my $dctl = Mojo::Server::DaemonControl->new;
  like $dctl->pid_file, qr{basics\.t\.pid$}, 'pid_file';
  is $dctl->graceful_timeout,       120,             'graceful_timeout';
  is $dctl->heartbeat_interval,     5,               'heartbeat_interval';
  is $dctl->heartbeat_timeout,      50,              'heartbeat_timeout';
  is $dctl->listen->[0]->to_string, 'http://*:8080', 'listen';
  is $dctl->workers,                4,               'workers';
};

subtest env => sub {
  local $ENV{MOJODCTL_GRACEFUL_TIMEOUT}   = 2;
  local $ENV{MOJODCTL_HEARTBEAT_INTERVAL} = 3;
  local $ENV{MOJODCTL_HEARTBEAT_TIMEOUT}  = 4;
  local $ENV{MOJODCTL_LISTEN}             = 'http://*:3001,https://example.com?secure=0';
  local $ENV{MOJODCTL_LOG_FILE}           = tempfile;
  local $ENV{MOJODCTL_LOG_LEVEL}          = 'fatal';
  local $ENV{MOJODCTL_PID_FILE}           = tempfile;
  local $ENV{MOJODCTL_WORKERS}            = 1;

  my $dctl = Mojo::Server::DaemonControl->new;
  is $dctl->graceful_timeout,       2, 'graceful_timeout';
  is $dctl->heartbeat_interval,     3, 'heartbeat_interval';
  is $dctl->heartbeat_timeout,      4, 'heartbeat_timeout';
  is [map {"$_"} @{$dctl->listen}], ['http://*:3001', 'https://example.com?secure=0',], 'listen';
  is $dctl->log->level,             'fatal',                                            'log level';
  is $dctl->log->path,              $ENV{MOJODCTL_LOG_FILE},                            'log file';
  is $dctl->pid_file->to_string,    "$ENV{MOJODCTL_PID_FILE}",                          'pid_file';
  is $dctl->workers,                1,                                                  'workers';
};

subtest 'pid file' => sub {
  my $pid_file = tempfile;
  my $dctl     = Mojo::Server::DaemonControl->new(pid_file => $pid_file);
  is $dctl->check_pid, 0, 'no pid';

  ok $dctl->ensure_pid_file, 'ensure_pid_file';
  is $dctl->check_pid, $$, 'wrote pid';

  undef $dctl;
  ok !-e $pid_file, 'pid file cleaned up';
};

done_testing;
