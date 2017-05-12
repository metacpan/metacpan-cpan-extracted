#!/usr/bin/perl -w

use strict;

use Test::More tests => 321;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
}

our($PG_HAS_CHKPASS, $HAVE_PG, $HAVE_MYSQL, $HAVE_INFORMIX, $HAVE_SQLITE);

#
# PostgreSQL
#

SKIP: foreach my $db_type (qw(pg pg_with_schema))
{
  skip("PostgreSQL tests", 132)  unless($HAVE_PG);

  Rose::DB->default_type($db_type);

  TEST_HACK:
  {
    no warnings;
    *MyPgObject::init_db = sub { Rose::DB->new($db_type) };
  }

  my $o = MyPgObject->new(NAME => 'John', 
                          K1   => 1,
                          K2   => undef,
                          K3   => 3);

  #ok($o->can('id'), "no primary key alias - $db_type");

  ok(ref $o && $o->isa('MyPgObject'), "new() 1 - $db_type");

  $o->FLAG2('TRUE');
  $o->DATE_CREATED('now');
  $o->LAST_MODIFIED($o->DATE_CREATED);
  $o->SAVE_COL(7);

  ok($o->save, "save() 1 - $db_type");

  is($o->ID, 1, "auto-generated primary key - $db_type");

  ok($o->load, "load() 1 - $db_type");

  $o->NAME('C' x 50);
  is($o->NAME, 'C' x 32, "varchar truncation - $db_type");

  $o->NAME('John');

  $o->CODE('A');
  is($o->CODE, 'A     ', "character padding - $db_type");

  $o->CODE('C' x 50);
  is($o->CODE, 'C' x 6, "character truncation - $db_type");

  my $os = 
    Rose::DB::Object::Manager->get_objects(
      #debug => 1,
      object_class => ref($o),
      query =>
      [
        id => $o->ID,
      ]);

  is($os->[0]->ID, $o->ID, "Manager query with pk alias 1 - $db_type");

  $os = 
    Rose::DB::Object::Manager->get_objects(
      #debug => 1,
      object_class => ref($o),
      query =>
      [
        ID => $o->ID,
      ]);

  is($os->[0]->ID, $o->ID, "Manager query with pk alias 2 - $db_type");

  my $ouk = MyPgObject->new(K1 => 1,
                            K2 => undef,
                            K3 => 3);

  ok($ouk->load, "load() uk 1 - $db_type");
  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->ID, 1, "load() uk 2 - $db_type");
  is($ouk->NAME, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

  my $o2 = MyPgObject->new(ID => $o->ID);

  ok(ref $o2 && $o2->isa('MyPgObject'), "new() 2 - $db_type");

  is($o2->BITS->to_Bin, '00101', "BITS() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->NAME, $o->NAME, "load() verify 1 - $db_type");
  is($o2->DATE_CREATED, $o->DATE_CREATED, "load() verify 2 - $db_type");
  is($o2->LAST_MODIFIED, $o->LAST_MODIFIED, "load() verify 3 - $db_type");
  is($o2->STATUS, 'active', "load() verify 4 (default value) - $db_type");
  is($o2->FLAG, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->FLAG2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->SAVE_COL, 7, "load() verify 7 (aliased column) - $db_type");
  is($o2->START->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->BITS->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->START eq $clone->START, "clone() 1 - $db_type");
  $clone->START->set(year => '1960');
  ok($o2->START ne $clone->START, "clone() 2 - $db_type");

  $o2->NAME('John 2');
  $o2->START('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->LAST_MODIFIED('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->DATE_CREATED, $o->DATE_CREATED, "save() verify 1 - $db_type");
  ok($o2->LAST_MODIFIED ne $o->LAST_MODIFIED, "save() verify 2 - $db_type");
  is($o2->START->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyPgObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyPgObject->new(ID => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  ok($o->load, "load() 4 - $db_type");

  SKIP:
  {
    if($PG_HAS_CHKPASS)
    {
      $o->{'PASSWORD_ENCRYPTED'} = ':8R1Kf2nOS0bRE';

      ok($o->PASSWORD_IS('xyzzy'), "chkpass() 1 - $db_type");
      is($o->PASSWORD, 'xyzzy', "chkpass() 2 - $db_type");

      $o->PASSWORD('foobar');

      ok($o->PASSWORD_IS('foobar'), "chkpass() 3 - $db_type");
      is($o->PASSWORD, 'foobar', "chkpass() 4 - $db_type");

      ok($o->save, "save() 3 - $db_type");
    }
    else
    {
      skip("chkpass tests", 5);
    }
  }

  my $o5 = MyPgObject->new(ID => $o->ID);

  ok($o5->load, "load() 5 - $db_type");

  SKIP:
  {
    if($PG_HAS_CHKPASS)
    {
      ok($o5->PASSWORD_IS('foobar'), "chkpass() 5 - $db_type");
      is($o5->PASSWORD, 'foobar', "chkpass() 6 - $db_type"); 
    }
    else
    {
      skip("chkpass tests", 2);
    }
  }

  $o5->NUMS([ 4, 5, 6 ]);
  ok($o5->save, "save() 4 - $db_type");
  ok($o->load, "load() 6 - $db_type");

  is($o5->NUMS->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o5->NUMS->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o5->NUMS->[2], 6, "load() verify 12 (array value) - $db_type");

  my @a = $o5->NUMS;

  is($a[0], 4, "load() verify 13 (array value) - $db_type");
  is($a[1], 5, "load() verify 14 (array value) - $db_type");
  is($a[2], 6, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MyPgObject->new(NAME => 'John', ID => 9);
  $o->SAVE_COL(22);
  ok($o->save, "save() 4 - $db_type");
  $o->SAVE_COL(50);
  ok($o->save, "save() 5 - $db_type");

  $ouk = MyPgObject->new(SAVE_COL => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # This is okay now
  #eval { $o->meta->alias_column(ID => 'foo') };
  #ok($@, "alias_column() primary key - $db_type");

  $o = MyPgObject->new(ID => 777);

  $o->meta->error_mode('fatal');

  $o->dbh->{'PrintError'} = 0;

  eval { $o->load };
  ok($@ && $o->not_found, "load() not found fatal - $db_type");

  $o->ID('abc');

  eval { $o->load };
  ok($@ && !$o->not_found, "load() fatal - $db_type");

  eval { $o->save };
  ok($@, "save() fatal - $db_type");

  $o->meta->error_mode('return');
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 64)  unless($HAVE_MYSQL);

  Rose::DB->default_type($db_type);

  my $o = MyMySQLObject->new(NAME => 'John',
                             K1   => 1,
                             K2   => undef,
                             K3   => 3);

  ok(ref $o && $o->isa('MyMySQLObject'), "new() 1 - $db_type");

  #ok($o->can('id'), "no primary key alias - $db_type");

  $o->FLAG2('true');
  $o->DATE_CREATED('now');
  $o->LAST_MODIFIED($o->DATE_CREATED);
  $o->SAVE_COL(22);
  $o->READ(55);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  $o->NAME('C' x 50);
  is($o->NAME, 'C' x 32, "varchar truncation - $db_type");

  $o->NAME('John');

  $o->CODE('A');
  is($o->CODE, 'A     ', "character padding - $db_type");

  $o->CODE('C' x 50);
  is($o->CODE, 'C' x 6, "character truncation - $db_type");

  my $os = 
    Rose::DB::Object::Manager->get_objects(
      #debug => 1,
      object_class => ref($o),
      query =>
      [
        id => $o->ID,
      ]);

  is($os->[0]->ID, $o->ID, "Manager query with pk alias 1 - $db_type");

  $os = 
    Rose::DB::Object::Manager->get_objects(
      #debug => 1,
      object_class => ref($o),
      query =>
      [
        ID => $o->ID,
      ]);

  is($os->[0]->ID, $o->ID, "Manager query with pk alias 2 - $db_type");

  my $ouk = MyMySQLObject->new(K1 => 1,
                               K2 => undef,
                               K3 => 3);

  ok($ouk->load, "load() uk 1 - $db_type");
  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->ID, 1, "load() uk 2 - $db_type");
  is($ouk->NAME, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

  my $o2 = MyMySQLObject->new(ID => $o->ID);

  ok(ref $o2 && $o2->isa('MyMySQLObject'), "new() 2 - $db_type");

  is($o2->BITS->to_Bin, '00101', "BITS() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->NAME, $o->NAME, "load() verify 1 - $db_type");
  is($o2->DATE_CREATED, $o->DATE_CREATED, "load() verify 2 - $db_type");
  is($o2->LAST_MODIFIED, $o->LAST_MODIFIED, "load() verify 3 - $db_type");
  is($o2->STATUS, 'active', "load() verify 4 (default value) - $db_type");
  is($o2->FLAG, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->FLAG2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->SAVE_COL, 22, "load() verify 7 (aliased column) - $db_type");
  is($o2->START->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->BITS->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->START eq $clone->START, "clone() 1 - $db_type");
  $clone->START->set(year => '1960');
  ok($o2->START ne $clone->START, "clone() 2 - $db_type");

  $o2->NAME('John 2');
  $o2->START('5/24/2001');
  $o2->READ(99);

  sleep(1); # keep the last modified dates from being the same

  $o2->LAST_MODIFIED('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->DATE_CREATED, $o->DATE_CREATED, "save() verify 1 - $db_type");
  ok($o2->LAST_MODIFIED ne $o->LAST_MODIFIED, "save() verify 2 - $db_type");
  is($o2->START->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyMySQLObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyMySQLObject->new(ID => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  $o->NUMS([ 4, 5, 6 ]);
  ok($o->save, "save() 3 - $db_type");
  ok($o->load, "load() 4 - $db_type");

  is($o->NUMS->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o->NUMS->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o->NUMS->[2], 6, "load() verify 12 (array value) - $db_type");

  my @a = $o->NUMS;

  is($a[0], 4, "load() verify 13 (array value) - $db_type");
  is($a[1], 5, "load() verify 14 (array value) - $db_type");
  is($a[2], 6, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MyMySQLObject->new(NAME => 'John', ID => 9);
  $o->SAVE_COL(22);
  ok($o->save, "save() 4 - $db_type");
  $o->SAVE_COL(50);
  ok($o->save, "save() 5 - $db_type");

  $ouk = MyMySQLObject->new(SAVE_COL => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # This is okay now
  #eval { $o->meta->alias_column(ID => 'foo') };
  #ok($@, "alias_column() primary key - $db_type");

  $o = MyMySQLObject->new(ID => 777);

  $o->meta->error_mode('fatal');

  $o->dbh->{'PrintError'} = 0;

  eval { $o->load };
  ok($@ && $o->not_found, "load() not found fatal - $db_type");

  my $old_table = $o->meta->table;
  $o->meta->table('nonesuch');

  eval { $o->load };
  ok($@ && !$o->not_found, "load() fatal - $db_type");

  eval { $o->save };
  ok($@, "save() fatal - $db_type");

  $o->meta->table($old_table);  
  $o->meta->error_mode('return');

  $o = MyMPKMySQLObject->new(NAME => 'John');

  ok($o->save, "save() 1 multi-value primary key with generated values - $db_type");

  is($o->K1, 1, "save() verify 1 multi-value primary key with generated values - $db_type");
  is($o->K2, 2, "save() verify 2 multi-value primary key with generated values - $db_type");

  $o = MyMPKMySQLObject->new(NAME => 'Alex');

  ok($o->save, "save() 2 multi-value primary key with generated values - $db_type");

  is($o->K1, 3, "save() verify 3 multi-value primary key with generated values - $db_type");
  is($o->K2, 4, "save() verify 4 multi-value primary key with generated values - $db_type");
}

#
# Informix
#

SKIP: foreach my $db_type ('informix')
{
  skip("Informix tests", 65)  unless($HAVE_INFORMIX);

  Rose::DB->default_type($db_type);

  my $o = MyInformixObject->new(NAME => 'John', 
                                ID   => 1,
                                K1   => 1,
                                K2   => undef,
                                K3   => 3);

  ok(ref $o && $o->isa('MyInformixObject'), "new() 1 - $db_type");

  #ok($o->can('id'), "no primary key alias - $db_type");

  $o->meta->allow_inline_column_values(1);

  $o->FLAG2('true');
  $o->DATE_CREATED('current year to fraction(5)');
  $o->LAST_MODIFIED($o->DATE_CREATED);
  $o->SAVE_COL(22);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  $o->NAME('C' x 50);
  is($o->NAME, 'C' x 32, "varchar truncation - $db_type");

  $o->NAME('John');

  $o->CODE('A');
  is($o->CODE, 'A     ', "character padding - $db_type");

  $o->CODE('C' x 50);
  is($o->CODE, 'C' x 6, "character truncation - $db_type");

  my $os = 
    Rose::DB::Object::Manager->get_objects(
      #debug => 1,
      object_class => ref($o),
      query =>
      [
        id => $o->ID,
      ]);

  is($os->[0]->ID, $o->ID, "Manager query with pk alias 1 - $db_type");

  $os = 
    Rose::DB::Object::Manager->get_objects(
      #debug => 1,
      object_class => ref($o),
      query =>
      [
        ID => $o->ID,
      ]);

  is($os->[0]->ID, $o->ID, "Manager query with pk alias 2 - $db_type");

  my $ouk = MyInformixObject->new(K1 => 1,
                                  K2 => undef,
                                  K3 => 3);

  ok($ouk->load, "load() uk 1 - $db_type");
  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->ID, 1, "load() uk 2 - $db_type");
  is($ouk->NAME, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

  my $o2 = MyInformixObject->new(ID => $o->ID);

  ok(ref $o2 && $o2->isa('MyInformixObject'), "new() 2 - $db_type");

  is($o2->BITS->to_Bin, '00101', "BITS() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->NAME, $o->NAME, "load() verify 1 - $db_type");
  is($o2->DATE_CREATED, $o->DATE_CREATED, "load() verify 2 - $db_type");
  is($o2->LAST_MODIFIED, $o->LAST_MODIFIED, "load() verify 3 - $db_type");
  is($o2->STATUS, 'active', "load() verify 4 (default value) - $db_type");
  is($o2->FLAG, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->FLAG2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->SAVE_COL, 22, "load() verify 7 (aliased column) - $db_type");
  is($o2->START->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->BITS->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->START eq $clone->START, "clone() 1 - $db_type");
  $clone->START->set(year => '1960');
  ok($o2->START ne $clone->START, "clone() 2 - $db_type");

  $o2->NAME('John 2');
  $o2->START('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->LAST_MODIFIED('current year to second');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->DATE_CREATED, $o->DATE_CREATED, "save() verify 1 - $db_type");
  ok($o2->LAST_MODIFIED ne $o->LAST_MODIFIED, "save() verify 2 - $db_type");
  is($o2->START->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyInformixObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyInformixObject->new(ID => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  $o->NUMS([ 4, 5, 6 ]);
  $o->NAMES([ qw(a b 3.1) ]);

  ok($o->save, "save() 3 - $db_type");
  ok($o->load, "load() 4 - $db_type");

  is($o->NUMS->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o->NUMS->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o->NUMS->[2], 6, "load() verify 12 (array value) - $db_type");

  $o->NUMS(7, 8, 9);

  my @a = $o->NUMS;

  is($a[0], 7, "load() verify 13 (array value) - $db_type");
  is($a[1], 8, "load() verify 14 (array value) - $db_type");
  is($a[2], 9, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  is($o->NAMES->[0], 'a', "load() verify 10 (set value) - $db_type");
  is($o->NAMES->[1], 'b', "load() verify 11 (set value) - $db_type");
  is($o->NAMES->[2], '3.1', "load() verify 12 (set value) - $db_type");

  $o->NAMES('c', 'd', '4.2');

  @a = $o->NAMES;

  is($a[0], 'c', "load() verify 13 (set value) - $db_type");
  is($a[1], 'd', "load() verify 14 (set value) - $db_type");
  is($a[2], '4.2', "load() verify 15 (set value) - $db_type");
  is(@a, 3, "load() verify 16 (set value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MyInformixObject->new(NAME => 'John', ID => 9);

  $o->FLAG2('true');
  $o->DATE_CREATED('current year to fraction(5)');
  $o->LAST_MODIFIED($o->DATE_CREATED);
  $o->SAVE_COL(22);

  ok($o->save, "save() 4 - $db_type");
  $o->SAVE_COL(50);

  ok($o->save, "save() 5 - $db_type");

  $ouk = MyInformixObject->new(SAVE_COL => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # This is okay now
  #eval { $o->meta->alias_column(ID => 'foo') };
  #ok($@, "alias_column() primary key - $db_type");

  $o = MyInformixObject->new(ID => 777);

  $o->meta->error_mode('fatal');

  $o->dbh->{'PrintError'} = 0;

  eval { $o->load };
  ok($@ && $o->not_found, "load() not found fatal - $db_type");

  $o->ID('abc');

  eval { $o->load };
  ok($@ && !$o->not_found, "load() fatal - $db_type");

  eval { $o->save };
  ok($@, "save() fatal - $db_type");

  $o->meta->error_mode('return');
}

#
# SQLite
#

SKIP: foreach my $db_type ('sqlite')
{
  skip("SQLite tests", 59)  unless($HAVE_SQLITE);

  Rose::DB->default_type($db_type);

  my $o = MySQLiteObject->new(NAME   => 'John', 
                              EYEDEE => 1,
                              K1     => 1,
                              K2     => undef,
                              K3     => 3);

  ok(ref $o && $o->isa('MySQLiteObject'), "new() 1 - $db_type");

  #ok($o->can('id'), "no primary key alias - $db_type");

  $o->meta->allow_inline_column_values(1);

  $o->FLAG2('true');
  $o->DATE_CREATED('now');
  $o->LAST_MODIFIED($o->DATE_CREATED);
  $o->SAVE_COL(22);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  $o->NAME('C' x 50);
  is($o->NAME, 'C' x 32, "varchar truncation - $db_type");

  $o->NAME('John');

  $o->CODE('A');
  is($o->CODE, 'A     ', "character padding - $db_type");

  $o->CODE('C' x 50);
  is($o->CODE, 'C' x 6, "character truncation - $db_type");

  my $os = 
    Rose::DB::Object::Manager->get_objects(
      #debug => 1,
      object_class => ref($o),
      query =>
      [
        id => $o->EYEDEE,
      ]);

  is($os->[0]->EYEDEE, $o->EYEDEE, "Manager query with pk alias 1 - $db_type");

  $os = 
    Rose::DB::Object::Manager->get_objects(
      #debug => 1,
      object_class => ref($o),
      query =>
      [
        EYEDEE => $o->EYEDEE,
      ]);

  is($os->[0]->EYEDEE, $o->EYEDEE, "Manager query with pk alias 2 - $db_type");

  my $ouk = MySQLiteObject->new(K1 => 1,
                                  K2 => undef,
                                  K3 => 3);

  ok($ouk->load, "load() uk 1 - $db_type");
  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->EYEDEE, 1, "load() uk 2 - $db_type");
  is($ouk->NAME, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

  my $o2 = MySQLiteObject->new(EYEDEE => $o->EYEDEE);

  ok(ref $o2 && $o2->isa('MySQLiteObject'), "new() 2 - $db_type");

  is($o2->BITS->to_Bin, '00101', "BITS() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->NAME, $o->NAME, "load() verify 1 - $db_type");
  is($o2->DATE_CREATED, $o->DATE_CREATED, "load() verify 2 - $db_type");
  is($o2->LAST_MODIFIED, $o->LAST_MODIFIED, "load() verify 3 - $db_type");
  is($o2->STATUS, 'active', "load() verify 4 (default value) - $db_type");
  is($o2->FLAG, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->FLAG2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->SAVE_COL, 22, "load() verify 7 (aliased column) - $db_type");
  is($o2->START->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->BITS->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->START eq $clone->START, "clone() 1 - $db_type");
  $clone->START->set(year => '1960');
  ok($o2->START ne $clone->START, "clone() 2 - $db_type");

  $o2->NAME('John 2');
  $o2->START('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->LAST_MODIFIED('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->DATE_CREATED, $o->DATE_CREATED, "save() verify 1 - $db_type");
  ok($o2->LAST_MODIFIED ne $o->LAST_MODIFIED, "save() verify 2 - $db_type");
  is($o2->START->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MySQLiteObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MySQLiteObject->new(EYEDEE => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  $o->NUMS([ 4, 5, 6 ]);

  ok($o->save, "save() 3 - $db_type");
  ok($o->load, "load() 4 - $db_type");

  is($o->NUMS->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o->NUMS->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o->NUMS->[2], 6, "load() verify 12 (array value) - $db_type");

  $o->NUMS(7, 8, 9);

  my @a = $o->NUMS;

  is($a[0], 7, "load() verify 13 (array value) - $db_type");
  is($a[1], 8, "load() verify 14 (array value) - $db_type");
  is($a[2], 9, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MySQLiteObject->new(NAME => 'John', EYEDEE => 9);

  $o->FLAG2('true');
  $o->DATE_CREATED('now');
  $o->LAST_MODIFIED($o->DATE_CREATED);
  $o->SAVE_COL(22);

  ok($o->save, "save() 4 - $db_type");
  $o->SAVE_COL(50);

  ok($o->save, "save() 5 - $db_type");

  $ouk = MySQLiteObject->new(SAVE_COL => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  $o = MySQLiteObject->new(EYEDEE => 777);

  $o->meta->error_mode('fatal');

  $o->dbh->{'PrintError'} = 0;

  eval { $o->load };
  ok($@ && $o->not_found, "load() not found fatal - $db_type");

  $o->EYEDEE('abc');

  eval { $o->load }; # SQLite doesn't care about data types
  ok($@ && $o->not_found, "load() fatal - $db_type");

  eval { $o->save };
  ok($@, "save() fatal - $db_type");

  $o->meta->error_mode('return');

  # This is okay now
  eval { $o->meta->alias_column(id => 'foo') };
  ok(!$@, "alias_column() primary key - $db_type");
}

BEGIN
{
  #
  # PostgreSQL
  #

  my $dbh;

  eval 
  {
    $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_PG = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
      $dbh->do('DROP TABLE rose_db_object_private.rose_db_object_test');
      $dbh->do('DROP TABLE rose_db_object_chkpass_test');
      $dbh->do('CREATE SCHEMA rose_db_object_private');
    }

    our $PG_HAS_CHKPASS = pg_has_chkpass();

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             SERIAL NOT NULL PRIMARY KEY,
  k1             INT,
  k2             INT,
  k3             INT,
  @{[ $PG_HAS_CHKPASS ? 'passwd CHKPASS,' : '' ]}
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bitz           BIT(5) NOT NULL DEFAULT B'00101',
  start          DATE,
  save           INT,
  nums           INT[],
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_private.rose_db_object_test
(
  id             SERIAL NOT NULL PRIMARY KEY,
  k1             INT,
  k2             INT,
  k3             INT,
  @{[ $PG_HAS_CHKPASS ? 'passwd CHKPASS,' : '' ]}
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bitz           BIT(5) NOT NULL DEFAULT B'00101',
  start          DATE,
  save           INT,
  nums           INT[],
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyPgObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('pg') }

    MyPgObject->meta->table('rose_db_object_test');

    my %chkpass_args =
    (
      type  => 'chkpass', 
      alias => 'password',
      encrypted_suffix => '_ENCRYPTED',
      cmp_suffix       => '_IS',
    );

    MyPgObject->meta->columns
    (
      name     => { type => 'varchar', length => 32, overflow => 'truncate' },
      code     => { type => 'char', length => 6, overflow => 'truncate' },
      id       => { primary_key => 1, not_null => 1 },
      k1       => { type => 'int' },
      k2       => { type => 'int' },
      k3       => { type => 'int' },
      ($PG_HAS_CHKPASS ? (passwd => \%chkpass_args) : ()),
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active' },
      start    => { type => 'date', default => '12/24/1980' },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      bitz     => { type => 'bitfield', bits => 5, default => 101, alias => 'bits' },
      #last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    MyPgObject->meta->add_unique_key('save');

    MyPgObject->meta->add_unique_key([ qw(k1 k2 k3) ]);

    MyPgObject->meta->add_columns(
      Rose::DB::Object::Metadata::Column::Timestamp->new(
        name => 'last_modified'));

    MyPgObject->meta->column_name_to_method_name_mapper(sub 
    {
      my($meta,  $column_name, $method_type, $method_name) = @_;
      return uc $method_name;
    });

    MyPgObject->meta->alias_column(save => 'save_col');

    MyPgObject->meta->initialize;

    Test::More::is(MyPgObject->meta->column('id')->is_primary_key_member, 1, 'is_primary_key_member - pg');
    Test::More::is(MyPgObject->meta->column('id')->primary_key_position, 1, 'primary_key_position 1 - pg');
    Test::More::ok(!defined MyPgObject->meta->column('k1')->primary_key_position, 'primary_key_position 2 - pg');
    MyPgObject->meta->column('k1')->primary_key_position(7);
    Test::More::ok(!defined MyPgObject->meta->column('k1')->primary_key_position, 'primary_key_position 3 - pg');
  }

  #
  # MySQL
  #

  my $db_version;

  eval
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh() or die Rose::DB->error;
    $db_version = $db->database_version;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_MYSQL = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
      $dbh->do('DROP TABLE rose_db_object_test2');
    }

    # MySQL 5.0.3 or later has a completely stupid "native" BIT type
    my $bit_col = 
      ($db_version >= 5_000_003) ?
        q(bitz  BIT(5) NOT NULL DEFAULT B'00101') :
        q(bitz  BIT(5) NOT NULL DEFAULT '00101');

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  k1             INT,
  k2             INT,
  k3             INT,
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           TINYINT(1) NOT NULL,
  flag2          TINYINT(1),
  status         VARCHAR(32) DEFAULT 'active',
  $bit_col,
  nums           VARCHAR(255),
  start          DATE,
  save           INT,
  `read`         INT,
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test2
(
  k1             INT NOT NULL,
  k2             INT NOT NULL,
  name           VARCHAR(32),

  UNIQUE(k1, k2)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyMySQLObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLObject->meta->allow_inline_column_values(1);

    MyMySQLObject->meta->table('rose_db_object_test');

    MyMySQLObject->meta->columns
    (
      name     => { type => 'varchar', length => 32, overflow => 'truncate' },
      code     => { type => 'char', length => 6, overflow => 'truncate' },
      id       => { primary_key => 1, not_null => 1 },
      k1       => { type => 'int' },
      k2       => { type => 'int' },
      k3       => { type => 'int' },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active' },
      start    => { type => 'date', default => '12/24/1980' },
      save     => { type => 'scalar' },
      read     => { type => 'int' },
      nums     => { type => 'array' },
      bitz     => { type => 'bitfield', bits => 5, default => 101, alias => 'bits' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    MyMySQLObject->meta->column_name_to_method_name_mapper(sub 
    {
      my($meta,  $column_name, $method_type, $method_name) = @_;
      return uc $method_name;
    });

    MyMySQLObject->meta->alias_column(save => 'save_col');

    MyMySQLObject->meta->add_unique_key('save');
    MyMySQLObject->meta->add_unique_key([ qw(k1 k2 k3) ]);

    MyMySQLObject->meta->initialize(preserve_existing => 1);

    Test::More::is(MyMySQLObject->meta->column('id')->is_primary_key_member, 1, 'is_primary_key_member - mysql');
    Test::More::is(MyMySQLObject->meta->column('id')->primary_key_position, 1, 'primary_key_position 1 - mysql');
    Test::More::ok(!defined MyMySQLObject->meta->column('k1')->primary_key_position, 'primary_key_position 2 - mysql');
    MyMySQLObject->meta->column('k1')->primary_key_position(7);
    Test::More::ok(!defined MyMySQLObject->meta->column('k1')->primary_key_position, 'primary_key_position 3 - mysql');

    package MyMPKMySQLObject;

    use Rose::DB::Object;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMPKMySQLObject->meta->table('rose_db_object_test2');

    MyMPKMySQLObject->meta->columns
    (
      k1          => { type => 'int', not_null => 1 },
      k2          => { type => 'int', not_null => 1 },
      name        => { type => 'varchar', length => 32 },
    );

    MyMPKMySQLObject->meta->primary_key_columns('k1', 'k2');

    sub MyMPKMySQLObject::K1 { shift->k1(@_) }
    sub MyMPKMySQLObject::K2 { shift->k2(@_) }

    MyMPKMySQLObject->meta->column_name_to_method_name_mapper(sub 
    {
      my($meta,  $column_name, $method_type, $method_name) = @_;
      return $method_name =~ /^k[12]$/ ? $method_name : uc $method_name;
    });

    MyMPKMySQLObject->meta->initialize;

    my $i = 1;

    MyMPKMySQLObject->meta->primary_key_generator(sub
    {
      my($meta, $db) = @_;

      my $k1 = $i++;
      my $k2 = $i++;

      return $k1, $k2;
    });
  }

  #
  # Informix
  #

  eval
  {
    $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_INFORMIX = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             SERIAL NOT NULL PRIMARY KEY,
  k1             INT,
  k2             INT,
  k3             INT,
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bitz           VARCHAR(5) DEFAULT '00101' NOT NULL,
  nums           VARCHAR(255),
  start          DATE,
  save           INT,
  names          SET(VARCHAR(64) NOT NULL),
  last_modified  DATETIME YEAR TO FRACTION(5),
  date_created   DATETIME YEAR TO FRACTION(5)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyInformixObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('informix') }

    MyInformixObject->meta->table('rose_db_object_test');

    MyInformixObject->meta->columns
    (
      name     => { type => 'varchar', length => 32, overflow => 'truncate' },
      code     => { type => 'char', length => 6, overflow => 'truncate' },
      id       => { type => 'serial', primary_key => 1, not_null => 1 },
      k1       => { type => 'int' },
      k2       => { type => 'int' },
      k3       => { type => 'int' },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active' },
      start    => { type => 'date', default => '12/24/1980' },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      bitz     => { type => 'bitfield', bits => 5, default => 101, alias => 'bits' },
      names    => { type => 'set' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'datetime year to fraction(5)' },
    );

    MyInformixObject->meta->column_name_to_method_name_mapper(sub 
    {
      my($meta,  $column_name, $method_type, $method_name) = @_;
      return uc $method_name;
    });

    MyInformixObject->meta->prepare_options({ix_CursorWithHold => 1});    

    MyInformixObject->meta->alias_column(save => 'save_col');

    MyInformixObject->meta->add_unique_key('save');
    MyInformixObject->meta->add_unique_key([ qw(k1 k2 k3) ]);

    MyInformixObject->meta->initialize;

    Test::More::is(MyInformixObject->meta->column('id')->is_primary_key_member, 1, 'is_primary_key_member - informix');
    Test::More::is(MyInformixObject->meta->column('id')->primary_key_position, 1, 'primary_key_position 1 - informix');
    Test::More::ok(!defined MyInformixObject->meta->column('k1')->primary_key_position, 'primary_key_position 2 - informix');
    MyInformixObject->meta->column('k1')->primary_key_position(7);
    Test::More::ok(!defined MyInformixObject->meta->column('k1')->primary_key_position, 'primary_key_position 3 - informix');
  }

  #
  # SQLite
  #

  eval
  {
    $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_SQLITE = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  k1             INT,
  k2             INT,
  k3             INT,
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bitz           VARCHAR(5) DEFAULT '00101' NOT NULL,
  nums           VARCHAR(255),
  start          DATE,
  save           INT,
  last_modified  TIMESTAMP,
  date_created   DATETIME
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MySQLiteObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteObject->meta->table('rose_db_object_test');

    MySQLiteObject->meta->columns
    (
      name     => { type => 'varchar', length => 32, overflow => 'truncate' },
      code     => { type => 'char', length => 6, overflow => 'truncate' },
      id       => { type => 'serial', alias => 'eyedee', primary_key => 1, not_null => 1 },
      k1       => { type => 'int' },
      k2       => { type => 'int' },
      k3       => { type => 'int' },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active' },
      start    => { type => 'date', default => '12/24/1980' },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      bitz     => { type => 'bitfield', bits => 5, default => 101, alias => 'bits' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'datetime' },
    );

    MySQLiteObject->meta->column_name_to_method_name_mapper(sub 
    {
      my($meta,  $column_name, $method_type, $method_name) = @_;
      return uc $method_name;
    });

    MySQLiteObject->meta->prepare_options({ix_CursorWithHold => 1});    

    MySQLiteObject->meta->alias_column(save => 'save_col');

    MySQLiteObject->meta->add_unique_key('save');
    MySQLiteObject->meta->add_unique_key([ qw(k1 k2 k3) ]);

    MySQLiteObject->meta->initialize;

    Test::More::is(MySQLiteObject->meta->column('id')->is_primary_key_member, 1, 'is_primary_key_member - sqlite');
    Test::More::is(MySQLiteObject->meta->column('id')->primary_key_position, 1, 'primary_key_position 1 - sqlite');
    Test::More::ok(!defined MySQLiteObject->meta->column('k1')->primary_key_position, 'primary_key_position 2 - sqlite');
    MySQLiteObject->meta->column('k1')->primary_key_position(7);
    Test::More::ok(!defined MySQLiteObject->meta->column('k1')->primary_key_position, 'primary_key_position 3 - sqlite');
  }
}

END
{
  # Delete test table

  if($HAVE_PG)
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->do('DROP TABLE rose_db_object_private.rose_db_object_test');
    $dbh->do('DROP SCHEMA rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($HAVE_MYSQL)
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->do('DROP TABLE rose_db_object_test2');

    $dbh->disconnect;
  }

  if($HAVE_INFORMIX)
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');

    $dbh->disconnect;
  }

  if($HAVE_SQLITE)
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');

    $dbh->disconnect;
  }
}
