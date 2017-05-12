#!perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use TestStatsd;

use_ok 'Net::Statsd::Client';

my @warnings;
my $client = Net::Statsd::Client->new(warning_callback => sub { push @warnings, shift });

my $timer = $client->timer("test");
undef $timer;

is scalar @warnings, 1, "One warning sent through callback";
like $warnings[0], qr/Unfinished/, "It's the right warning";

done_testing;
