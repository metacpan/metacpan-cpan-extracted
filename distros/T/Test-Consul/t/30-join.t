#!perl

use strict;
use warnings;

use Test::Consul;

use Test::More;
use Test::Exception;
use HTTP::Tiny;
use JSON::MaybeXS;

Test::Consul->skip_all_if_no_bin;

my $tc1;
lives_ok { $tc1 = Test::Consul->start }
  "first consul instance started";
ok $tc1->running, "first consul instance is running";

my $tc2;
lives_ok { $tc2 = Test::Consul->start(datacenter => $tc1->datacenter) }
  "second consul instance started";
ok $tc1->running, "second consul instance is running";

lives_ok { $tc1->join($tc2) }
  "joined servers";

my $port = $tc1->port;
my $http = HTTP::Tiny->new;
my $res = $http->get("http://127.0.0.1:$port/v1/agent/members");

ok $res->{success}, "get members succeeded";

my $members = decode_json($res->{content});
is scalar @$members, 2, "two members in cluster";

done_testing;

