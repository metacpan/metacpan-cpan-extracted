use Test::More tests => 2;

use warnings;
use strict;

use blib;
use FindBin qw($Bin);
use Redis::RdbParser;

my $callbacks = {
    "start_rdb"         => \&start_rdb,
    "start_database"    => \&start_database,
    "key"               => \&key,
    "set"               => \&set,
    "start_hash"        => \&start_hash,
    "hset"              => \&hset,
    "end_hash"          => \&end_hash,
    "start_set"         => \&start_set,
    "sadd"              => \&sadd,
    "end_set"           => \&end_set,
    "start_list"        => \&start_list,
    "rpush"             => \&rpush,
    "end_list"          => \&end_list,
    "start_sorted_set"  => \&start_sorted_set,
    "zadd"              => \&zadd,
    "end_sorted_set"    => \&end_sorted_set,
    "end_database"      => \&end_database,
    "end_rdb"           => \&end_rdb,
};

my $dump;
my $test_value;

sub start_rdb {
    my $filename = shift;
    $dump = $filename;
}

sub start_database {
    my $db_number = shift;
}

sub key {
    my $key = shift;
}

sub set {
    my ($key, $value, $expiry) = @_;
    $test_value = $value;
}

sub start_hash {
    my ($key, $length, $expiry) = @_;
}

sub hset {
    my ($key, $field, $value) = @_;
}

sub end_hash {
    my $key = shift;
}

sub start_set {
    my ($key, $cardinality, $expiry) = @_;
}

sub sadd {
    my ($key, $member) = @_;
}

sub end_set {
    my ($key) = @_;
}

sub start_list {
    my ($key, $length, $expiry) = @_;
}

sub rpush {
    my ($key, $value) = @_;
}

sub end_list {
    my ($key) = @_;
}

sub start_sorted_set {
    my ($key, $length, $expiry) = @_;
}

sub zadd {
    my ($key, $score, $member) = @_;
}

sub end_sorted_set {
    my ($key) = @_;
}

sub end_database {
    my $db_number = shift;
}

sub end_rdb {
    my $filename = shift;
}

my $parser = new Redis::RdbParser($callbacks);
$parser->parse("$Bin/dump/easily_compressible_string_key.rdb");
ok($dump eq "$Bin/dump/easily_compressible_string_key.rdb", "start_rdb");
ok($test_value eq "Key that redis should compress easily", "set");
