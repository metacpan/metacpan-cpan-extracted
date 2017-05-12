#!/usr/bin/perl -w

use strict;

use Test::More tests => 448;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object::Cached');
}

our($PG_HAS_CHKPASS, $HAVE_PG, $HAVE_MYSQL, $HAVE_INFORMIX, $HAVE_SQLITE);

#
# Generic
#

foreach my $pair ((map { [ "2 $_", 2 ] } qw(s sec secs second seconds)),
                  (map { [ "2 $_", 2 * 60 ] } qw(m min mins minute minutes)),
                  (map { [ "2 $_", 2 * 60 * 60 ] } qw(h hr hrs hour hours)),
                  (map { [ "2 $_", 2 * 60 * 60 * 24 ] } qw(d day days)),
                  (map { [ "2 $_", 2 * 60 * 60 * 24 * 7 ] } qw(w wk wks week weeks)),
                  (map { [ "2 $_", 2 * 60 * 60 * 24 * 365 ] } qw(y yr yrs year years)))
{
  my($arg, $secs) = @$pair;
  MyCachedObject->meta->cached_objects_expire_in($arg);
  is(MyCachedObject->meta->cached_objects_expire_in, $secs, "cache_expires_in($arg) - generic");

  $arg =~ s/\s+//g;

  MyCachedObject->meta->cached_objects_expire_in($arg);
  is(MyCachedObject->meta->cached_objects_expire_in, $secs, "cache_expires_in($arg) - generic");
  
  MyCachedObject->cached_objects_expire_in($arg);
  my $object = MyCachedObject->new;
  is($object->cached_objects_expire_in, MyCachedObject->cached_objects_expire_in, 'object inherited expires');
}

#
# PostgreSQL
#

SKIP: foreach my $db_type (qw(pg pg_with_schema))
{
  skip("PostgreSQL tests", 159)  unless($HAVE_PG);

  Rose::DB->default_type($db_type);

  TEST_HACK:
  {
    no warnings;
    *MyPgObject::init_db = sub { Rose::DB->new($db_type) };
  }

  my $of = MyPgObject->new(name => 'John', id => 99);

  ok(ref $of && $of->isa('MyPgObject'), "cached new() 1 - $db_type");

  ok($of->save, "save() 1 - $db_type");

  my $of2 = MyPgObject->new(id => $of->id);

  ok(ref $of2 && $of2->isa('MyPgObject'), "cached new() 2 - $db_type");

  ok($of2->load, "cached load() - $db_type");

  is($of2->name, $of->name, "load() verify 1 - $db_type");

  my $of3 = MyPgObject->new(id => $of2->id);

  ok(ref $of3 && $of3->isa('MyPgObject'), "cached new() 3 - $db_type");

  ok($of3->load, "cached load() - $db_type");

  is($of3->name, $of2->name, "cached load() verify 2 - $db_type");

  is($of3, $of2, "load() verify cached 1 - $db_type");
  is($of2, $of, "load() verify cached 2 - $db_type");

  my $ouk = MyPgObject->new(name => $of->name);

  ok($ouk->load, "cached load() unique key - $db_type");
  is($ouk, $of, "load() verify cached unique key 1 - $db_type");
  is($ouk, $of2, "load() verify cached unique key 2 - $db_type");
  is($ouk, $of3, "load() verify cached unique key 3 - $db_type");

  is(keys %MyPgObject::Objects_By_Id, 1, "cache check 1 - $db_type");

  ok($of->forget, "forget() - $db_type");

  is(keys %MyPgObject::Objects_By_Id, 0, "cache check 2 - $db_type");

  # Standard tests

  my $o = MyPgObject->new(name => 'John x', id => 1);

  ok(ref $o && $o->isa('MyPgObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  my $o2 = MyPgObject->new(id => $o->id);

  ok(ref $o2 && $o2->isa('MyPgObject'), "new() 2 - $db_type");

  is($o2->bits->to_Bin, '00101', "bits() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->name, $o->name, "load() verify 1 - $db_type");
  is($o2->date_created, $o->date_created, "load() verify 2 - $db_type");
  is($o2->last_modified, $o->last_modified, "load() verify 3 - $db_type");
  is($o2->status, 'active', "load() verify 4 (default value) - $db_type");
  is($o2->flag, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->flag2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->save_col, 7, "load() verify 7 (aliased column) - $db_type");
  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');

  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified eq $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyPgObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyPgObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  ok($o->load, "load() 4 - $db_type");

  SKIP:
  {
    if($PG_HAS_CHKPASS)
    {
      $o->{'password_encrypted'} = ':8R1Kf2nOS0bRE';

      ok($o->password_is('xyzzy'), "chkpass() 1 - $db_type");
      is($o->password, 'xyzzy', "chkpass() 2 - $db_type");

      $o->password('foobar');

      ok($o->password_is('foobar'), "chkpass() 3 - $db_type");
      is($o->password, 'foobar', "chkpass() 4 - $db_type");

      ok($o->save, "save() 3 - $db_type");
    }
    else
    {
      skip("chkpass tests", 5);
    }
  }

  my $o5 = MyPgObject->new(id => $o->id);

  ok($o5->load, "load() 5 - $db_type");

  SKIP:
  {
    if($PG_HAS_CHKPASS)
    {
      ok($o5->password_is('foobar'), "chkpass() 5 - $db_type");
      is($o5->password, 'foobar', "chkpass() 6 - $db_type"); 
    }
    else
    {
      skip("chkpass tests", 2);
    }
  }

  $o5->nums([ 4, 5, 6 ]);
  ok($o5->save, "save() 4 - $db_type");
  ok($o->load, "load() 6 - $db_type");

  is($o5->nums->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o5->nums->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o5->nums->[2], 6, "load() verify 12 (array value) - $db_type");

  my @a = $o5->nums;

  is($a[0], 4, "load() verify 13 (array value) - $db_type");
  is($a[1], 5, "load() verify 14 (array value) - $db_type");
  is($a[2], 6, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 6 (array value) - $db_type");

  ok(exists $MyPgObject::Objects_By_Id{$o->id}, "pre delete and forget pk - $db_type");
  ok(exists $MyPgObject::Objects_By_Key{'name'}{$o->name}, "pre delete and forget uk - $db_type");

  ok($o->delete, "delete() - $db_type");

  ok(!exists $MyPgObject::Objects_By_Id{$o->id}, "post delete and forget pk - $db_type");
  ok(!exists $MyPgObject::Objects_By_Key{'name'}{$o->name}, "post delete and forget uk - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  $o2->forget;

  $o = MyPgObject->new(name => 'John');
  ok($o->load, "load() forget 1 - $db_type");

  $o->forget;

  $o2 = MyPgObject->new(name => 'John');
  ok($o2->load, "load() forget 2 - $db_type");

  ok($o ne $o2, "load() forget 3 - $db_type");

  $o->meta->clear_object_cache;

  FORGET_ALL_PG:
  {
    no warnings;
    is(scalar keys %MyPgObject::Objects_By_Id, 0, "clear_object_cache() 1 - $db_type");
    is(scalar keys %MyPgObject::Objects_By_Key, 0, "clear_object_cache() 2 - $db_type");
    is(scalar keys %MyPgObject::Objects_Keys, 0, "clear_object_cache() 3 - $db_type");
  }

  # Cache expiration with primary key
  MyPgObject->meta->cached_objects_expire_in('5 seconds');
  $o = MyPgObject->new(id => 99);
  $o->load or die $o->error;

  my $loaded = $MyPgObject::Objects_By_Id_Loaded{99};

  is($MyPgObject::Objects_By_Id_Loaded{99}, $loaded, "cache_expires_in pk 1 - $db_type");
  $o->load or die $o->error;
  is($MyPgObject::Objects_By_Id_Loaded{99}, $loaded, "cache_expires_in pk 2 - $db_type");
  sleep(5);
  $o->load or die $o->error;
  ok($MyPgObject::Objects_By_Id_Loaded{99} != $loaded, "cache_expires_in pk 3 - $db_type");

  # Cache expiration with unique key
  MyPgObject->meta->cached_objects_expire_in('5 seconds');
  $o = MyPgObject->new(name => 'John');
  $o->load or die $o->error;

  $loaded = $MyPgObject::Objects_By_Key_Loaded{'name'}{'John'};

  is($MyPgObject::Objects_By_Key_Loaded{'name'}{'John'}, $loaded, "cache_expires_in uk 1 - $db_type");
  $o->load or die $o->error;
  is($MyPgObject::Objects_By_Key_Loaded{'name'}{'John'}, $loaded, "cache_expires_in uk 2 - $db_type");
  sleep(5);
  $o->load or die $o->error;
  ok($MyPgObject::Objects_By_Key_Loaded{'name'}{'John'} != $loaded, "cache_expires_in uk 3 - $db_type");
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 61)  unless($HAVE_MYSQL);

  Rose::DB->default_type($db_type);

  my $opk = MyMySQLObject->new(name => 'John', id => 199);

  $opk->remember_by_primary_key;

  $opk = MyMySQLObject->new(name => 'John');
  ok(!$opk->load(speculative => 1), "remember_by_primary_key() 1 - $db_type");

  $opk = MyMySQLObject->new(id => 199);
  ok($opk->load(speculative => 1), "remember_by_primary_key() 2 - $db_type");

  $opk->forget;

  my $of = MyMySQLObject->new(name => 'John');

  ok(ref $of && $of->isa('MyMySQLObject'), "cached new() 1 - $db_type");

  ok($of->save, 'save() 1');

  my $of2 = MyMySQLObject->new(id => $of->id);

  ok(ref $of2 && $of2->isa('MyMySQLObject'), "cached new() 2 - $db_type");

  ok($of2->load, "cached load() - $db_type");

  is($of2->name, $of->name, 'load() verify 1');

  my $of3 = MyMySQLObject->new(id => $of2->id);

  ok(ref $of3 && $of3->isa('MyMySQLObject'), "cached new() 3 - $db_type");

  ok($of3->load, "cached load() - $db_type");

  is($of3->name, $of2->name, "cached load() verify 2 - $db_type");

  is($of3, $of2, "load() verify cached 1 - $db_type");
  is($of2, $of, "load() verify cached 2 - $db_type");

  my $ouk = MyMySQLObject->new(name => $of->name);

  ok($ouk->load, "cached load() unique key - $db_type");
  is($ouk, $of, "load() verify cached unique key 1 - $db_type");
  is($ouk, $of2, "load() verify cached unique key 2 - $db_type");
  is($ouk, $of3, "load() verify cached unique key 3 - $db_type");

  is(keys %MyMySQLObject::Objects_By_Id, 1, "cache check 1 - $db_type");

  ok($of->forget, 'forget()');

  is(keys %MyMySQLObject::Objects_By_Id, 0, "cache check 2 - $db_type");

  # Standard tests

  my $o = MyMySQLObject->new(name => 'John x');

  ok(ref $o && $o->isa('MyMySQLObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(22);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  my $o2 = MyMySQLObject->new(id => $o->id);

  ok(ref $o2 && $o2->isa('MyMySQLObject'), "new() 2 - $db_type");

  is($o2->bits->to_Bin, '00101', "bits() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->name, $o->name, "load() verify 1 - $db_type");
  is($o2->date_created, $o->date_created, "load() verify 2 - $db_type");
  is($o2->last_modified, $o->last_modified, "load() verify 3 - $db_type");
  is($o2->status, 'active', "load() verify 4 (default value) - $db_type");
  is($o2->flag, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->flag2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->save_col, 22, "load() verify 7 (aliased column) - $db_type");
  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified eq $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyMySQLObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyMySQLObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');

  $o = MyMySQLObject->new(name => 'John');

  ok($o->load, "load() forget 1 - $db_type");

  $o->forget;

  $o2 = MyMySQLObject->new(name => 'John');
  ok($o2->load, "load() forget 2 - $db_type");

  ok($o ne $o2, "load() forget 3 - $db_type");

  $o->meta->clear_object_cache;

  FORGET_ALL_MYSQL:
  {
    no warnings;
    is(scalar keys %MyMySQLObject::Objects_By_Id, 0, "clear_object_cache() 1 - $db_type");
    is(scalar keys %MyMySQLObject::Objects_By_Key, 0, "clear_object_cache() 2 - $db_type");
    is(scalar keys %MyMySQLObject::Objects_Keys, 0, "clear_object_cache() 3 - $db_type");
  }

  my $id = $o->id;

  # Cache expiration with primary key
  MyMySQLObject->meta->cached_objects_expire_in('5 seconds');
  $o = MyMySQLObject->new(id => $id);
  $o->load or die $o->error;

  my $loaded = $MyMySQLObject::Objects_By_Id_Loaded{$id};

  is($MyMySQLObject::Objects_By_Id_Loaded{$id}, $loaded, "cache_expires_in pk 1 - $db_type");
  $o->load or die $o->error;
  is($MyMySQLObject::Objects_By_Id_Loaded{$id}, $loaded, "cache_expires_in pk 2 - $db_type");
  sleep(5);
  $o->load or die $o->error;
  ok($MyMySQLObject::Objects_By_Id_Loaded{$id} != $loaded, "cache_expires_in pk 3 - $db_type");

  # Cache expiration with unique key
  MyMySQLObject->meta->cached_objects_expire_in('5 seconds');
  $o = MyMySQLObject->new(name => 'John');
  $o->load or die $o->error;

  $loaded = $MyMySQLObject::Objects_By_Key_Loaded{'name'}{'John'};

  is($MyMySQLObject::Objects_By_Key_Loaded{'name'}{'John'}, $loaded, "cache_expires_in uk 1 - $db_type");
  $o->load or die $o->error;
  is($MyMySQLObject::Objects_By_Key_Loaded{'name'}{'John'}, $loaded, "cache_expires_in uk 2 - $db_type");
  sleep(5);
  $o->load or die $o->error;
  ok($MyMySQLObject::Objects_By_Key_Loaded{'name'}{'John'} != $loaded, "cache_expires_in uk 3 - $db_type");
}

#
# Informix
#

SKIP: foreach my $db_type (qw(informix))
{
  skip("Informix tests", 70)  unless($HAVE_INFORMIX);

  Rose::DB->default_type($db_type);

  my $of = MyInformixObject->new(name => 'John', id => 99);

  ok(ref $of && $of->isa('MyInformixObject'), "cached new() 1 - $db_type");

  ok($of->save, "save() 1 - $db_type");

  my $of2 = MyInformixObject->new(id => $of->id);

  ok(ref $of2 && $of2->isa('MyInformixObject'), "cached new() 2 - $db_type");

  ok($of2->load, "cached load() - $db_type");

  is($of2->name, $of->name, "load() verify 1 - $db_type");

  my $of3 = MyInformixObject->new(id => $of2->id);

  ok(ref $of3 && $of3->isa('MyInformixObject'), "cached new() 3 - $db_type");

  ok($of3->load, "cached load() - $db_type");

  is($of3->name, $of2->name, "cached load() verify 2 - $db_type");

  is($of3, $of2, "load() verify cached 1 - $db_type");
  is($of2, $of, "load() verify cached 2 - $db_type");

  my $ouk = MyInformixObject->new(name => $of->name);

  ok($ouk->load, "cached load() unique key - $db_type");
  is($ouk, $of, "load() verify cached unique key 1 - $db_type");
  is($ouk, $of2, "load() verify cached unique key 2 - $db_type");
  is($ouk, $of3, "load() verify cached unique key 3 - $db_type");

  is(keys %MyInformixObject::Objects_By_Id, 1, "cache check 1 - $db_type");

  ok($of->forget, "forget() - $db_type");

  is(keys %MyInformixObject::Objects_By_Id, 0, "cache check 2 - $db_type");

  # Standard tests

  my $o = MyInformixObject->new(name => 'John x', id => 1);

  ok(ref $o && $o->isa('MyInformixObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  my $o2 = MyInformixObject->new(id => $o->id);

  ok(ref $o2 && $o2->isa('MyInformixObject'), "new() 2 - $db_type");

  is($o2->bits->to_Bin, '00101', "bits() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->name, $o->name, "load() verify 1 - $db_type");
  is($o2->date_created, $o->date_created, "load() verify 2 - $db_type");
  is($o2->last_modified, $o->last_modified, "load() verify 3 - $db_type");
  is($o2->status, 'active', "load() verify 4 (default value) - $db_type");
  is($o2->flag, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->flag2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->save_col, 7, "load() verify 7 (aliased column) - $db_type");
  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');

  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified eq $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyInformixObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyInformixObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  ok($o->load, "load() 4 - $db_type");

  my $o5 = MyInformixObject->new(id => $o->id);

  ok($o5->load, "load() 5 - $db_type");

  $o5->nums([ 4, 5, 6 ]);
  ok($o5->save, "save() 4 - $db_type");
  ok($o->load, "load() 6 - $db_type");

  is($o5->nums->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o5->nums->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o5->nums->[2], 6, "load() verify 12 (array value) - $db_type");

  my @a = $o5->nums;

  is($a[0], 4, "load() verify 13 (array value) - $db_type");
  is($a[1], 5, "load() verify 14 (array value) - $db_type");
  is($a[2], 6, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 6 (array value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');

  $o2->forget;

  $o = MyInformixObject->new(name => 'John');
  ok($o->load, "load() forget 1 - $db_type");

  $o->forget;

  $o2 = MyInformixObject->new(name => 'John');
  ok($o2->load, "load() forget 2 - $db_type");

  ok($o ne $o2, "load() forget 3 - $db_type");

  $o->meta->clear_object_cache;

  FORGET_ALL_INFORMIX:
  {
    no warnings;
    is(scalar keys %MyInformixObject::Objects_By_Id, 0, "clear_object_cache() 1 - $db_type");
    is(scalar keys %MyInformixObject::Objects_By_Key, 0, "clear_object_cache() 2 - $db_type");
    is(scalar keys %MyInformixObject::Objects_Keys, 0, "clear_object_cache() 3 - $db_type");
  }

  # Cache expiration with primary key
  MyInformixObject->meta->cached_objects_expire_in('5 seconds');
  $o = MyInformixObject->new(id => 99);
  $o->load or die $o->error;

  my $loaded = $MyInformixObject::Objects_By_Id_Loaded{99};

  is($MyInformixObject::Objects_By_Id_Loaded{99}, $loaded, "cache_expires_in pk 1 - $db_type");
  $o->load or die $o->error;
  is($MyInformixObject::Objects_By_Id_Loaded{99}, $loaded, "cache_expires_in pk 2 - $db_type");
  sleep(5);
  $o->load or die $o->error;
  ok($MyInformixObject::Objects_By_Id_Loaded{99} != $loaded, "cache_expires_in pk 3 - $db_type");

  # Cache expiration with unique key
  MyInformixObject->meta->cached_objects_expire_in('5 seconds');
  $o = MyInformixObject->new(name => 'John');
  $o->load or die $o->error;

  $loaded = $MyInformixObject::Objects_By_Key_Loaded{'name'}{'John'};

  is($MyInformixObject::Objects_By_Key_Loaded{'name'}{'John'}, $loaded, "cache_expires_in uk 1 - $db_type");
  $o->load or die $o->error;
  is($MyInformixObject::Objects_By_Key_Loaded{'name'}{'John'}, $loaded, "cache_expires_in uk 2 - $db_type");
  sleep(5);
  $o->load or die $o->error;
  ok($MyInformixObject::Objects_By_Key_Loaded{'name'}{'John'} != $loaded, "cache_expires_in uk 3 - $db_type");

  $o->meta->clear_object_cache;
}

#
# SQLite
#

SKIP: foreach my $db_type (qw(sqlite))
{
  skip("SQLite tests", 73)  unless($HAVE_SQLITE);

  Rose::DB->default_type($db_type);

  my $opk = MySQLiteObject->new(name => 'John', id => 199);

  $opk->remember_by_primary_key;

  $opk = MySQLiteObject->new(name => 'John');
  ok(!$opk->load(speculative => 1), "remember_by_primary_key() 1 - $db_type");

  $opk = MySQLiteObject->new(id => 199);
  ok($opk->load(speculative => 1), "remember_by_primary_key() 2 - $db_type");

  $opk->forget;

  my $of = MySQLiteObject->new(name => 'John', id => 99);

  ok(ref $of && $of->isa('MySQLiteObject'), "cached new() 1 - $db_type");

  ok($of->save, "save() 1 - $db_type");

  my $of2 = MySQLiteObject->new(id => $of->id);

  ok(ref $of2 && $of2->isa('MySQLiteObject'), "cached new() 2 - $db_type");

  ok($of2->load, "cached load() - $db_type");

  is($of2->name, $of->name, "load() verify 1 - $db_type");

  my $of3 = MySQLiteObject->new(id => $of2->id);

  ok(ref $of3 && $of3->isa('MySQLiteObject'), "cached new() 3 - $db_type");

  ok($of3->load, "cached load() - $db_type");

  is($of3->name, $of2->name, "cached load() verify 2 - $db_type");

  is($of3, $of2, "load() verify cached 1 - $db_type");
  is($of2, $of, "load() verify cached 2 - $db_type");

  my $ouk = MySQLiteObject->new(name => $of->name);

  ok($ouk->load, "cached load() unique key - $db_type");
  is($ouk, $of, "load() verify cached unique key 1 - $db_type");
  is($ouk, $of2, "load() verify cached unique key 2 - $db_type");
  is($ouk, $of3, "load() verify cached unique key 3 - $db_type");

  is(keys %MySQLiteObject::Objects_By_Id, 1, "cache check 1 - $db_type");

  ok($of->forget, "forget() - $db_type");

  is(keys %MySQLiteObject::Objects_By_Id, 0, "cache check 2 - $db_type");

  # Standard tests

  my $o = MySQLiteObject->new(name => 'John x', id => 1);

  ok(ref $o && $o->isa('MySQLiteObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  my $o2 = MySQLiteObject->new(id => $o->id);

  ok(ref $o2 && $o2->isa('MySQLiteObject'), "new() 2 - $db_type");

  is($o2->bits->to_Bin, '00101', "bits() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->name, $o->name, "load() verify 1 - $db_type");
  is($o2->date_created, $o->date_created, "load() verify 2 - $db_type");
  is($o2->last_modified, $o->last_modified, "load() verify 3 - $db_type");
  is($o2->status, 'active', "load() verify 4 (default value) - $db_type");
  is($o2->flag, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->flag2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->save_col, 7, "load() verify 7 (aliased column) - $db_type");
  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');

  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified eq $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MySQLiteObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MySQLiteObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  ok($o->load, "load() 4 - $db_type");

  my $o5 = MySQLiteObject->new(id => $o->id);

  ok($o5->load, "load() 5 - $db_type");

  $o5->nums([ 4, 5, 6 ]);
  ok($o5->save, "save() 4 - $db_type");
  ok($o->load, "load() 6 - $db_type");

  is($o5->nums->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o5->nums->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o5->nums->[2], 6, "load() verify 12 (array value) - $db_type");

  my @a = $o5->nums;

  is($a[0], 4, "load() verify 13 (array value) - $db_type");
  is($a[1], 5, "load() verify 14 (array value) - $db_type");
  is($a[2], 6, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 6 (array value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');

  $o2->forget;

  $o = MySQLiteObject->new(name => 'John');
  ok($o->load, "load() forget 1 - $db_type");

  $o->forget;

  $o2 = MySQLiteObject->new(name => 'John');
  ok($o2->load, "load() forget 2 - $db_type");

  ok($o ne $o2, "load() forget 3 - $db_type");

  $o->meta->clear_object_cache;

  FORGET_ALL_SQLITE:
  {
    no warnings;
    is(scalar keys %MySQLiteObject::Objects_By_Id, 0, "clear_object_cache() 1 - $db_type");
    is(scalar keys %MySQLiteObject::Objects_By_Key, 0, "clear_object_cache() 2 - $db_type");
    is(scalar keys %MySQLiteObject::Objects_Keys, 0, "clear_object_cache() 3 - $db_type");
  }

  # Cache expiration with primary key
  MySQLiteObject->meta->cached_objects_expire_in('5 seconds');
  $o = MySQLiteObject->new(id => 99);
  $o->load or die $o->error;

  my $loaded = $MySQLiteObject::Objects_By_Id_Loaded{99};

  is($MySQLiteObject::Objects_By_Id_Loaded{99}, $loaded, "cache_expires_in pk 1 - $db_type");
  $o->load or die $o->error;
  is($MySQLiteObject::Objects_By_Id_Loaded{99}, $loaded, "cache_expires_in pk 2 - $db_type");
  sleep(5);
  $o->load or die $o->error;
  ok($MySQLiteObject::Objects_By_Id_Loaded{99} != $loaded, "cache_expires_in pk 3 - $db_type");

  # Cache expiration with unique key
  MySQLiteObject->meta->cached_objects_expire_in('5 seconds');
  $o = MySQLiteObject->new(name => 'John');
  $o->load or die $o->error;

  $loaded = $MySQLiteObject::Objects_By_Key_Loaded{'namex'}{'John'};

  is($MySQLiteObject::Objects_By_Key_Loaded{'namex'}{'John'}, $loaded, "cache_expires_in uk 1 - $db_type");
  $o->load or die $o->error;
  is($MySQLiteObject::Objects_By_Key_Loaded{'namex'}{'John'}, $loaded, "cache_expires_in uk 2 - $db_type");
  sleep(5);
  $o->load or die $o->error;
  ok($MySQLiteObject::Objects_By_Key_Loaded{'namex'}{'John'} != $loaded, "cache_expires_in uk 3 - $db_type");

  MySQLiteObject->remember_all;

  $loaded = $MySQLiteObject::Objects_By_Key_Loaded{'namex'}{'John'};

  ok($loaded && $loaded ne $o, "remember_all - $db_type");
}

BEGIN
{
  #
  # Generic
  #

  GENERIC:
  {
    package MyCachedObject;
    our @ISA = qw(Rose::DB::Object::Cached);
  }

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
  id             SERIAL PRIMARY KEY,
  @{[ $PG_HAS_CHKPASS ? 'password CHKPASS,' : '' ]}
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           BIT(5) NOT NULL DEFAULT B'00101',
  start          DATE,
  save           INT,
  nums           INT[],
  last_modified  TIMESTAMP NOT NULL DEFAULT 'now',
  date_created   TIMESTAMP NOT NULL DEFAULT 'now',

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_private.rose_db_object_test
(
  id             SERIAL PRIMARY KEY,
  @{[ $PG_HAS_CHKPASS ? 'password CHKPASS,' : '' ]}
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           BIT(5) NOT NULL DEFAULT B'00101',
  start          DATE,
  save           INT,
  nums           INT[],
  last_modified  TIMESTAMP NOT NULL DEFAULT 'now',
  date_created   TIMESTAMP NOT NULL DEFAULT 'now',

  UNIQUE(name)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyPgObject;

    our @ISA = qw(Rose::DB::Object::Cached);

    sub init_db { Rose::DB->new('pg') }

    MyPgObject->meta->table('rose_db_object_test');

    MyPgObject->meta->columns
    (
      'name',
      id       => { primary_key => 1 },
      ($PG_HAS_CHKPASS ? (password => { type => 'chkpass' }) : ()),
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active' },
      start    => { type => 'date', default => '12/24/1980' },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      bits     => { type => 'bitfield', bits => 5, default => 101 },
      last_modified => { type => 'timestamp', default => 'now' },
      date_created  => { type => 'timestamp', default => 'now' },
    );

    eval { MyPgObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MyPgObject->meta->add_unique_key('name');

    MyPgObject->meta->alias_column(save => 'save_col');
    MyPgObject->meta->initialize(replace_existing => 1);

    Test::More::ok(MyPgObject->meta->method_name_is_reserved('remember', 'MyPgObject'), 'reserved method: remember');
    Test::More::ok(MyPgObject->meta->method_name_is_reserved('forget', 'MyPgObject'), 'reserved method: forget');
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
    }

    # MySQL 5.0.3 or later has a completely stupid "native" BIT type
    my $bit_col = 
      ($db_version >= 5_000_003) ?
        q(bits  BIT(5) NOT NULL DEFAULT B'00101') :
        q(bits  BIT(5) NOT NULL DEFAULT '00101');

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  flag           TINYINT(1) NOT NULL,
  flag2          TINYINT(1),
  status         VARCHAR(32) DEFAULT 'active',
  $bit_col,
  start          DATE,
  save           INT,
  last_modified  TIMESTAMP NOT NULL,
  date_created   DATETIME,

  UNIQUE(name)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyMySQLObject;

    our @ISA = qw(Rose::DB::Object::Cached);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLObject->meta->allow_inline_column_values(1);

    MyMySQLObject->meta->table('rose_db_object_test');

    MyMySQLObject->meta->columns
    (
      'name',
      id       => { primary_key => 1 },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active' },
      start    => { type => 'date', default => '12/24/1980' },
      save     => { type => 'scalar' },
      bits     => { type => 'bitfield', bits => 5, default => 101 },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'datetime' },
    );

    eval { MyMySQLObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MyMySQLObject->meta->add_unique_key('name');

    MyMySQLObject->meta->alias_column(save => 'save_col');
    MyMySQLObject->meta->initialize(preserve_existing => 1);

    Test::More::ok(MyMySQLObject->meta->method_name_is_reserved('remember', 'MyMySQLObject'), 'reserved method: remember');
    Test::More::ok(MyMySQLObject->meta->method_name_is_reserved('forget', 'MyMySQLObject'), 'reserved method: forget');
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
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           VARCHAR(5) DEFAULT '00101' NOT NULL,
  nums           VARCHAR(255),
  start          DATE,
  save           INT,
  last_modified  DATETIME YEAR TO FRACTION(5),
  date_created   DATETIME YEAR TO FRACTION(5),

  UNIQUE(name)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyInformixObject;

    our @ISA = qw(Rose::DB::Object::Cached);

    sub init_db { Rose::DB->new('informix') }

    MyInformixObject->meta->table('rose_db_object_test');

    MyInformixObject->meta->columns
    (
      'name',
      id       => { primary_key => 1 },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active' },
      start    => { type => 'date', default => '12/24/1980' },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      bits     => { type => 'bitfield', bits => 5, default => 101 },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    eval { MyInformixObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MyInformixObject->meta->add_unique_key('name');

    MyInformixObject->meta->alias_column(save => 'save_col');
    MyInformixObject->meta->initialize(preserve_existing => 1);

    Test::More::ok(MyInformixObject->meta->method_name_is_reserved('remember', 'MyInformixObject'), 'reserved method: remember');
    Test::More::ok(MyInformixObject->meta->method_name_is_reserved('forget', 'MyInformixObject'), 'reserved method: forget');
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
  namex          VARCHAR(32) NOT NULL,
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           VARCHAR(5) DEFAULT '00101' NOT NULL,
  nums           VARCHAR(255),
  startx         DATE,
  save           INT,
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  UNIQUE(namex)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MySQLiteObject;

    our @ISA = qw(Rose::DB::Object::Cached);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteObject->meta->table('rose_db_object_test');

    MySQLiteObject->meta->columns
    (
      namex    => { alias => 'name' },
      id       => { primary_key => 1 },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active' },
      startx   => { type => 'date', default => '12/24/1980', alias => 'start' },
      'save',
      nums     => { type => 'array' },
      bits     => { type => 'bitfield', bits => 5, default => 101 },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    eval { MySQLiteObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MySQLiteObject->meta->add_unique_key('namex');

    MySQLiteObject->meta->alias_column(save => 'save_col');
    MySQLiteObject->meta->initialize(preserve_existing => 1);

    Test::More::ok(MySQLiteObject->meta->method_name_is_reserved('remember', 'MySQLiteObject'), 'reserved method: remember');
    Test::More::ok(MySQLiteObject->meta->method_name_is_reserved('forget', 'MySQLiteObject'), 'reserved method: forget');
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
    # SQLite
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');

    $dbh->disconnect;
  }
}
