#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib ("$FindBin::Bin/../lib" =~ m[^(/.*)])[0];

use DBI;
use Ormlette;

# die on attempt to init with invalid dbh
{
  dies_ok { Ormlette->init } 'init dies with no params';
  dies_ok { Ormlette->init(42) } 'init dies with invalid dbh param';
}

# initialize from connected dbh
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  my $egg = Ormlette->init($dbh);
  isa_ok($egg, 'Ormlette');
  is($egg->{dbh}, $dbh, 'dbh stored in ormlette');
  is($egg->dbh, $dbh, 'dbh accessible via ->dbh');
}

# identify tables and construct correct package names
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test1 ( id integer )');
  $dbh->do('CREATE TABLE TEST_taBle_2 (id integer )');
  my $egg = Ormlette->init($dbh);
  is_deeply($egg->{tbl_names}, {
    test1 => 'main::Test1', TEST_taBle_2 => 'main::TestTable2',
  }, 'found all tables and built package names');
}

# use double-underscore for multi-level class structure
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE multi__level ( id integer )');
  my $egg = Ormlette->init($dbh);
  is_deeply($egg->{tbl_names}, {
      multi__level => 'main::Multi::Level'
  }, 'double underscore in table name gives multi-level package name');
}

# correctly identify root namespace
{
  package Root;
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test ( id integer )');
  my $egg = Ormlette->init($dbh);

  package main;
  is_deeply($egg->{tbl_names}, { test => 'Root::Test' },
    'packages placed in correct namespace by default');
  is(Root->dbh, $dbh, 'default root namespace knows dbh');
  is(Root::Test->dbh, $dbh, 'default table package knows dbh');
}

# use 'namespace' param to override root namespace
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE test_table ( id integer )');
  my $egg = Ormlette->init($dbh, namespace => 'Egg');
  is_deeply($egg->{tbl_names}, {
    test_table => 'Egg::TestTable',
  }, 'override root ormlette namespace with namespace param');
}

# prevent modification of root namespace with ignore_root param
{
  package IgnoreRoot;
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE ignore_root_test ( id integer )');
  my $egg = Ormlette->init($dbh, ignore_root => 1);

  package main;
  dies_ok { IgnoreRoot->dbh }
    'root namespace has no dbh method if ignore_root is set';
}

# restrict list of packages touched using tables param
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE tbl_test ( id integer )');
  $dbh->do('CREATE TABLE ignore_me (id integer )');
  my $egg = Ormlette->init($dbh, tables => [ 'tbl_test', 'bogus' ]);
  is_deeply($egg->{tbl_names}, {
    tbl_test => 'main::TblTest',
  }, 'tables param causes non-listed tables to be ignored');

  $egg = Ormlette->init($dbh, tables => [ ]);
  is_deeply($egg->{tbl_names}, { }, 'empty tables param ignores everything');
}

# restrict list of packages touched using ignore_tables param
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE ormlify_me ( id integer )');
  $dbh->do('CREATE TABLE ignore_me (id integer )');
  my $egg = Ormlette->init($dbh, ignore_tables => ['ignore_me']);

  is_deeply(
    $egg->{tbl_names},
    {ormlify_me => 'main::OrmlifyMe',},
    'tables_ignore param causes listed tables to be ignored'
  );
}

# use 'isa' param to assign a parent to generated classes
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE isa_test (id integer)');

  package Parent;
  # Nothing here; just need the namespace to exist

  package main;

  my $egg = Ormlette->init($dbh, isa => 'Parent');
  is_deeply([@main::IsaTest::ISA], ['Parent'], 'set @ISA with isa param');
  my $isa_test = IsaTest->new;
  isa_ok($isa_test, 'main::IsaTest', 'parented class is itself');
  isa_ok($isa_test, 'Parent',  'parented class is descended from parent');
}

# don't overwrite @ISA if it's already set
{
  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '');
  $dbh->do('CREATE TABLE save_parent (id integer)');

  package SaveParent;
  our @ISA = qw( Parent );

  package NotParent;
  # Again, just need the name, no functionality

  package main;

  my $egg = Ormlette->init($dbh, isa => 'NotParent');
  my $preserved = SaveParent->new;
  isa_ok($preserved, 'Parent', 'pre-existing parent class preserved');
}

done_testing;
