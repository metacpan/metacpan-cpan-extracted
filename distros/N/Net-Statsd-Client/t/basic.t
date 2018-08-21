#!perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use TestStatsd;
$TestStatsd::ALWAYS_SAMPLE = 1;

use_ok 'Net::Statsd::Client';

my $client = Net::Statsd::Client->new;

sends_ok { $client->increment("foo1") } $client, qr/^foo1:1\|c$/, "increment";
sends_ok { $client->decrement("foo2") } $client, qr/^foo2:-1\|c$/, "decrement";
sends_ok { $client->update("foo3", 42) } $client, qr/^foo3:42\|c$/, "update";
sends_ok { $client->timing_ms("foo4", 1) } $client, qr/^foo4:1\|ms$/, "timing";
sends_ok {
  my $timer = $client->timer("foo5");
  sleep 1;
  $timer->finish;
} $client, qr/^foo5:[\d\.]+\|ms$/, "timer 2";

$client = Net::Statsd::Client->new(sample_rate => 0.42);

sends_ok { $client->increment("foo1") } $client, qr/^foo1:1\|c\|\@0\.42$/, "increment sampled";
sends_ok { $client->decrement("foo2") } $client, qr/^foo2:-1\|c\|\@0\.42$/, "decrement sampled";
sends_ok { $client->update("foo3", 42) } $client, qr/^foo3:42\|c\|\@0\.42$/, "update sampled";
sends_ok { $client->timing_ms("foo4", 1) } $client, qr/^foo4:1\|ms\|\@0\.42$/, "timing sampled";
sends_ok {
  my $timer = $client->timer("foo5");
  sleep 1;
  $timer->finish;
} $client, qr/^foo5:[\d\.]+\|ms\|\@0\.42$/, "timer 2 sampled";

sends_ok { $client->gauge("luftballons", 99) } $client, qr/^luftballons:99\|g\|\@0\.42$/, "gauge";
sends_ok { $client->set_add("users", "gary") } $client, qr/^users:gary\|s\|\@0\.42$/, "set";

done_testing;
