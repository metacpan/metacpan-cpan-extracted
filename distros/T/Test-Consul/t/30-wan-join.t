#!perl

use strict;
use warnings;

use Test::Consul;

use Test::More;
use Test::Exception;
use HTTP::Tiny;

Test::Consul->skip_all_if_no_bin;

my $tc1;
lives_ok { $tc1 = Test::Consul->start }
  "dc1 start method returned successfully on first instance";
ok $tc1->running, "guard thinks consul dc1 is running";

my $tc2;
lives_ok { $tc2 = Test::Consul->start }
  "dc2 method returned successfully on second instance";
ok $tc2->running, "guard thinks consul dc2 is running";

lives_ok { $tc1->wan_join($tc2) }
  "successfully WAN joined dc1 to dc2";

done_testing;

