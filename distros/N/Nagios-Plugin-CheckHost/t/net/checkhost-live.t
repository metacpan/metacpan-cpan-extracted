#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'set TEST_LIVE env variable to test live'
  unless $ENV{TEST_LIVE};

use_ok 'Net::CheckHost';

my $ch = new_ok 'Net::CheckHost';

subtest 'ping check' => sub {
    my $r = $ch->request('check-ping', host => 'localhost', max_nodes => 1);
    my $rid = $r->{request_id};
    ok $rid, 'request id';
    ok $r->{nodes}, 'nodes list';
    my $random_node = (keys %{$r->{nodes}})[0];

    my $r2 = $ch->request('check-result/' . $rid);
    ok exists $r2->{$random_node}, 'node check result';
};

done_testing();
