#!perl
use strict;
use warnings;
use Test::More;

use IO::Socket;

plan skip_all => "Live testing disabled except for RELEASE_TESTING" unless $ENV{RELEASE_TESTING};

my $sock = IO::Socket::INET->new(
  LocalPort => 8125,
  Proto => "udp",
  Blocking => 0,
) or plan skip_all => "Can't listen UDP";

BEGIN {
  *CORE::GLOBAL::rand = sub { 0 }; # disable sampling
}

use_ok 'Net::Statsd::Client::Telegraf';

sub sends_ok (&@) {
  my ($code, $pattern, $desc) = @_;
  my $ok = eval {
    $code->();
    1;
  };
  if (!$ok) {
    diag "Died: $@";
    fail $desc;
    return;
  }
  my $buf;
  my $ret;
  do { $ret = recv $sock, $buf, 8192, 0 } while !defined $ret && $!{EAGAIN};
  if (!defined $ret) {
    diag "recv failed with $!";
    fail $desc;
    return;
  }
  like $buf, $pattern, $desc;
}

my $client = Net::Statsd::Client::Telegraf->new;

sends_ok { $client->increment("foo1") } qr/^foo1:1\|c$/, "increment";
sends_ok { $client->decrement("foo2") } qr/^foo2:-1\|c$/, "decrement";
sends_ok { $client->update("foo3", 42) } qr/^foo3:42\|c$/, "update";
sends_ok { $client->timing_ms("foo4", 1) } qr/^foo4:1\|ms$/, "timing";
sends_ok {
  my $timer = $client->timer("foo5");
  sleep 1;
  $timer->finish;
} qr/^foo5:[\d\.]+\|ms$/, "timer 2";

sends_ok { $client->increment("foo1", sample_rate => 0.8, tags => { key => "value" } ) } qr/^foo1,key=value:1\|c\|\@0\.8$/, "increment";
sends_ok { $client->decrement("foo2", sample_rate => 0.8, tags => { key => "value" }) } qr/^foo2,key=value:-1\|c\|\@0\.8$/, "decrement";
sends_ok { $client->update("foo3", 42, sample_rate => 0.8, tags => { key => "value" }) } qr/^foo3,key=value:42\|c\|\@0\.8$/, "update";
sends_ok { $client->timing_ms("foo4", 1, sample_rate => 0.8, tags => { key => "value" }) } qr/^foo4,key=value:1\|ms\|\@0\.8$/, "timing";
sends_ok {
  my $timer = $client->timer("foo5", sample_rate => 0.8, tags => { key => "value" });
  sleep 1;
  $timer->finish;
} qr/^foo5,key=value:[\d\.]+\|ms\|\@0\.8$/, "timer 2";

$client = Net::Statsd::Client::Telegraf->new(sample_rate => 0.8, tags => { key => "value" });

sends_ok { $client->increment("foo1") } qr/^foo1,key=value:1\|c\|\@0\.8$/, "increment";
sends_ok { $client->decrement("foo2") } qr/^foo2,key=value:-1\|c\|\@0\.8$/, "decrement";
sends_ok { $client->update("foo3", 42) } qr/^foo3,key=value:42\|c\|\@0\.8$/, "update";
sends_ok { $client->timing_ms("foo4", 1) } qr/^foo4,key=value:1\|ms\|\@0\.8$/, "timing";
sends_ok {
  my $timer = $client->timer("foo5");
  sleep 1;
  $timer->finish;
} qr/^foo5,key=value:[\d\.]+\|ms\|\@0\.8$/, "timer 2";

done_testing;
