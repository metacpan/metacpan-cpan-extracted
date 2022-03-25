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
