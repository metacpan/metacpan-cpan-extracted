use strict;
use warnings;
use Test::More;

package test::host;
use Moose; with 'Net::Riak::Role::Hosts';

package main;

my $test = test::host->new();
is scalar @{$test->host}, 1, 'got one host';

ok my $host = $test->get_host, 'got host';
is $host, 'http://127.0.0.1:8098', 'host is ok';

done_testing;
