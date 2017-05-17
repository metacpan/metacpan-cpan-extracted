use Mojo::Base -strict;
use Test::More;
use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';
use FindBin;
use IO::Socket::INET;
use Mojo::File 'path';
use Mojo::IOLoop::Server;
use Mojo::UserAgent;

plan skip_all => $@
  unless -e '.git' and eval 'require Proc::ProcessTable && require File::Which && 1';

# Prepare script
my $dir = tempdir CLEANUP => 1;
my $script = catfile $dir, 'myapp.pl';
my $port = Mojo::IOLoop::Server->generate_port;

path($script)->spurt(<<EOF);
use lib "$FindBin::Bin/../lib";
use Mojolicious::Lite;

plugin Config => {
  default => {
    hypnotoad => {
      inactivity_timeout => 3,
      listen => ['http://127.0.0.1:$port'],
      workers => 2
    }
  }
};

plugin CGI => {
  route => '/',
  script => "$script", # this is required to run the test for 0.26
  run => sub {
    print "HTTP/1.1 200 OK\r\n";
    print "Content-Type: text/text; charset=ISO-8859-1\r\n";
    print "\r\n";
    print "Hello CGI!\n";
  },
};

app->start;
EOF

# Start server
my $hypnotoad = File::Which::which('hypnotoad');
open my $start, '-|', $^X, $hypnotoad, $script;
sleep 1 while !_port($port);

# Remember PID
open my $file, '<', catfile($dir, 'hypnotoad.pid');
my $pid = <$file>;
chomp $pid;
ok $pid, "PID $pid found";

# Application is alive
my $ua = Mojo::UserAgent->new;
my $tx = $ua->get("http://127.0.0.1:$port/");
is $tx->res->code, 200,            'right status';
is $tx->res->body, "Hello CGI!\n", 'right content';

# Hammer the server
my $requests = 20;
diag("Hammering the server with $requests requests");
for my $i (1 .. $requests) {
  $ua->get("http://127.0.0.1:$port/");
  sleep 1;
}

# See whether zombies are reaped
my $seconds = 20;
my $ts      = time;
diag("Waiting for the reaper");
for my $i (1 .. $seconds) {
  sleep 1;
  last if _zombies() == 0;
}

my $delta = time - $ts;
is _zombies(), 0, "No zombies left after $delta seconds";

# Stop the server
open my $stop, '-|', $^X, $hypnotoad, $script, '-s';
sleep 1 while _port($port);

# Checking Processes
my $alive = kill 0 => $pid;
is $alive, 0, "$pid is terminated";

sub _port { IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => shift) }

sub _zombies {
  my $processes = Proc::ProcessTable->new(enable_ttys => 0);

  # say join(', ', $processes->fields);
  my $grp     = getpgrp $pid;
  my $zombies = 0;
  foreach my $proc (@{$processes->table}) {
    $zombies++ if $proc->pgrp == $grp and $proc->state eq 'defunct';
  }
  return $zombies;
}

done_testing();
