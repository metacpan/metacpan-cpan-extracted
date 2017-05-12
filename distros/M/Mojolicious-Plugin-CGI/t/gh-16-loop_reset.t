BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }
use Mojo::Base -strict;
use Test::More;

plan skip_all => 'set TEST_MORBO to enable this test (developer only!)' unless $ENV{TEST_MORBO};
plan skip_all => 'Parallel::ForkManager is not available'               unless eval 'require Parallel::ForkManager;1';
plan skip_all => 't/cgi-bin/slow.pl'                                    unless -x 't/cgi-bin/slow.pl';

use File::Spec::Functions 'catdir';
use File::Temp 'tempdir';
use IO::Socket::INET;
use Mojo::IOLoop::Server;
use Mojo::Server::Daemon;
use Mojo::Server::Morbo;
use Mojo::UserAgent;
use Mojo::Util 'spurt';

# Prepare script
my $n      = 5;
my $dir    = tempdir CLEANUP => 1;
my $script = catdir $dir, 'myapp.pl';
my $morbo  = Mojo::Server::Morbo->new(watch => [$script]);
spurt <<'EOF', $script;
use Mojolicious::Lite;
app->log->level('fatal');
plugin CGI => ['/slow' => 't/cgi-bin/slow.pl'];
app->start;
EOF

# Start
my $port = Mojo::IOLoop::Server->generate_port;

# assume morbo is in the same dir as the perl runing this test
# this is not WIN32 compatible, and 5.14+, but since dev test only...
(my $prefix = $^X) =~ s!/perl[^/]*$!!;
my $pid = open my $server, '-|', $^X, "$prefix/morbo", '-l', "http://127.0.0.1:$port", $script;
sleep 1 until _server_running($port);

my $ua = Mojo::UserAgent->new;
my $pm = Parallel::ForkManager->new($n);
$pm->run_on_finish(
  sub {
    my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
    my ($is_finished, $code, $body) = @$data;
    ok $is_finished, 'transaction is finished';
    is $code, 200, 'right status';
  }
);

foreach my $req (1 .. $n) {
  $pm->start and next;
  my $tx = $ua->get("http://127.0.0.1:$port/slow");
  $pm->finish(0, [$tx->is_finished, $tx->res->code, $tx->res->body]);
}
$pm->wait_all_children;

kill 'INT', $pid;
sleep 1 while _server_running($port);

done_testing();

sub _server_running { IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => shift) }
