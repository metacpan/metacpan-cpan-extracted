#!perl

use strict;
use warnings;

use Test::Consul;

use Test::More;
use Test::Exception;
use HTTP::Tiny;

Test::Consul->skip_all_if_no_bin;

my $tc;
lives_ok { $tc = Test::Consul->start } "start method returned successfully";
ok $tc->running, "guard thinks consul is running";

my $url = "http://127.0.0.1:".$tc->port."/v1/status/leader";
my $http = HTTP::Tiny->new(timeout => 10);
my $res = $http->get($url);
ok $res->{success}, "call to consul succeeded";
like $res->{content}, qr/^"[0-9\.]+:[0-9]+"$/, "consul leader is available";

my $pid = $tc->{_pid};
lives_ok { $tc->end } "end method returned successfully";

ok(! kill(0, $pid), "consul process is really dead");

done_testing;
