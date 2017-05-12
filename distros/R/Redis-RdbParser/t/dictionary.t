use Test::More tests => 6;

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
my $db;
my $object_key;
my $num_entries;
my $last_field;
my $last_value;
my $end_key;

sub start_rdb {
    my $filename = shift;
    $dump = $filename;
}

sub start_database {
    my $db_number = shift;
    $db = $db_number;
}

sub key {
    my $key = shift;
    $object_key = $key;
}

sub set {
    my ($key, $value, $expiry) = @_;
}

sub start_hash {
    my ($key, $length, $expiry) = @_;
    $num_entries = $length;
}

sub hset {
    my ($key, $field, $value) = @_;
    $last_field = $field;
    $last_value = $value;
}

sub end_hash {
    my $key = shift;
    $end_key = $key;
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

my $filter = {
    'dbs' => [0],
    'types' => ["hash"],
};

$parser->parse("$Bin/dump/dictionary.rdb", $filter);

ok($dump eq "$Bin/dump/dictionary.rdb", "start_rdb");
ok($db == 0, "start_database");
ok($object_key eq "force_dictionary", "key");
ok($num_entries == 1000, "start_hash");
ok($last_field eq "PET9GLTADHF2LAE6EUNDX6SPE1M7VFWBK5S9TW3967SAG0UUUB" 
    && $last_value eq "4YOEJ3QPNQ6UADK4RZ3LDN8H0KQHD9605OQTJND8B1FTODSL74",
    "hset");
ok($end_key eq "force_dictionary", "end_hash");
