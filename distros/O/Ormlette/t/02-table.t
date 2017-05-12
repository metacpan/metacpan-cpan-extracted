#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib ("$FindBin::Bin/../lib" =~ m[^(/.*)])[0];

use DBI;
use Ormlette;

# access dbh via table class
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE dbh_test ( id integer )');
  Ormlette->init($dbh, namespace => 'DBHTest');
  is(DBHTest::DbhTest->dbh, $dbh, 'retrieve dbh via table class');
}

# get table names from table classes
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE first_tbl ( id integer )');
  $dbh->do('CREATE TABLE second_tbl (id integer )');
  Ormlette->init($dbh, namespace => 'TblName');
  is(TblName::FirstTbl->table, 'first_tbl', 'first table name ok');
  is(TblName::SecondTbl->table, 'second_tbl', 'second table name ok');
}

# default ->new returns an object and allows values to be set
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( foo text, bar text )');
  Ormlette->init($dbh, namespace => 'BasicNew');
  isa_ok(BasicNew::Test->new, 'BasicNew::Test');
  my $obj = BasicNew::Test->new(foo => 1, bar => 'baz');
  is_deeply($obj, { foo => 1, bar => 'baz' }, 'params accepted by ->new');
}

# if ->new is already defined, don't replace it
{
  package NoOverride::Test;
  sub new { return bless { }, 'Original' };

  package main;
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( id integer )');
  Ormlette->init($dbh, namespace => 'NoOverride');
  isa_ok(NoOverride::Test->new, 'Original');
}

# no mutating methods if readonly set
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( id integer )');
  Ormlette->init($dbh, namespace => 'ROMethods', readonly => 1);
  is(ROMethods::Test->can('new'), undef, 'no ->new with readonly');
  is(ROMethods::Test->can('_ormlette_new'), undef,
    'no ->_ormlette_new with readonly');
}

# add records with ->insert
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE no_key ( id integer, my_txt char(10) )');
  $dbh->do('CREATE TABLE keyed ( id integer primary key, my_txt char(10) )');
  Ormlette->init($dbh, namespace => 'Insert');

  isa_ok(Insert::NoKey->new(id => 1, my_txt => 'foo')->insert, 'Insert::NoKey');
  isa_ok(Insert::Keyed->new(id => 2, my_txt => 'bar')->insert, 'Insert::Keyed');

  is_deeply(Insert::NoKey->new(id => 3, my_txt => 'baz')->insert,
    { id => 3, my_txt => 'baz' }, 'correct return from keyless ->insert');
  is_deeply(Insert::Keyed->new(id => 4, my_txt => 'wibble')->insert,
    { id => 4, my_txt => 'wibble' }, 'correct return from keyed ->insert');
  is_deeply(Insert::Keyed->new(my_txt => 'xyzzy')->insert,
    { id => 5, my_txt => 'xyzzy' }, 'correct return from autokeyed ->insert');

  is_deeply(Insert::NoKey->select('WHERE id = 3'),
    [ { id => 3, my_txt => 'baz' } ], '->select inserted keyless record');
  is_deeply(Insert::Keyed->load(5),
    { id => 5, my_txt => 'xyzzy' }, '->load inserted autokey record');
}

# ->update records in keyed table
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE keyed ( id integer primary key, my_txt char(10) )');
  Ormlette->init($dbh, namespace => 'Update');

  my $obj = Update::Keyed->new(id => 42, my_txt => 'fourty-two')->insert;
  $obj->{my_txt} = 'twoscore and two';
  is($obj->update, $obj, 'correct return value from ->update');

  my $reload = Update::Keyed->load(42);
  is_deeply($reload, $obj, 'updated original object retrieved');

  $reload->{my_txt} = 'The Ultimate Answer';
  $reload->update;
  undef $obj;
  $obj= Update::Keyed->load(42);
  is_deeply($obj, $reload, 'update of loaded object reloaded');

  Update::Keyed->new(id => 13, my_txt => 'insert from update')->update;
  ok(defined Update::Keyed->load(13), 'update implicitly inserts new object');
}

# construct and save with ->create
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( id integer primary key, my_txt char(10) )');
  Ormlette->init($dbh, namespace => 'Create');

  isa_ok(Create::Test->create(my_txt => 'created'), 'Create::Test');
  is_deeply(Create::Test->load(1), { id => 1, my_txt => 'created' },
    'reload object built with ->create');
}

# delete records with ->delete
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE no_key ( id integer, my_txt char(10) )');
  $dbh->do('CREATE TABLE keyed ( id integer primary key, my_txt char(10) )');
  $dbh->do('CREATE TABLE multi_key
    ( id1 integer, id2 integer, PRIMARY KEY (id1, id2) )');
  Ormlette->init($dbh, namespace => 'Delete');

  Delete::NoKey->create(id => 1, my_txt => 'foo');
  Delete::NoKey->create(id => 2, my_txt => 'bar');
  Delete::NoKey->create(id => 3, my_txt => 'baz');
  Delete::NoKey->create(id => 4, my_txt => 'wibble');

  Delete::NoKey->delete(q(WHERE my_txt LIKE 'ba%'));
  is_deeply(Delete::NoKey->select,
    [ { id => 1, my_txt => 'foo' }, { id => 4, my_txt => 'wibble' } ],
    'delete unkeyed records with ->delete');

  Delete::NoKey->delete;
  is_deeply(Delete::NoKey->select,
    [ { id => 1, my_txt => 'foo' }, { id => 4, my_txt => 'wibble' } ],
    'class ->delete with no params is a no-op on unkeyed table');

  dies_ok { Delete::NoKey->load(id => 1)->delete }
    'instance ->delete dies on unkeyed table';

  for (qw( jan feb mar apr )) {
    Delete::Keyed->create(my_txt => $_);
  }

  Delete::Keyed->delete(q(WHERE my_txt LIKE '%r'));
  is_deeply(Delete::Keyed->select,
    [ { id => 1, my_txt => 'jan' }, { id => 2, my_txt => 'feb' } ],
    'delete keyed records with class ->delete');

  Delete::Keyed->delete;
  is_deeply(Delete::Keyed->select,
    [ { id => 1, my_txt => 'jan' }, { id => 2, my_txt => 'feb' } ],
    'class ->delete with no params is a no-op on keyed table');

  Delete::Keyed->load(1)->delete;
  is_deeply(Delete::Keyed->select, [ { id => 2, my_txt => 'feb' } ],
    'delete keyed object with instance ->delete');

  for (1..4) {
    Delete::MultiKey->create(id1 => $_, id2 => 7);
  }

  Delete::MultiKey->delete(q(WHERE id1 > 2));
  is_deeply(Delete::MultiKey->select,
    [ { id1 => 1, id2 => 7 }, { id1 => 2, id2 => 7 } ],
    'delete with class ->delete from table with multi-field key');

  Delete::MultiKey->delete;
  is_deeply(Delete::MultiKey->select,
    [ { id1 => 1, id2 => 7 }, { id1 => 2, id2 => 7 } ],
    'class ->delete with no params is a no-op on multi-field keyed table');

  Delete::MultiKey->load(id1 => 1)->delete;
  is_deeply(Delete::MultiKey->select, [ { id1 => 2, id2 => 7 } ],
    'delete multi-field keyed object with instance ->delete');
}

# ->iterate over records one at a time
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( value integer )');
  Ormlette->init($dbh, namespace => 'Iterate');

  Iterate::Test->create(value => $_) for (1 .. 10);

  my $sum;
  Iterate::Test->iterate(sub { $sum += $_->{value} });
  is($sum , 55, '->iterate over all records');

  $sum = 0;
  Iterate::Test->iterate(sub { $sum += $_->{value} },
    'WHERE value BETWEEN ? AND ?', 3, 7);
  is($sum , 25, '->iterate over subset of records');
}

# read/write using accessors
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( id integer, my_txt text )');
  Ormlette->init($dbh, namespace => 'RWAccessor');

  my $obj = RWAccessor::Test->new(id => 1, my_txt => 'one');
  is($obj->id, 1, 'read numeric field');
  is($obj->id(0), 0, 'change numeric field');
  is($obj->id, 0, 'read changed numeric field');
  is($obj->my_txt, 'one', 'read string field');
  is($obj->my_txt(''), '', 'change string field');
  is($obj->my_txt, '', 'read changed string field');
}

# generate read-only accessors if appropriate
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( id integer, my_txt text )');
  Ormlette->init($dbh, namespace => 'ROAccessor', readonly => 1);

  my $obj = bless { id => 42, my_txt => 'The Answer' }, 'ROAccessor::Test';
  is($obj->id, 42, 'read r/o numeric field');
  is($obj->id(2), 42, 'refuse to change r/o numeric field');
  is($obj->id, 42, 'r/o numeric field not changed');
  is($obj->my_txt, 'The Answer', 'read r/o string field');
  is($obj->my_txt('fail'), 'The Answer', 'refuse to change r/o string field');
  is($obj->my_txt, 'The Answer', 'r/o string field not changed');
}

# don't replace existing accessors
{
  package PreserveAccessors::Test;
  sub foo { 'Surprise!' };

  package main;
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( foo text, xyzzy text )');
  Ormlette->init($dbh, namespace => 'PreserveAccessors');

  my $obj = PreserveAccessors::Test->new(foo => 'bar', xyzzy => 'plugh');
  is($obj->foo, 'Surprise!', 'do not overwrite existing accessor');
  is($obj->xyzzy, 'plugh', 'missing accessor still created normally');
}

# default ->new inserts hash keys for all attribs and nothing else
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( id integer, my_text text )');
  Ormlette->init($dbh, namespace => 'BuildComplete');

  my $obj = BuildComplete::Test->new(id => 3, garbage => 'ignore');
  is_deeply($obj, { id => 3, my_text => undef },
    'all known attribs present after ->new and junk params ignored');
}

# ->truncate
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( id integer )');
  Ormlette->init($dbh, namespace => 'Truncate');

  Truncate::Test->create(id => 1);
  Truncate::Test->truncate;
  is_deeply(Truncate::Test->select, [ ],
    '->truncate as class method clears table');

  my $obj = Truncate::Test->create(id => 2);
  dies_ok { $obj->truncate } '->truncate as instance method dies';
}

done_testing;
