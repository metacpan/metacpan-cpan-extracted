#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for running this test" if $@;

plan tests => 1;

use lib 't/lib';

use FindBin;
use TestDB;

my $dbh = TestDB->init_db;
ok($dbh);

my $db = TestDB->db;

open(my $file, "< $FindBin::Bin/test_schema/$db.sql") or die $!;

my $schema = do { local $/; <$file> };

my @sql = split(/\s*;\s*/, $schema);
foreach my $sql (@sql) {
    next unless $sql;
    my ($table) = ($sql =~ m/TABLE `(.*?)`/);
    $dbh->do("DROP TABLE IF EXISTS `$table`") if $table;
    $dbh->do($sql);
}
