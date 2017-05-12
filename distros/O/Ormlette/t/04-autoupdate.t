#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib ("$FindBin::Bin/../lib" =~ m[^(/.*)])[0];

use DBI;
use Ormlette;

# set and clear dirty flag
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( my_key integer primary key )');
  Ormlette->init($dbh, namespace => 'GetDirty');

  my $obj = GetDirty::Test->new;
  ok(!exists $obj->{_dirty}, 'no dirty flag on creation');
  $obj->mark_dirty;
  ok($obj->dirty, 'dirty flag set after mark_dirty');
  $obj->mark_clean;
  ok(!$obj->dirty, 'dirty flag cleared after mark_clean');
}

# no dirty flag if no key
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( my_int integer )');
  Ormlette->init($dbh, namespace => 'Keyless');

  my $obj = Keyless::Test->new;
  ok(!$obj->can('mark_dirty'), 'no mark_dirty on keyless class');
  ok(!$obj->can('mark_clean'), 'no mark_clean on keyless class');
  ok(!$obj->can('dirty'), 'no dirty on keyless class');
  ok(!$obj->can('DESTROY'), 'no destructor on keyless class');
}

# autoupdate iff dirty set
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( my_key integer primary key, str text )');
  Ormlette->init($dbh, namespace => 'DoUpdate');

  my $obj = DoUpdate::Test->create(my_key => 1, str => 'foo');
  $obj->str('bar');
  $obj->mark_dirty;
  undef $obj;

  my $obj2 = DoUpdate::Test->load(1);
  is($obj2->str, 'bar', 'changes to dirty object autosaved');
  $obj2->str('wibble');
  undef $obj2;

  is(DoUpdate::Test->load(1)->str, 'bar', 'changed to clean object not saved');
}

# autoupdate inserts object if not already in database
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( my_key integer primary key )');
  Ormlette->init($dbh, namespace => 'DoInsert');

  my $obj = DoInsert::Test->new(my_key => 1);
  $obj->mark_dirty;
  undef $obj;

  ok(defined DoInsert::Test->load(1), 'new dirty object autoinserted');
}

done_testing;

