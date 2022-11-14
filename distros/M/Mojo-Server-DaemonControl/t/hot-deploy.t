use Mojo::Base -strict;
use Test2::V0;
use Mojo::File qw(curfile);
use Mojo::IOLoop::Server;
use Mojo::Promise;
use Mojo::Server::DaemonControl;
use Mojo::UserAgent;
use Time::HiRes qw(time);

plan skip_all => 'TEST_LIVE=1' unless $ENV{TEST_LIVE};

my $app    = curfile->dirname->child('myapp.pl');
my $listen = sprintf 'http://127.0.0.1:%s', Mojo::IOLoop::Server->generate_port;

pipe my $UA_READ, my $UA_WRITE or die $!;
$UA_READ->blocking(0);

subtest 'hot deploy workers' => sub {
  my $dctl = Mojo::Server::DaemonControl->new(
    graceful_timeout   => 2,
    heartbeat_interval => 0.3,
    heartbeat_timeout  => 1,
    listen             => [$listen],
    workers            => 2,
  );

  my ($ua_result,  %workers)       = ('');
  my ($n_requests, $request_limit) = (0, 20);
  $dctl->on(
    heartbeat => sub {
      my ($dctl, $w) = @_;
      $workers{$w->{pid}} = $w;

      # Check tha we don't miss out on any requests
      sysread $UA_READ, my $ua_chunk, 1024, 0;
      $ua_result .= $ua_chunk     if $ua_chunk;
      run_request_in_fork('/pid') if $n_requests++ < $request_limit;
      run_request_in_fork('/pid') if $n_requests++ < $request_limit;

      # Reload the application - Only do this once
      state $reloaded = 0;
      Mojo::Server::DaemonControl->new->reload($app) if $w->{time} && ++$reloaded == 3;
      $dctl->stop                                    if split("\n", $ua_result) >= $request_limit;
    }
  );

  is int($dctl->run($app)), 0, 'ran successfully';
  is int(values %workers),  4, 'started n workers';
  unlike $ua_result, qr{^/pid:0:}m, 'get /pid was all successful' or diag $ua_result;

  my $n_uniq = 0;
  for my $pid (sort keys %workers) {
    my $todo = todo 'this test is unlikely to succeed';
    like $ua_result, qr{\bpid=$pid\b}, "answer from worker $pid" and $n_uniq++;
  }

  ok $n_uniq >= 3, "at least three children ($n_uniq) receieved requests";
};

done_testing;

sub run_request_in_fork {
  my $path = shift;
  return if fork;

  my $ua  = Mojo::UserAgent->new;
  my $tx  = $ua->get("$listen$path");
  my $err = $tx->error;
  syswrite $UA_WRITE, sprintf "$path:%s:%s\n",
    $err ? ($err->{code} // 0, $err->{message}) : ($tx->res->code, $tx->res->text);
  exit 0;
}
