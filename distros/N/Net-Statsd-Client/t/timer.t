#!perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use TestStatsd;

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

done_testing;
