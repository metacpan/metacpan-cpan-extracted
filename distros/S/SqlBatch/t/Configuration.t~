#!/usr/bin/perl

use v5.16;
use strict;
use warnings;
use utf8;

use lib qw(../lib);

use Carp;
use Test::More;
use Data::Dumper;

use SqlBatch::Configuration;

my $file1  =<<'FILE1';
{
    "datasource" : "DBI:RAM:",
    "username" : "user",
    "password" : "pw"
}
FILE1
    ;

my $conf1;
eval {
    $conf1 = SqlBatch::Configuration->new(\$file1);
};
ok(!$@,"Configuration loaded and validated");
say $@;
ok($conf1->item('username') eq 'user',"Retrieve item");
my %h = $conf1->items_hash;
ok(scalar(keys %h) == 3,"Item hash");

my $dbh = $conf1->database_handle;
ok($dbh,"Database handle");

done_testing;
