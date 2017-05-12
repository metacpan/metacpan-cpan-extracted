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

plan tests => 20;
use Test::DataLoader::MySQL;

my $dbh = DBI->connect($mysqld->dsn()) or die $DBI::errstr;

$dbh->do("CREATE TABLE foo (id INTEGER, name VARCHAR(20))");
$dbh->do("CREATE TABLE bar (id INTEGER, name VARCHAR(20))");
$dbh->do("insert into foo set id=0,name='xxx'");

my $data = Test::DataLoader::MySQL->new($dbh);
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



my $keys;
$keys = $data->load('foo', 1);#load data #1
is($keys->{id}, 1);

$keys = $data->load('foo', 2);#load data #2
is($keys->{id}, 2);

is_deeply($data->do_select('foo', "id=1"), { id=>1, name=>'aaa'});
is_deeply([$data->do_select('foo', "id IN(1,2)")], [ { id=>1, name=>'aaa'},
                                                     { id=>2, name=>'bbb'},]);


# test load_with_option
$data->add('bar', 1,
           {
               id => 1,
               name => 'aaa',
           },
           ['id']);

$data->load('bar', 1, { name=>'bbb' });#load data #1 but name is altered to 'aaa'->'bbb'
is_deeply($data->do_select('bar', "id=1"), { id=>1, name=>'bbb'});


# load_direct
$data->load_direct('foo',
           {
               id => 3,
               name => 'xxx',
           },
           ['id']);
$data->load_direct('foo',
           {
               id => 4,
               name => 'yyy',
           },
           ['id']);



is_deeply($data->do_select('foo', "id=3"), { id=>3, name=>'xxx'});
is_deeply([$data->do_select('foo', "id IN(3,4)")], [ { id=>3, name=>'xxx'},
                                                     { id=>4, name=>'yyy'},]);


# test auto_increment
$dbh->do("CREATE TABLE baz (id INTEGER AUTO_INCREMENT, name VARCHAR(20), PRIMARY KEY(id))") || die $dbh->errstr;
$dbh->do("insert into baz set name='xxx'");

$data->add('baz', 1,
           {
               name => 'aaa',
           },
           ['id']);
$data->add('baz', 2,
           {
               name => 'bbb',
           },
           ['id']);

$keys = $data->load('baz', 1);#load data #1
is( $keys->{id}, 2);


$keys = $data->load('baz', 2);#load data #2
is( $keys->{id}, 3);


is_deeply($data->do_select('baz', "id=2"), { id=>2, name=>'aaa'});
is_deeply([$data->do_select('baz', "id IN(2,3)")], [ { id=>2, name=>'aaa'},
                                                     { id=>3, name=>'bbb'},]);
$keys = $data->load_direct('baz',
                           {
                               name => 'ccc',
                           },
                           ['id']);
is( $keys->{id}, 4);
is_deeply($data->do_select('baz', "id=4"), { id=>4, name=>'ccc'});


# Test primary key check
$data->add('foo', 100,
           {
               id => 100,
               name => 'aaaa',
           },
           []);
$data->add('foo', 200,
           {
               id => 200,
               name => 'bbbb',
           });
eval {
    $data->load('foo', 100);
};
like( $@, qr/primary keys are not defined/ );

eval {
    $data->load('foo', 200);
};
like( $@, qr/primary keys are not defined/ );

$data->set_keys('foo', ['id']);#if keys are defined...
eval {
    $data->load('foo', 100);
    $data->load('foo', 200);
};
is( $@, '' );#load will success

eval {
    $data->load_direct('baz',
                       {
                           name => 'ddd',
                       },
                       []);
};
like( $@, qr/primary keys are not defined/ );

eval {
    $data->load_direct('baz',
                       {
                           name => 'eee',
                       });
};
like( $@, qr/primary keys are not defined/ );

$data->set_keys('baz', ['id']);#if keys are defined...
eval {
    $data->load_direct('baz',
                       {
                           name => 'ddd',
                       },
                       []);
    $data->load_direct('baz',
                       {
                           name => 'eee',
                       });
};
is( $@, '' );#load will success

$data->clear;
$data = Test::DataLoader::MySQL->new($dbh);
is_deeply($data->do_select('foo', "1=1"), { id=>0, name=>'xxx'});#remain only not loaded by Test::DataLoader::MySQL

$data->clear;

$mysqld->stop;
