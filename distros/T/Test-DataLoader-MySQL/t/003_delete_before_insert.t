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

plan tests => 4;
use Test::DataLoader::MySQL;

my $dbh = DBI->connect($mysqld->dsn()) or die $DBI::errstr;

$dbh->do("CREATE TABLE foo (id INTEGER, name VARCHAR(20))");
$dbh->do("insert into foo set id=0,name='xxx'");

my $data = Test::DataLoader::MySQL->new($dbh, DeleteBeforeInsert=>1);
$data->add('foo', 1,
           {
               id => 0, #id is same as inserted before
               name => 'aaa',
           },
           ['id']);

$data->load('foo', 1);#load data #1
is_deeply($data->do_select('foo', "id=0"), { id=>0, name=>'aaa'});# data is replaced



# load_direct
$data->load_direct('foo',
           {
               id => 0,#same id
               name => 'xxx',
           },
           ['id']);



is_deeply($data->do_select('foo', "id=0"), { id=>0, name=>'xxx'});

# test auto_increment
$dbh->do("CREATE TABLE baz (id INTEGER AUTO_INCREMENT, name VARCHAR(20), PRIMARY KEY(id))") || die $dbh->errstr;
$dbh->do("insert into baz set name='aaa'");
$data->add('baz', 1,
           {
               name => 'aaa',
           },
           ['id']);

my $keys = $data->load('baz', 1);#load data #1
is( $keys->{id}, 2);


is_deeply($data->do_select('baz', "id=2"), { id=>2, name=>'aaa'});



$data->clear;
$mysqld->stop;

