#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture(
    schema  => testrundb_schema,
    fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml',
);
# -----------------------------------------------------------------------------------------------------------------

my $retval;
my $i_host_id_host1 = `$^X -Ilib bin/tapper host-new  --name="host1"`;
chomp $i_host_id_host1;

my $host_result = model('TestrunDB')->resultset('Host')->find($i_host_id_host1);
ok($host_result->id, 'inserted host');
ok($host_result->free, 'inserted host - free');
is($host_result->name, 'host1', 'inserted host - name');

# --------------------------------------------------

my $answer = `$^X -Ilib bin/tapper host-feature-new --name="host1" --entry=mem --value=2048`;

my $feature_result = model('TestrunDB')->resultset('HostFeature')->search({entry => "mem"})->first;
ok($feature_result && $feature_result->id, 'inserted feature');
is($feature_result->host_id, $i_host_id_host1, 'inserted feature - host_id');
is($feature_result->entry,   'mem',            'inserted feature - name');
is($feature_result->value,   2048,             'inserted feature - value');

# --------------------------------------------------

$answer = `$^X -Ilib bin/tapper host-feature-update --name="host1" --entry=mem --value=4096`;

$feature_result = model('TestrunDB')->resultset('HostFeature')->search({host_id => $i_host_id_host1, entry => "mem"})->first;
ok($feature_result && $feature_result->id, 'updated feature');
is($feature_result->host_id, $i_host_id_host1,  'updated feature - host_id');
is($feature_result->entry,   'mem',             'updated feature - name');
is($feature_result->value,   4096,              'updated feature - value');

# --------------------------------------------------

$answer = `$^X -Ilib bin/tapper host-feature-delete --name="host1" --entry=mem 2>&1`;
chomp $answer;
like($answer, qr/--force/, "needs --force to delete");

$feature_result = model('TestrunDB')->resultset('HostFeature')->search({host_id => $i_host_id_host1, entry => "mem"})->first;
ok($feature_result && $feature_result->id, 'feature still exists');
is($feature_result->host_id, $i_host_id_host1,  'feature still exists - host_id');
is($feature_result->entry,   'mem',             'feature still exists - name');
is($feature_result->value,   4096,              'feature still exists - value');

# --------------------------------------------------

$answer = `$^X -Ilib bin/tapper host-feature-delete --name="host1" --entry=mem --force 2>&1`;

unlike ($answer, qr/--force/, "No hint to use --force because we do.");
$feature_result = model('TestrunDB')->resultset('HostFeature')->search({host_id => $i_host_id_host1, entry => "mem"},{rows => 1})->first;
is($feature_result, undef, 'feature deleted');

done_testing();
