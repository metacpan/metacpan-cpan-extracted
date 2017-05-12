#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Monitoring::Plugin;
use Monitoring::Plugin::Functions;
use Nagios::Plugin::CheckHost::Node;
use Nagios::Plugin::CheckHost::Result::Ping;
use_ok 'Nagios::Plugin::CheckHost::Ping';

@ARGV = (
    qw(--host localhost),
    qw(--max_nodes 3),
    qw(--loss_threshold_warning 25),
    qw(--loss_threshold_critical 50),
    qw(--warning 0),
    qw(--critical 1)
);

Monitoring::Plugin::Functions::_fake_exit(1);
my $ping = new_ok 'Nagios::Plugin::CheckHost::Ping';
$ping->nagios->getopts;
$ping->{request_id} = 10;

my $nodes = [
    Nagios::Plugin::CheckHost::Node->new("7f000001", ['be', 'Antwerp']),
    Nagios::Plugin::CheckHost::Node->new("7f000002", ['fr', 'Paris']),
    Nagios::Plugin::CheckHost::Node->new("7f000003", ['it', 'Milan']),
];
my $IP        = "127.0.0.1";
my @OK        = ("OK", 1);
my @TIMEOUT   = ("TIMEOUT", 5);
my @RESULT_OK = ([@OK, $IP], [@OK], [@OK], [@OK]);

subtest 'loss ok result' => sub {
    my $pingr = new_ok 'Nagios::Plugin::CheckHost::Result::Ping',
      [nodes => $nodes];
    $pingr->store_result({
            $nodes->[0]->identifier => [[@RESULT_OK]],
            $nodes->[1]->identifier => [[@RESULT_OK]],
            $nodes->[2]->identifier =>
              [[[@TIMEOUT, $IP], [@OK], [@OK], [@OK]]]
        }
    );

    is $pingr->calc_loss($nodes->[0]), 0;
    is $pingr->calc_loss($nodes->[1]), 0;
    is $pingr->calc_loss($nodes->[2]), 0.25;

    my $e = $ping->process_check_result($pingr);
    is $e->code, Monitoring::Plugin::OK, "ok exit code";
};

subtest 'loss warning threshold' => sub {
    my $pingr = new_ok 'Nagios::Plugin::CheckHost::Result::Ping',
      [nodes => $nodes];
    $pingr->store_result({
            $nodes->[0]->identifier => [[@RESULT_OK]],
            $nodes->[1]->identifier =>
              [[[@OK, $IP], [@OK], [@TIMEOUT], [@TIMEOUT]]],
            $nodes->[2]->identifier =>
              [[[@TIMEOUT, $IP], [@TIMEOUT], [@TIMEOUT], [@TIMEOUT]]]
        }
    );

    is $pingr->calc_loss($nodes->[0]), 0;
    is $pingr->calc_loss($nodes->[1]), 0.5;
    is $pingr->calc_loss($nodes->[2]), 1;

    my $e = $ping->process_check_result($pingr);
    is $e->code, Monitoring::Plugin::WARNING, "warning exit code";
};

subtest 'loss critical threshold' => sub {
    my $pingr = new_ok 'Nagios::Plugin::CheckHost::Result::Ping',
      [nodes => $nodes];
    my @failed = ([@TIMEOUT, $IP], [@TIMEOUT], [@TIMEOUT], [@TIMEOUT]);
    $pingr->store_result({
            $nodes->[0]->identifier => [[@RESULT_OK]],
            $nodes->[1]->identifier => [[@failed]],
            $nodes->[2]->identifier => [[@failed]],
        }
    );

    is $pingr->calc_loss($nodes->[0]), 0;
    is $pingr->calc_loss($nodes->[1]), 1;
    is $pingr->calc_loss($nodes->[2]), 1;

    my $e = $ping->process_check_result($pingr);
    is $e->code, Monitoring::Plugin::CRITICAL, "critical exit code";
};

subtest 'slave fault' => sub {
    my $pingr = new_ok 'Nagios::Plugin::CheckHost::Result::Ping',
      [nodes => $nodes];
    $pingr->store_result({
            $nodes->[0]->identifier => [[@RESULT_OK]],
            $nodes->[1]->identifier => [[@RESULT_OK]],
            $nodes->[2]->identifier => [undef]
        }
    );

    my $e = $ping->process_check_result($pingr);
    is $e->code, Monitoring::Plugin::OK, "ok exit code";
};

done_testing();
