#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More;
use DBI;

eval "use Test::mysqld 0.11";
plan skip_all => "Test::mysqld 0.11(or grator version) is need for test" if ( $@ );

my $mysqld = Test::mysqld->new( my_cnf => {
                                  'skip-networking' => '',
                                }
                              );
plan skip_all => "MySQL may not be installed" if ( !defined $mysqld );

plan tests => 3;

use Test::DataLoader::MySQL;

my $dbh = DBI->connect($mysqld->dsn()) or die $DBI::errstr;

$dbh->do("CREATE TABLE foo (id INTEGER, name VARCHAR(20))");


my $data = Test::DataLoader::MySQL->new($dbh);
$data->load_file('t/testdata.pm');

$data->load('foo', 1);#load data #1
$data->load('foo', 2);#load data #2

is_deeply($data->do_select('foo', "id=1"), { id=>1, name=>'aaa'});
is_deeply([$data->do_select('foo', "id IN(1,2)")], [ { id=>1, name=>'aaa'},
                                                     { id=>2, name=>'bbb'},]);


$data->clear;

$data = Test::DataLoader::MySQL->new($dbh);
is($data->do_select('foo', "1=1"), undef);
$data->clear;

$mysqld->stop;
