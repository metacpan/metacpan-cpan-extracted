#!/usr/bin/env perl

use File::Which;
use Test::More tests => 6;
use File::Temp qw{ tempdir };
BEGIN { use_ok('Monitoring::Generator::TestConfig') };

my $test_dir = tempdir(CLEANUP => 1);

my $mgt = Monitoring::Generator::TestConfig->new( 'output_dir' => $test_dir, 'overwrite_dir' => 1 );
isa_ok($mgt, 'Monitoring::Generator::TestConfig');


########################################
# _merge_config_hashes
my $hash1    = { 'a' => 1, 'b' => 2, 'c' => [ 'a', 'b', 'c' ] };
my $hash2    = undef;
my $expected = { 'a' => 1, 'b' => 2, 'c' => [ 'a', 'b', 'c' ] };
my $got = $mgt->_merge_config_hashes($hash1, $hash2);
is_deeply($got, $expected, 'internal: _merge_config_hashes($hashref, undef)');

$hash1    = { 'a' => 1, 'b' => 2, 'c' => [ 'a', 'b', 'c' ] };
$hash2    = { 'a' => 1, 'b' => 2, 'c' => 3 };
$expected = { 'a' => 1, 'b' => 2, 'c' => 3 };
$got = $mgt->_merge_config_hashes($hash1, $hash2);
is_deeply($got, $expected, 'internal: _merge_config_hashes($hashref, $hashref)');

$hash1    = { 'a' => 1, 'b' => 2, 'c' => [ 'a', 'b', 'c' ] };
$hash2    = { 'b' => 'x' };
$expected = { 'a' => 1, 'b' => 'x', 'c' => [ 'a', 'b', 'c' ] };
$got = $mgt->_merge_config_hashes($hash1, $hash2);
is_deeply($got, $expected, 'internal: _merge_config_hashes($hashref, $hashref2)');


########################################
# _config_hash_to_string
$hash1 = { 'abc' => 1, 'bcdefgh' => 'blah_blub', 'yxz' => [ 'a', 'b', 'c' ] };
$expected = 'abc=1
bcdefgh=blah_blub
yxz=a
yxz=b
yxz=c
';
$got = $mgt->_config_hash_to_string($hash1);
is($got, $expected, 'internal: _config_hash_to_string($hashref)');
