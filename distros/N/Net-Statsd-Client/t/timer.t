#!perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use TestStatsd;
use Time::HiRes qw(sleep);

use_ok 'Net::Statsd::Client';

my $client = Net::Statsd::Client->new;

sends_ok {
  my $timer = $client->timer("foo");
  $timer->finish;
} $client, qr/foo/, "vanilla";

sends_ok {
  my $timer = $client->timer("foo");
  $timer->metric("bar");
  $timer->finish;
} $client, qr/bar/, "changed metric";

# Test that the timer returns the milliseconds
my $timer = $client->timer('foo');
sleep 0.1;
my $elapsed_ms = $timer->finish;
ok( $elapsed_ms > 100, "timer->finish returned elapsed ms");

done_testing;
