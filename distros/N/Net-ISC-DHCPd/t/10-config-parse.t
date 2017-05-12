#!perl

use warnings;
use strict;
use lib './lib';
use Benchmark;
use Test::More;

my $count  = $ENV{'COUNT'} || 1;
my $config = "./t/data/dhcpd.conf";
my $lines  = 57;

plan tests => 1 + 36 * $count;

use_ok("Net::ISC::DHCPd::Config");

my $time = timeit($count, sub {
    my $config = Net::ISC::DHCPd::Config->new(file => $config);

    is(ref $config, 'Net::ISC::DHCPd::Config', 'config object constructed');
    is($config->parse, $lines, 'all config lines parsed') or BAIL_OUT 'failed to parse config';

    is(scalar(@_=$config->keyvalues), 3, 'key values');
    is(scalar(@_=$config->optionspaces), 1, 'option space');
    is(scalar(@_=$config->options), 1, 'options');
    is(scalar(@_=$config->subnets), 1, 'subnets');
    is(scalar(@_=$config->hosts), 2, 'hosts');
    is(scalar(@_=$config->includes), 1, 'includes');

    my $included = $config->includes->[0];
    like($included->file, qr{foo-included.conf}, 'foo-included.conf got included');
    is($included->parse, 6, 'included file got parsed');
    is(scalar(@_=$included->hosts), 1, 'included file contains one hosts');

    is(scalar(@_=$config->optioncodes), 3, 'option space options');
    my $space = $config->optioncodes->[0];
    is($space->name, 'bar', 'option space name');
    is($space->code, 1, 'option space code');
    is($space->prefix, 'foo', 'option space prefix');

    my $subnet = $config->subnets->[0];
    my $subnet_opt = $subnet->options->[0];
    is($subnet->address, '10.0.0.96/27', 'subnet address');
    is($subnet_opt->name, 'domain-name', 'subnet option name');
    is($subnet_opt->value, 'isc.org', 'subnet option value');
    ok($subnet_opt->quoted, 'subnet option is quoted');
    is(scalar(@_=$subnet->pools), 3, 'three subnet pools found');

    is($config->find_subnets({ address => 'foo' }), 0, 'could not find subnets with "foo" as network address');
    is($config->find_subnets({ address => '10.0.0.96/27' }), 1, 'found subnets with "10.0.0.96/27" as network address');
    is($config->remove_subnets({ address => '10.0.0.96/27' }), 1, 'removed subnets with "10.0.0.96/27" as network address');
    is($config->find_subnets({ address => '10.0.0.96/27' }), 0, 'could not find subnets with "10.0.0.96/27" as network address');

    my $range = $subnet->pools->[0]->ranges->[0];
    is($range->lower, '10.0.0.98/32', 'lower pool range');
    is($range->upper, '10.0.0.103/32', 'upper pool range');

    my $host = $config->hosts->[0];
    is($host->name, 'foo', 'host foo found');
    is($host->fixedaddresses->[0]->value, '10.19.83.102', 'fixed address found');
    is($host->hardwareethernet->value, '00:0e:35:d1:27:e3', 'macaddress found');

    $host = $config->hosts->[1];
    is($host->name, 'foo2', 'host foo2 found');
    is($host->hardwareethernet->value, '0:e:5:d1:27:e3', 'macaddress found');

    my $shared_subnets = $config->sharednetworks->[0]->subnets;
    is(int(@$shared_subnets), 2, 'shared subnets found');

    my $function = $config->functions->[0];
    ok($function, 'function defined');
    is($function->name, 'commit', 'commit function found');
    is($function->keyvalues->[0]->name, 'set', 'function first keyvalue found');
    is($function->conditionals->[0]->type, 'if', 'if conditional found');
});

diag(($lines * $count) .": " .timestr($time));
