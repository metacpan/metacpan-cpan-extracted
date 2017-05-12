#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib ("$FindBin::Bin/../lib" =~ m[^(/.*)])[0];

use DBI;
use Ormlette;

# ->select with null criteria
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( my_int integer, my_str varchar(10) )');
  Ormlette->init($dbh, namespace => 'SelectAll');

  $dbh->do(q(INSERT INTO test (my_int, my_str) VALUES (7, 'seven')));
  is_deeply(SelectAll::Test->select, [ { my_int => 7, my_str => 'seven' } ],
    'retrieved only object in table with ->select');

  $dbh->do(q(INSERT INTO test (my_int, my_str) VALUES (8, 'eight')));
  $dbh->do(q(INSERT INTO test (my_int, my_str) VALUES (9, 'nine')));
  is_deeply(
    [ sort { $a->{my_int} <=> $b->{my_int} } @{SelectAll::Test->select} ],
    [ { my_int => 7, my_str => 'seven' },
      { my_int => 8, my_str => 'eight' },
      { my_int => 9, my_str => 'nine' } ],
    'retrieved all objects in table with ->select');
}

# ->select with criteria
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( my_int integer, my_str varchar(10) )');
  Ormlette->init($dbh, namespace => 'SelectCrit');

  $dbh->do(q(INSERT INTO test (my_int, my_str) VALUES (9, 'nine')));
  $dbh->do(q(INSERT INTO test (my_int, my_str) VALUES (42, 'answer')));
  $dbh->do(q(INSERT INTO test (my_int, my_str) VALUES (23, 'skidoo')));
  $dbh->do(q(INSERT INTO test (my_int, my_str) VALUES (99, 'bottles')));

  is_deeply(SelectCrit::Test->select('WHERE my_int = 9'),
    [ { my_int => 9, my_str => 'nine' } ],
    '->select one record by hardcoded value');
  is_deeply(SelectCrit::Test->select('WHERE my_str = ?', 'answer'),
    [ { my_int => 42, my_str => 'answer' } ],
    '->select one record by placeholder');
  is_deeply(SelectCrit::Test->select('WHERE my_int > 40 ORDER BY my_int DESC'),
    [ { my_int => 99, my_str => 'bottles' },
      { my_int => 42, my_str => 'answer' } ],
    '->select and order multiple records');
  is_deeply(SelectCrit::Test->select('WHERE 0 = 1'), [ ],
    '->select returns an empty list when no records match');
}

# select returns properly-blessed objects
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( my_int integer, my_str varchar(10) )');
  Ormlette->init($dbh, namespace => 'SelectBless');

  $dbh->do(q(INSERT INTO test (my_int, my_str) VALUES (12, 'twelve')));
  isa_ok(SelectBless::Test->select->[0], 'SelectBless::Test');
}

# select from join with shared field names
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE foo ( id integer primary key)');
  $dbh->do('CREATE TABLE bar ( id integer primary key, foo_id integer )');
  Ormlette->init($dbh, namespace => 'DupJoin');

  my $foo = DupJoin::Foo->create;
  my $bar = DupJoin::Bar->create(foo_id => $foo->id);
  is_deeply(DupJoin::Foo->select('JOIN bar ON foo.id = bar.foo_id'), [ $foo ],
    'do ->select on joined tables with shared field name');
}

# create ->load method for both keyed and unkeyed tables
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE keyed ( id integer primary key )');
  $dbh->do('CREATE TABLE no_key ( id integer )');
  Ormlette->init($dbh, namespace => 'KeyCheck');
  is(ref KeyCheck::Keyed->can('load'), 'CODE',
    'create ->load if primary key is present');
  is(ref KeyCheck::NoKey->can('load'), 'CODE',
    'also create ->load without primary key');
}

# retrieve records by key with ->load
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE keyed ( id integer primary key, my_txt char(10) )');
  $dbh->do('CREATE TABLE multi_key
    ( id1 integer, id2 integer, non_key text, PRIMARY KEY (id1, id2) )');
  Ormlette->init($dbh, namespace => 'KeyLoad');

  $dbh->do(q(INSERT INTO keyed (id, my_txt) VALUES ( 18, 'eighteen' )));
  $dbh->do(q(INSERT INTO keyed (id, my_txt) VALUES ( 19, 'nineteen' )));
  $dbh->do(q(INSERT INTO multi_key (id1, id2, non_key) VALUES ( 1, 2, 'tre')));
  $dbh->do(q(INSERT INTO multi_key (id1, id2, non_key) VALUES ( 4, 5, 'six')));

  my $obj = KeyLoad::Keyed->load(18);
  isa_ok($obj, 'KeyLoad::Keyed');
  is_deeply($obj, { id => 18, my_txt => 'eighteen' },
    '->load with single-field key');
  is(KeyLoad::Keyed->load(4), undef,
    '->load with single-field key returns nothing on missing key');

  undef $obj;
  $obj = KeyLoad::MultiKey->load(id1 => 4, id2 => 5);
  isa_ok($obj, 'KeyLoad::MultiKey');
  is_deeply($obj, { id1 => 4, id2 => 5, non_key => 'six' },
    '->load with multi-field key');
  is(KeyLoad::MultiKey->load(2, 'tre'), undef,
    '->load with multi-field key returns nothing on missing key');
}

# ->load by unique non-key values
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE keyed ( id integer primary key, my_txt char(10) )');
  $dbh->do('CREATE TABLE no_key ( foo text, bar text )');
  Ormlette->init($dbh, namespace => 'NonKeyLoad');

  $dbh->do(q(INSERT INTO keyed (id, my_txt) VALUES ( 1, 'first' )));
  $dbh->do(q(INSERT INTO keyed (id, my_txt) VALUES ( 2, 'second' )));
  $dbh->do(q(INSERT INTO no_key (foo, bar) VALUES ( 'mumble', 'frotz' )));
  $dbh->do(q(INSERT INTO no_key (foo, bar) VALUES ( 'xyzzy', 'plugh' )));

  my $obj = NonKeyLoad::Keyed->load(my_txt => 'first');
  isa_ok($obj, 'NonKeyLoad::Keyed');
  is_deeply($obj, { id => 1, my_txt => 'first' },
    '->load from keyed table by non-key field');
  is(NonKeyLoad::Keyed->load(my_txt => 'third'), undef,
    '->load from keyed table with missing non-key value returns nothing');

  undef $obj;
  $obj = NonKeyLoad::NoKey->load(foo => 'mumble');
  isa_ok($obj, 'NonKeyLoad::NoKey');
  is_deeply($obj, { foo => 'mumble', bar => 'frotz' },
    '->load from non-keyed table by single field');

  undef $obj;
  $obj = NonKeyLoad::NoKey->load(foo => 'xyzzy', bar => 'plugh');
  isa_ok($obj, 'NonKeyLoad::NoKey');
  is_deeply($obj, { foo => 'xyzzy', bar => 'plugh' },
    '->load from non-keyed table by multiple fields');

  is(NonKeyLoad::NoKey->load(foo => 'wibble'), undef,
    '->load from non-keyed table returns nothing on missing value');
}

# ->load by non-unique values
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE dupes ( foo text, bar text )');
  Ormlette->init($dbh, namespace => 'DupeLoad');

  $dbh->do(q(INSERT INTO dupes (foo, bar) VALUES ( 'foo', 'bar' )));
  $dbh->do(q(INSERT INTO dupes (foo, bar) VALUES ( 'foo', 'baz' )));

  my $obj = DupeLoad::Dupes->load(foo => 'foo');
  isa_ok($obj, 'DupeLoad::Dupes');
  is($obj->foo, 'foo',
    '->load matching multiple records gets correct value in duped field');
  like($obj->bar, qr/ba[rz]/,
    '->load matching multiple records gets a correct value in other field');
}

# die when attempting to ->load with invalid params
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE keyed ( id integer, my_txt text )');
  $dbh->do('CREATE TABLE multi_key
    ( id1 integer, id2 integer, non_key text, PRIMARY KEY (id1, id2) )');
  $dbh->do('CREATE TABLE no_key ( foo text, bar text )');
  Ormlette->init($dbh, namespace => 'BadParam');

  dies_ok { BadParam::Keyed->load(1, 2, 3) }
    '->load on single-field keyed table dies with 3 params';
  dies_ok { BadParam::MultiKey->load(1) }
    '->load on multi-field keyed table dies with 1 param';
  dies_ok { BadParam::MultiKey->load(1, 2, 3) }
    '->load on multi-field keyed table dies with 3 params';
  dies_ok { BadParam::NoKey->load(1) }
    '->load on non-keyed table dies with 1 param';
  dies_ok { BadParam::NoKey->load(1, 2, 3) }
    '->load on non-keyed table dies with 3 params';
}

done_testing;

