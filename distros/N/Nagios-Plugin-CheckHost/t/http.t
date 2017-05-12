#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Monitoring::Plugin;
use Monitoring::Plugin::Functions;
Monitoring::Plugin::Functions::_fake_exit(1);

use Nagios::Plugin::CheckHost::Node;
use Nagios::Plugin::CheckHost::Result::Http;
use_ok 'Nagios::Plugin::CheckHost::HTTP';

@ARGV = (
    qw(--host localhost),
    qw(--max_nodes 3),
    qw(--warning 0),
    qw(--critical 1),
);


my $http = new_ok 'Nagios::Plugin::CheckHost::HTTP';
$http->nagios->getopts;
$http->{request_id} = 10;

my $nodes = [
    Nagios::Plugin::CheckHost::Node->new("7f000001", ['be', 'Antwerp']),
    Nagios::Plugin::CheckHost::Node->new("7f000002", ['fr', 'Paris']),
    Nagios::Plugin::CheckHost::Node->new("7f000003", ['it', 'Milan']),
];

my $IP           = "127.0.0.1";
my @OK           = (1, '0.13', "OK", "200", $IP);
my @SERVER_ERROR = (0, '0.17', "Not found", "404", $IP);

subtest 'ok result' => sub {
    my $httpr = new_ok 'Nagios::Plugin::CheckHost::Result::Http',
      [nodes => $nodes];
    $httpr->store_result({
            $nodes->[0]->identifier => [[@OK]],
            $nodes->[1]->identifier => [[@OK]],
            $nodes->[2]->identifier => [[@OK]],
        }
    );

    my $e = $http->process_check_result($httpr);
    is $e->code, Monitoring::Plugin::OK, "ok exit code";
};

subtest 'warning threshold' => sub {
    my $httpr = new_ok 'Nagios::Plugin::CheckHost::Result::Http',
      [nodes => $nodes];
    $httpr->store_result({
            $nodes->[0]->identifier => [[@OK]],
            $nodes->[1]->identifier => [[@OK]],
            $nodes->[2]->identifier => [[@SERVER_ERROR]],
        }
    );

    my $e = $http->process_check_result($httpr);
    is $e->code, Monitoring::Plugin::WARNING, "warning exit code";
};

subtest 'critical threshold' => sub {
    my $httpr = new_ok 'Nagios::Plugin::CheckHost::Result::Http',
      [nodes => $nodes];
    $httpr->store_result({
            $nodes->[0]->identifier => [[@OK]],
            $nodes->[1]->identifier => [[@SERVER_ERROR]],
            $nodes->[2]->identifier => [[@SERVER_ERROR]],
        }
    );

    my $e = $http->process_check_result($httpr);
    is $e->code, Monitoring::Plugin::CRITICAL, "critical exit code";
};

subtest 'slave fault' => sub {
    my $httpr = new_ok 'Nagios::Plugin::CheckHost::Result::Http',
      [nodes => $nodes];
    $httpr->store_result({
            $nodes->[0]->identifier => [[@OK]],
            $nodes->[1]->identifier => [[@OK]],
            $nodes->[2]->identifier => [undef,"some message"],
        }
    );

    my $e = $http->process_check_result($httpr);
    is $e->code, Monitoring::Plugin::OK, "ok exit code";
};

done_testing();
