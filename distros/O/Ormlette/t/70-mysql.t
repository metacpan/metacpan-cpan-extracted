#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dbname, $dbhost, $dbuser, $dbpass) = @ENV{qw(
  ORMLETTE_MYSQL_DB ORMLETTE_MYSQL_HOST ORMLETTE_MYSQL_USER ORMLETTE_MYSQL_PW
)};

unless ($dbname && $dbuser) {
  plan skip_all => 'Must define ORMLETTE_MYSQL_DB and ORMLETTE_MYSQL_USER for '
    . 'MySQL tests to run.  Also define ORMLETTE_MYSQL_HOST and '
    . 'ORMLETTE_MYSQL_PW if needed.  The specified user must have full rights '
    . 'over the specified database.';
}

use FindBin;
use lib ("$FindBin::Bin/../lib" =~ m[^(/.*)])[0];

use DBI;
use Ormlette;

$dbhost ||= 'localhost';
my $dsn = "dbi:mysql:host=$dbhost;database=$dbname";

# identify tables and construct correct package names
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE test1 ( id integer )');
  $dbh->do('CREATE TABLE TEST_taBle_2 (id integer )');
  my $egg = Ormlette->init($dbh);
  is_deeply($egg->{tbl_names}, {
    test1 => 'main::Test1', TEST_taBle_2 => 'main::TestTable2',
  }, 'found all tables and built package names');

  $dbh->do('DROP TABLE test1');
  $dbh->do('DROP TABLE TEST_taBle_2');
}

# add records with ->insert
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE no_key ( id integer, my_txt text )');
  $dbh->do('CREATE TABLE keyed ( id integer primary key auto_increment,
    my_txt text )');
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

  $dbh->do('DROP TABLE no_key');
  $dbh->do('DROP TABLE keyed');
}

# ->update records in keyed table
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE keyed ( id integer primary key auto_increment,
    my_txt text )');
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

  $dbh->do('DROP TABLE keyed');
}

# construct and save with ->create
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE test ( id integer primary key auto_increment,
    my_txt text )');
  Ormlette->init($dbh, namespace => 'Create');

  isa_ok(Create::Test->create(my_txt => 'created'), 'Create::Test');
  is_deeply(Create::Test->load(1), { id => 1, my_txt => 'created' },
    'reload object built with ->create');

  $dbh->do('DROP TABLE test');
}

# delete records with ->delete
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE no_key ( id integer, my_txt text )');
  $dbh->do('CREATE TABLE keyed ( id integer primary key auto_increment, my_txt text )');
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

  $dbh->do('DROP TABLE no_key');
  $dbh->do('DROP TABLE keyed');
  $dbh->do('DROP TABLE multi_key');
}

# ->iterate over records one at a time
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
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

  $dbh->do('DROP TABLE test');
}

# read/write using accessors
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE test ( id integer, my_txt text )');
  Ormlette->init($dbh, namespace => 'RWAccessor');

  my $obj = RWAccessor::Test->new(id => 1, my_txt => 'one');
  is($obj->id, 1, 'read numeric field');
  is($obj->id(0), 0, 'change numeric field');
  is($obj->id, 0, 'read changed numeric field');
  is($obj->my_txt, 'one', 'read string field');
  is($obj->my_txt(''), '', 'change string field');
  is($obj->my_txt, '', 'read changed string field');

  $dbh->do('DROP TABLE test');
}

# generate read-only accessors if appropriate
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE test ( id integer, my_txt text )');
  Ormlette->init($dbh, namespace => 'ROAccessor', readonly => 1);

  my $obj = bless { id => 42, my_txt => 'The Answer' }, 'ROAccessor::Test';
  is($obj->id, 42, 'read r/o numeric field');
  is($obj->id(2), 42, 'refuse to change r/o numeric field');
  is($obj->id, 42, 'r/o numeric field not changed');
  is($obj->my_txt, 'The Answer', 'read r/o string field');
  is($obj->my_txt('fail'), 'The Answer', 'refuse to change r/o string field');
  is($obj->my_txt, 'The Answer', 'r/o string field not changed');

  $dbh->do('DROP TABLE test');
}

# don't replace existing accessors
{
  package PreserveAccessors::Test;
  sub foo { 'Surprise!' };

  package main;
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE test ( foo text, xyzzy text )');
  Ormlette->init($dbh, namespace => 'PreserveAccessors');

  my $obj = PreserveAccessors::Test->new(foo => 'bar', xyzzy => 'plugh');
  is($obj->foo, 'Surprise!', 'do not overwrite existing accessor');
  is($obj->xyzzy, 'plugh', 'missing accessor still created normally');

  $dbh->do('DROP TABLE test');
}

# default ->new inserts hash keys for all attribs and nothing else
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE test ( id integer, my_text text )');
  Ormlette->init($dbh, namespace => 'BuildComplete');

  my $obj = BuildComplete::Test->new(id => 3, garbage => 'ignore');
  is_deeply($obj, { id => 3, my_text => undef },
    'all known attribs present after ->new and junk params ignored');

  $dbh->do('DROP TABLE test');
}

# ->truncate
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE test ( id integer )');
  Ormlette->init($dbh, namespace => 'Truncate');

  Truncate::Test->create(id => 1);
  Truncate::Test->truncate;
  is_deeply(Truncate::Test->select, [ ],
    '->truncate as class method clears table');

  my $obj = Truncate::Test->create(id => 2);
  dies_ok { $obj->truncate } '->truncate as instance method dies';

  $dbh->do('DROP TABLE test');
}

# ->select with null criteria
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE test ( my_int integer, my_str text )');
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

  $dbh->do('DROP TABLE test');
}

# ->select with criteria
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE test ( my_int integer, my_str text )');
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

  $dbh->do('DROP TABLE test');
}

# select from join with shared field names
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE foo ( id integer primary key auto_increment)');
  $dbh->do('CREATE TABLE bar ( id integer primary key auto_increment, foo_id integer )');
  Ormlette->init($dbh, namespace => 'DupJoin');

  my $foo = DupJoin::Foo->create;
  my $bar = DupJoin::Bar->create(foo_id => $foo->id);
  is_deeply(DupJoin::Foo->select('JOIN bar ON foo.id = bar.foo_id'), [ $foo ],
    'do ->select on joined tables with shared field name');

  $dbh->do('DROP TABLE foo');
  $dbh->do('DROP TABLE bar');
}

# create ->load method for both keyed and unkeyed tables
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE keyed ( id integer primary key auto_increment)');
  $dbh->do('CREATE TABLE no_key ( id integer )');
  Ormlette->init($dbh, namespace => 'KeyCheck');
  is(ref KeyCheck::Keyed->can('load'), 'CODE',
    'create ->load if primary key is present');
  is(ref KeyCheck::NoKey->can('load'), 'CODE',
    'also create ->load without primary key');

  $dbh->do('DROP TABLE keyed');
  $dbh->do('DROP TABLE no_key');
}

# retrieve records by key with ->load
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE keyed ( id integer primary key auto_increment, my_txt text )');
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

  $dbh->do('DROP TABLE keyed');
  $dbh->do('DROP TABLE multi_key');
}

# ->load by unique non-key values
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
  $dbh->do('CREATE TABLE keyed ( id integer primary key auto_increment, my_txt text )');
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

  $dbh->do('DROP TABLE keyed');
  $dbh->do('DROP TABLE no_key');
}

# ->load by non-unique values
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
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

  $dbh->do('DROP TABLE dupes');
}

# die when attempting to ->load with invalid params
{
  my $dbh = DBI->connect($dsn, $dbuser, $dbpass);
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

  $dbh->do('DROP TABLE keyed');
  $dbh->do('DROP TABLE multi_key');
  $dbh->do('DROP TABLE no_key');
}

done_testing;

