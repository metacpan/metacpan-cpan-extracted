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

plan tests => 1;

use Test::DataLoader::MySQL;
my $dbh = DBI->connect($mysqld->dsn()) or die $DBI::errstr;

$dbh->do("CREATE TABLE foo (id INTEGER, name VARCHAR(20))");
$dbh->do("insert into foo set id=0,name='xxx'");

my $data = Test::DataLoader::MySQL->new($dbh, Keep => 1);#Keep option specified
$data->add('foo', 1,
           {
               id => 1,
               name => 'aaa',
           },
           ['id']);
$data->add('foo', 2,
           {
               id => 2,
               name => 'bbb',
           },
           ['id']);

$data->load('foo', 1);#load data #1
$data->load('foo', 2);#load data #2

$data->clear;

$data = Test::DataLoader::MySQL->new($dbh);
my $expected = [
    { id=>0, name=>'xxx'},
    { id=>1, name=>'aaa'},
    { id=>2, name=>'bbb'},
];
is_deeply([$data->do_select('foo', "1=1")], $expected);#remain all data because Keep option specified

$data->clear;

$mysqld->stop;
