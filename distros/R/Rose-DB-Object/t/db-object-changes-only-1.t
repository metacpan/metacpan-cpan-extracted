#!/usr/bin/perl -w

use strict;

use Test::More tests => 490;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Util');
}

Rose::DB::Object::Util->import(':all');

our($PG_HAS_CHKPASS, $HAVE_PG, $HAVE_MYSQL, $HAVE_INFORMIX, $HAVE_SQLITE);

#
# PostgreSQL
#

SKIP: foreach my $db_type (qw(pg pg_with_schema))
{
  skip("PostgreSQL tests", 222)  unless($HAVE_PG);

  Rose::DB->default_type($db_type);

  TEST_HACK:
  {
    no warnings;
    *MyPgObject::init_db = sub { Rose::DB->new($db_type) };
  }

  my $o = MyPgObject->new(name => 'John', 
                          k1   => 1,
                          k2   => undef,
                          k3   => 3);

  ok(ref $o && $o->isa('MyPgObject'), "new() 1 - $db_type");

  $o->flag2('TRUE');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);

  if(rand >= 0.5)
  {
    ok($o->save, "save() 1 - $db_type");
  }
  else
  {
    ok($o->insert, "insert() 1 - $db_type");
  }

  is($o->meta->primary_key->sequence_names->[0], 'rose_db_object_test_id_seq', 
     "pk sequence name - $db_type");

  ok(is_in_db($o), "is_in_db - $db_type");

  is($o->id, 1, "auto-generated primary key - $db_type");

  ok($o->load, "load() 1 - $db_type");

  $o->name('C' x 50);
  is($o->name, 'C' x 32, "varchar truncation - $db_type");

  $o->name('John');

  $o->code('A');
  is($o->code, 'A     ', "character padding - $db_type");

  $o->code('C' x 50);
  is($o->code, 'C' x 6, "character truncation - $db_type");

  my $ouk;
  ok($ouk = MyPgObject->new(k1 => 1,
                            k2 => undef,
                            k3 => 3)->load, "load() uk 1 - $db_type");

  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->id, 1, "load() uk 2 - $db_type");
  is($ouk->name, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

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

  $o2->set_status('foo');
  is($o2->get_status, 'foo', "get_status() - $db_type");
  $o2->set_status('active');
  eval { $o2->set_status };
  ok($@, "set_status() - $db_type");

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->start eq $clone->start, "clone() 1 - $db_type");
  $clone->start->set(year => '1960');
  ok($o2->start ne $clone->start, "clone() 2 - $db_type");

  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  ok(!has_modified_columns($o2), "no modified columns after load() - $db_type");

  $o2->name('John 2');
  $o2->save(changes_only => 1);

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $bo = MyPgObject->new(id => $o->id);
  $bo->load;
  $bo->flag(0);
  $bo->save;

  $bo = MyPgObject->new(id => $o->id);
  $bo->load;

  ok(!$bo->flag, "boolean check - $db_type");

  $bo->flag(0);
  $bo->save;

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

      $o->code('C1');
      #local $Rose::DB::Object::Debug = 1;
      ok($o->save, "save() 3 - $db_type");

      $o = MyPgObject->new(id => $o->id)->load;      
      $o->code('C2');
      $o->save;

      $o = MyPgObject->new(id => $o->id)->load;
      ok($o->password_is('foobar'), "chkpass() 6 - $db_type");
    }
    else
    {
      skip("chkpass tests", 6);
    }
  }

  my $o5 = MyPgObject->new(id => $o->id);

  ok($o5->load, "load() 5 - $db_type");

  SKIP:
  {
    if($PG_HAS_CHKPASS)
    {
      ok($o5->password_is('foobar'), "chkpass() 7 - $db_type");
      is($o5->password, 'foobar', "chkpass() 8 - $db_type"); 
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
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MyPgObject->new(name => 'John', id => 9);
  $o->save_col(22);
  ok($o->save, "save() 4 - $db_type");
  $o->save_col(50);
  ok($o->save, "save() 5 - $db_type");

  $ouk = MyPgObject->new(save_col => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # This is okay now
  #eval { $o->meta->alias_column(id => 'foo') };
  #ok($@, "alias_column() primary key - $db_type");

  $o = MyPgObject->new(id => 777);

  $o->meta->error_mode('fatal');

  $o->dbh->{'PrintError'} = 0;

  eval { $o->load };
  ok($@ && $o->not_found, "load() not found fatal - $db_type");

  $o->id('abc');

  eval { $o->load };
  ok($@ && !$o->not_found, "load() fatal - $db_type");

  eval { $o->save };
  ok($@, "save() fatal - $db_type");

  $o = MyPgObject->new(id => 9999); # no such id

  $o->meta->error_mode('fatal');

  eval { $o->load() };
  ok($@, "load() non-speculative implicit - $db_type");  
  ok(!$o->load(speculative => 1), "load() speculative explicit 1 - $db_type");
  eval { $o->load(speculative => 0) };
  ok($@, "load() non-speculative explicit 2 - $db_type");

  $o->meta->default_load_speculative(1);

  ok(!$o->load(), "load() speculative implicit - $db_type");  
  ok(!$o->load(speculative => 1), "load() speculative explicit 2 - $db_type");
  eval { $o->load(speculative => 0) };
  ok($@, "load() non-speculative explicit 2 - $db_type");

  # Reset for next trip through loop
  $o->meta->default_load_speculative(0);
  $o->meta->error_mode('return');

  $o = MyPgObject->new(name => 'John', 
                       k1   => 1,
                       k2   => undef,
                       k3   => 3)->save;

  is($o->dur->months, 2, "interval months 1 - $db_type");
  is($o->dur->days, 5, "interval days 1 - $db_type");
  is($o->dur->seconds, 3, "interval seconds 1 - $db_type");

  $o->dur(DateTime::Duration->new(years => 7, nanoseconds => 3000));

  is($o->dur->in_units('years'), 7, "interval in_units years 1 - $db_type");
  is($o->dur->in_units('months'), 84, "interval in_units months 1 - $db_type");
  # Test disabled until https://github.com/lestrrat-p5/DateTime-Format-Pg/issues/19 is addressed
  #is($o->dur->nanoseconds, 3000, "interval nanoseconds 1 - $db_type");
  is($o->dur->days, 0, "interval days 2 - $db_type");
  is($o->dur->minutes, 0, "interval minutes 2 - $db_type");
  is($o->dur->seconds, 0, "interval seconds 2 - $db_type");

  $o->save;

  $o = MyPgObject->new(id => $o->id)->load;

  is($o->dur->in_units('years'), 7, "interval in_units years 2 - $db_type");
  is($o->dur->in_units('months'), 84, "interval in_units months 2 - $db_type");
  # Test disabled until https://github.com/lestrrat-p5/DateTime-Format-Pg/issues/19 is addressed
  #is($o->dur->nanoseconds, 3000, "interval nanoseconds 2 - $db_type");
  is($o->dur->days, 0, "interval days 3 - $db_type");
  is($o->dur->minutes, 0, "interval minutes 3 - $db_type");
  is($o->dur->seconds, 0, "interval seconds 3 - $db_type");

  is($o->epoch(format => '%Y-%m-%d %H:%M:%S'), '1999-11-30 21:30:00', "epoch 1 - $db_type");

  $o->hiepoch('943997400.123456');
  is($o->hiepoch(format => '%Y-%m-%d %H:%M:%S.%6N'), '1999-11-30 21:30:00.123456', "epoch hires 1 - $db_type");

  $o->epoch('5/6/1980 12:34:56');

  $o->save;

  $o = MyPgObject->new(id => $o->id)->load;

  is($o->epoch(format => '%Y-%m-%d %H:%M:%S'), '1980-05-06 12:34:56', "epoch 2 - $db_type");
  is($o->hiepoch(format => '%Y-%m-%d %H:%M:%S.%6N'), '1999-11-30 21:30:00.123456', "epoch hires 2 - $db_type");

  is($o->bint1, '9223372036854775800', "bigint 1 - $db_type");
  is($o->bint2, '-9223372036854775800', "bigint 2 - $db_type");
  is($o->bint3, '9223372036854775000', "bigint 3 - $db_type");
  is($o->bint4, undef, "bigint 3.1 - $db_type");

  $o->bint1($o->bint1 + 1);
  $o->save;

  $o = MyPgObject->new(id => $o->id)->load;
  is($o->bint1, '9223372036854775801', "bigint 4 - $db_type");

  $o->bint3(5);
  eval { $o->bint3(7) };
  ok($@, "bigint 5 - $db_type");

  #local $Rose::DB::Object::Debug = 1;  
  $o = MyPgObject2->new->save(changes_only => 1);
  $o = MyPgObject2->new(id => $o->id)->load;

  is($o->num, 123, "insert changes only 1 - $db_type");
  is($o->flag, 2, "insert changes only 2 - $db_type");

  $o = MyPgObject2->new(flag => 7)->save(changes_only => 1);
  $o = MyPgObject2->new(id => $o->id)->load;

  is($o->num, 123, "insert changes only 3 - $db_type");
  is($o->flag, 7, "insert changes only 4 - $db_type");

  #local $Rose::DB::Object::Debug = 1;  
  $o = MyPgObject3->new->save;
  $o = MyPgObject3->new(id => $o->id)->load;

  is($o->num, 123, "insert changes only 5 - $db_type");
  is($o->flag, 1, "insert changes only 6 - $db_type");

  $o = MyPgObject2->new(flag => 7)->save(changes_only => 1);
  $o = MyPgObject2->new(id => $o->id)->load;

  is($o->num, 123, "insert changes only 7 - $db_type");
  is($o->flag, 7, "insert changes only 8 - $db_type");

  MyPgObject3->meta->allow_inline_column_values(1);
  $o = MyPgObject3->new(dt => 'now()')->save(changes_only => 1);
  $o = MyPgObject3->new(id => $o->id)->load;

  is($o->num, 123, "insert changes only 9 - $db_type");
  is($o->flag, 1, "insert changes only 10 - $db_type");
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 105)  unless($HAVE_MYSQL);

  Rose::DB->default_type($db_type);

  my $o = MyMySQLObject->new(name => 'John',
                             k1   => 1,
                             k2   => undef,
                             k3   => 3);

  ok(ref $o && $o->isa('MyMySQLObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(22);

  $o->bitz3('11');

  if(rand >= 0.5)
  {
    ok($o->save, "save() 1 - $db_type");
  }
  else
  {
    ok($o->insert, "insert() 1 - $db_type");
  }

  ok($o->load, "load() 1 - $db_type");

  my $ox = MyMySQLObject->new(id => $o->id)->load;
  is($ox->bitz2->to_Bin(), '00', "spot check bitfield 1 - $db_type");
  is($ox->bitz3->to_Bin(), '0011', "spot check bitfield 2 - $db_type");

  eval { $o->name('C' x 50) };
  ok($@, "varchar overflow fatal - $db_type");

  $o->name('John');

  $o->code('A');
  is($o->code, 'A     ', "character padding - $db_type");

  eval { $o->code('C' x 50) };
  ok($@, "code overflow fatal - $db_type");
  $o->code('C' x 6);

  is($o->enums, 'foo', "enum 1 - $db_type");
  eval { $o->enums('blee') };
  ok($@, "enum 2 - $db_type");

  $o->enums('bar');

  my $ouk;

  ok($ouk = MyMySQLObject->new(k1 => 1,
                               k2 => undef,
                               k3 => 3)->load, "load() uk 1 - $db_type");

  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->id, 1, "load() uk 2 - $db_type");
  is($ouk->name, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

  my $o2 = MyMySQLObject->new(id => $o->id);

  ok(ref $o2 && $o2->isa('MyMySQLObject'), "new() 2 - $db_type");

  is($o2->bits->to_Bin, '00101', "bits() (bitfield default value) - $db_type");
  is($o2->bitz2->to_Bin, '00', "bitz2() (bitfield default value) - $db_type");

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

  $o2->set_status('foo');
  is($o2->get_status, 'foo', 'get_status()');
  $o2->set_status('active');
  eval { $o2->set_status };
  ok($@, 'set_status()');

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");
  is($o2->bitz2->to_Bin, '00', "load() verify 10 (bitfield value) - $db_type");
  is($o2->bitz3->to_Bin, '0011', "load() verify 11 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->start eq $clone->start, "clone() 1 - $db_type");
  $clone->start->set(year => '1960');
  ok($o2->start ne $clone->start, "clone() 2 - $db_type");

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyMySQLObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyMySQLObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  $o->nums([ 4, 5, 6 ]);
  ok($o->save, "save() 3 - $db_type");
  ok($o->load, "load() 4 - $db_type");

  is($o->nums->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o->nums->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o->nums->[2], 6, "load() verify 12 (array value) - $db_type");

  my @a = $o->nums;

  is($a[0], 4, "load() verify 13 (array value) - $db_type");
  is($a[1], 5, "load() verify 14 (array value) - $db_type");
  is($a[2], 6, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MyMySQLObject->new(name => 'John', id => 9);
  $o->save_col(22);

  ok($o->save, "save() 4 - $db_type");
  $o->save_col(50);
  ok($o->save, "save() 5 - $db_type");

  $ouk = MyMySQLObject->new(save_col => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # This is okay now
  #eval { $o->meta->alias_column(id => 'foo') };
  #ok($@, "alias_column() primary key - $db_type");

  $o = MyMySQLObject->new(id => 777);

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

  $o = MyMPKMySQLObject->new(name => 'John');

  ok($o->save, "save() 1 multi-value primary key with generated values - $db_type");

  is($o->k1, 1, "save() verify 1 multi-value primary key with generated values - $db_type");
  is($o->k2, 2, "save() verify 2 multi-value primary key with generated values - $db_type");

  $o = MyMPKMySQLObject->new(name => 'Alex');

  ok($o->save, "save() 2 multi-value primary key with generated values - $db_type");

  is($o->k1, 3, "save() verify 3 multi-value primary key with generated values - $db_type");
  is($o->k2, 4, "save() verify 4 multi-value primary key with generated values - $db_type");

  is($ox->bitz3->to_Bin(), '0011', "spot check bitfield 3 - $db_type");

  $ox->bitz3->Bit_On(3);
  set_column_value_modified($ox, 'bitz3');
  is($ox->bitz3->to_Bin(), '1011', "spot check bitfield 4 - $db_type");

  $ox->save(insert => 1);

  $ox = MyMySQLObject->new(id => $ox->id)->load;
  is($ox->bitz3->to_Bin(), '1011', "spot check bitfield 5 - $db_type");

  $ox->bitz3->Bit_On(2);
  set_column_value_modified($ox, 'bitz3');
  $ox->save;
  $ox = MyMySQLObject->new(id => $ox->id)->load;
  is($ox->bitz3->to_Bin(), '1111', "spot check bitfield 6 - $db_type");

  $o = MyMySQLObject->new(id => 9999); # no such id

  $o->meta->error_mode('fatal');

  eval { $o->load() };
  ok($@, "load() non-speculative implicit - $db_type");  
  ok(!$o->load(speculative => 1), "load() speculative explicit 1 - $db_type");
  eval { $o->load(speculative => 0) };
  ok($@, "load() non-speculative explicit 2 - $db_type");

  $o->meta->default_load_speculative(1);

  ok(!$o->load(), "load() speculative implicit - $db_type");  
  ok(!$o->load(speculative => 1), "load() speculative explicit 2 - $db_type");
  eval { $o->load(speculative => 0) };
  ok($@, "load() non-speculative explicit 2 - $db_type");

  $o->meta->default_load_speculative(0);

  $o = MyMySQLObject->new(id => 1)->load;

  is($o->dur->months, 2, "interval months 1 - $db_type");
  is($o->dur->days, 5, "interval days 1 - $db_type");
  is($o->dur->seconds, 3, "interval seconds 1 - $db_type");

  $o->dur(DateTime::Duration->new(years => 7, nanoseconds => 3000));

  is($o->dur->in_units('years'), 7, "interval in_units years 1 - $db_type");
  is($o->dur->in_units('months'), 84, "interval in_units months 1 - $db_type");
  is($o->dur->nanoseconds, 3000, "interval nanoseconds 1 - $db_type");
  is($o->dur->days, 0, "interval days 2 - $db_type");
  is($o->dur->minutes, 0, "interval minutes 2 - $db_type");
  is($o->dur->seconds, 0, "interval seconds 2 - $db_type");

  $o->save;

  $o = MyMySQLObject->new(id => $o->id)->load;

  is($o->dur->in_units('years'), 7, "interval in_units years 2 - $db_type");
  is($o->dur->in_units('months'), 84, "interval in_units months 2 - $db_type");
  is($o->dur->nanoseconds, 3000, "interval nanoseconds 2 - $db_type");
  is($o->dur->days, 0, "interval days 3 - $db_type");
  is($o->dur->minutes, 0, "interval minutes 3 - $db_type");
  is($o->dur->seconds, 0, "interval seconds 3 - $db_type");

  is($o->meta->column('dur')->scale, 6, "interval scale - $db_type");

  is($o->epoch(format => '%Y-%m-%d %H:%M:%S'), '1999-11-30 21:30:00', "epoch 1 - $db_type");

  $o->hiepoch('943997400.123456');
  is($o->hiepoch(format => '%Y-%m-%d %H:%M:%S.%6N'), '1999-11-30 21:30:00.123456', "epoch hires 1 - $db_type");

  $o->epoch('5/6/1980 12:34:56');

  $o->save;

  $o = MyMySQLObject->new(id => $o->id)->load;

  is($o->epoch(format => '%Y-%m-%d %H:%M:%S'), '1980-05-06 12:34:56', "epoch 2 - $db_type");
  is($o->hiepoch(format => '%Y-%m-%d %H:%M:%S.%6N'), '1999-11-30 21:30:00.123456', "epoch hires 2 - $db_type");

  #local $Rose::DB::Object::Debug = 1;  
  $o = MyMySQLObject3->new->save;
  $o = MyMySQLObject3->new(id => $o->id)->load;

  is($o->num, 123, "insert changes only 5 - $db_type");
  is($o->flag, 1, "insert changes only 6 - $db_type");
}

#
# Informix
#

SKIP: foreach my $db_type ('informix')
{
  skip("Informix tests", 73)  unless($HAVE_INFORMIX);

  Rose::DB->default_type($db_type);

  my $o = MyInformixObject->new(name => 'John', 
                                id   => 1,
                                k1   => 1,
                                k2   => undef,
                                k3   => 3);

  ok(ref $o && $o->isa('MyInformixObject'), "new() 1 - $db_type");

  $o->meta->allow_inline_column_values(1);

  $o->flag2('true');
  $o->date_created('current year to fraction(5)');
  $o->last_modified($o->date_created);
  $o->save_col(22);

  if(rand >= 0.5)
  {
    ok($o->save, "save() 1 - $db_type");
  }
  else
  {
    ok($o->insert, "insert() 1 - $db_type");
  }

  ok($o->load, "load() 1 - $db_type");

  $o->name('C' x 50);
  is($o->name, 'C' x 32, "varchar truncation - $db_type");

  $o->name('John');

  $o->code('A');
  is($o->code, 'A     ', "character padding - $db_type");

  $o->code('C' x 50);
  is($o->code, 'C' x 6, "character truncation - $db_type");

  my $ouk;
  ok($ouk = MyInformixObject->new(k1 => 1,
                                  k2 => undef,
                                  k3 => 3)->load, "load() uk 1 - $db_type");

  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->id, 1, "load() uk 2 - $db_type");
  is($ouk->name, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

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
  is($o2->save_col, 22, "load() verify 7 (aliased column) - $db_type");
  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  $o2->set_status('foo');
  is($o2->get_status, 'foo', 'get_status()');
  $o2->set_status('active');
  eval { $o2->set_status };
  ok($@, 'set_status()');

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->start eq $clone->start, "clone() 1 - $db_type");
  $clone->start->set(year => '1960');
  ok($o2->start ne $clone->start, "clone() 2 - $db_type");

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('current year to second');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyInformixObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyInformixObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  $o->nums([ 4, 5, 6 ]);
  $o->names([ qw(a b 3.1) ]);

  ok($o->save, "save() 3 - $db_type");
  ok($o->load, "load() 4 - $db_type");

  is($o->nums->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o->nums->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o->nums->[2], 6, "load() verify 12 (array value) - $db_type");

  $o->nums(7, 8, 9);

  my @a = $o->nums;

  is($a[0], 7, "load() verify 13 (array value) - $db_type");
  is($a[1], 8, "load() verify 14 (array value) - $db_type");
  is($a[2], 9, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  is($o->names->[0], 'a', "load() verify 10 (set value) - $db_type");
  is($o->names->[1], 'b', "load() verify 11 (set value) - $db_type");
  is($o->names->[2], '3.1', "load() verify 12 (set value) - $db_type");

  $o->names('c', 'd', '4.2');

  @a = $o->names;

  is($a[0], 'c', "load() verify 13 (set value) - $db_type");
  is($a[1], 'd', "load() verify 14 (set value) - $db_type");
  is($a[2], '4.2', "load() verify 15 (set value) - $db_type");
  is(@a, 3, "load() verify 16 (set value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MyInformixObject->new(name => 'John', id => 9);

  $o->flag2('true');
  $o->date_created('current year to fraction(5)');
  $o->last_modified($o->date_created);
  $o->save_col(22);

  ok($o->save, "save() 4 - $db_type");
  $o->save_col(50);

  ok($o->save, "save() 5 - $db_type");

  $ouk = MyInformixObject->new(save_col => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # This is okay now
  #eval { $o->meta->alias_column(id => 'foo') };
  #ok($@, "alias_column() primary key - $db_type");

  $o = MyInformixObject->new(id => 777);

  $o->meta->error_mode('fatal');

  $o->dbh->{'PrintError'} = 0;

  eval { $o->load };
  ok($@ && $o->not_found, "load() not found fatal - $db_type");

  $o->id('abc');

  eval { $o->load };
  ok($@ && !$o->not_found, "load() fatal - $db_type");

  eval { $o->save };
  ok($@, "save() fatal - $db_type");

  #$o->meta->error_mode('return');

  $o = MyInformixObject->new(id => 9999); # no such id

  $o->meta->error_mode('fatal');

  eval { $o->load() };
  ok($@, "load() non-speculative implicit - $db_type");  
  ok(!$o->load(speculative => 1), "load() speculative explicit 1 - $db_type");
  eval { $o->load(speculative => 0) };
  ok($@, "load() non-speculative explicit 2 - $db_type");

  $o->meta->default_load_speculative(1);

  ok(!$o->load(), "load() speculative implicit - $db_type");  
  ok(!$o->load(speculative => 1), "load() speculative explicit 2 - $db_type");
  eval { $o->load(speculative => 0) };
  ok($@, "load() non-speculative explicit 2 - $db_type");
}

#
# SQLite
#

SKIP: foreach my $db_type ('sqlite')
{
  skip("SQLite tests", 88)  unless($HAVE_SQLITE);

  Rose::DB->default_type($db_type);

  my $o = MySQLiteObject->new;

  $o->k1(0);

  ok(has_modified_columns($o), "has_modified_columns() zero - $db_type");

  $o->k1(undef);

  ok(has_modified_columns($o), "has_modified_columns() undef - $db_type");

  $o = MySQLiteObject->new(name => 'John',
                           k1   => 0,
                           k2   => undef,
                           k3   => 3);

  ok(get_column_value_modified($o, 'k1'), "zero modification - $db_type");

  $o->k1(1);

  ok(ref $o && $o->isa('MySQLiteObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(22);

  if(rand >= 0.5)
  {
    ok($o->save, "save() 1 - $db_type");
  }
  else
  {
    ok($o->insert, "insert() 1 - $db_type");
  }

  ok($o->load, "load() 1 - $db_type");

  $o->name('C' x 50);
  is($o->name, 'C' x 32, "varchar truncation - $db_type");

  $o->name('John');

  $o->code('A');
  is($o->code, 'A     ', "character padding - $db_type");

  $o->code('C' x 50);
  is($o->code, 'C' x 6, "character truncation - $db_type");

  my $ouk;
  ok($ouk = MySQLiteObject->new(k1 => 1,
                                k2 => undef,
                                k3 => 3)->load, "load() uk 1 - $db_type");

  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->id->[0], 1, "load() uk 2 - $db_type");
  is($ouk->name, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

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
  is($o2->save_col, 22, "load() verify 7 (aliased column) - $db_type");
  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  $o2->set_status('foo');
  is($o2->get_status, 'foo', 'get_status()');
  $o2->set_status('active');
  eval { $o2->set_status };
  ok($@, 'set_status()');

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->start eq $clone->start, "clone() 1 - $db_type");
  $clone->start->set(year => '1960');
  ok($o2->start ne $clone->start, "clone() 2 - $db_type");

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MySQLiteObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MySQLiteObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  $o->nums([ 4, 5, 6 ]);
  ok($o->save, "save() 3 - $db_type");
  ok($o->load, "load() 4 - $db_type");

  is($o->nums->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o->nums->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o->nums->[2], 6, "load() verify 12 (array value) - $db_type");

  my @a = $o->nums;

  is($a[0], 4, "load() verify 13 (array value) - $db_type");
  is($a[1], 5, "load() verify 14 (array value) - $db_type");
  is($a[2], 6, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MySQLiteObject->new(name => 'John', id => 9);
  $o->save_col(22);
  ok($o->save, "save() 4 - $db_type");
  $o->save_col(50);
  ok($o->save, "save() 5 - $db_type");

  $ouk = MySQLiteObject->new(save_col => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # This is okay now
  #eval { $o->meta->alias_column(id => 'foo') };
  #ok($@, "alias_column() primary key - $db_type");

  $o = MySQLiteObject->new(id => 777);

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

  $o = MyMPKSQLiteObject->new(name => 'John');

  ok($o->save, "save() 1 multi-value primary key with generated values - $db_type");

  is($o->k1, 1, "save() verify 1 multi-value primary key with generated values - $db_type");
  is($o->k2, 2, "save() verify 2 multi-value primary key with generated values - $db_type");

  $o = MyMPKSQLiteObject->new(name => 'Alex');

  ok($o->save, "save() 2 multi-value primary key with generated values - $db_type");

  is($o->k1, 3, "save() verify 3 multi-value primary key with generated values - $db_type");
  is($o->k2, 4, "save() verify 4 multi-value primary key with generated values - $db_type");

  $o = MySQLiteObject->new(id => 9999); # no such id

  $o->meta->error_mode('fatal');

  eval { $o->load() };
  ok($@, "load() non-speculative implicit - $db_type");  
  ok(!$o->load(speculative => 1), "load() speculative explicit 1 - $db_type");
  eval { $o->load(speculative => 0) };
  ok($@, "load() non-speculative explicit 2 - $db_type");

  $o->meta->default_load_speculative(1);

  ok(!$o->load(), "load() speculative implicit - $db_type");  
  ok(!$o->load(speculative => 1), "load() speculative explicit 2 - $db_type");
  eval { $o->load(speculative => 0) };
  ok($@, "load() non-speculative explicit 2 - $db_type");

  #local $Rose::DB::Object::Debug = 1;  
  $o = MySQLiteObject3->new->save;
  $o = MySQLiteObject3->new(id => $o->id)->load;

  is($o->num, 123, "insert changes only 1 - $db_type");
  is($o->flag, 2, "insert changes only 2 - $db_type");

  $o = MySQLiteObject3->new(flag => 7)->save;
  $o = MySQLiteObject3->new(id => $o->id)->load;

  is($o->num, 123, "insert changes only 1 - $db_type");
  is($o->flag, 7, "insert changes only 2 - $db_type");

  $o->num(123);

  QUIET:
  {
    local $Rose::DB::Object::Debug = 1;
    ok($o->save(changes_only => 1), "noop update smart 1 - $db_type");
  }

  $o->num(undef);
  $o->save;

  $o->num(0);
  ok(has_modified_columns($o), "zero mod 1 - $db_type");
  $o->save(changes_only => 1);

  $o->num(0);
  ok(!has_modified_columns($o), "zero mod 2 - $db_type");
  $o->save(changes_only => 1);

  $o->num(undef);
  ok(has_modified_columns($o), "undef mod - $db_type");
  $o->save(changes_only => 1);
  $o->load;

  $o->num('');
  ok(has_modified_columns($o), "empty string mod 1 - $db_type");
  $o->save(changes_only => 1);
  $o->load;

  is($o->num, '', "empty string mod 2 - $db_type");

  $o = MySQLiteObject4->new(id => 1)->save;
  $o = MySQLiteObject4->new(id => 1)->load;
  ok($o->save, "noop update pk only 1 - $db_type");

  $o->meta->default_insert_changes_only(0);
  $o->meta->default_update_changes_only(0);

  $o = MySQLiteObject4->new(id => 2)->save;
  $o = MySQLiteObject4->new(id => 2)->load;
  ok($o->save, "noop update pk only 2 - $db_type");
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
      $dbh->do('DROP TABLE rose_db_object_test2');
      $dbh->do('DROP TABLE rose_db_object_test3');
      $dbh->do('DROP TABLE rose_db_object_private.rose_db_object_test');
      $dbh->do('DROP TABLE rose_db_object_private.rose_db_object_test2');
      $dbh->do('DROP TABLE rose_db_object_private.rose_db_object_test3');
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
  decs           DECIMAL(10,2),
  start          DATE,
  save           INT,
  nums           INT[],
  dur            INTERVAL(6) DEFAULT '2 months 5 days 3 seconds',
  epoch          INT DEFAULT 943997400,
  hiepoch        DECIMAL(16,6),
  bint1          BIGINT DEFAULT 9223372036854775800,
  bint2          BIGINT DEFAULT -9223372036854775800,
  bint3          BIGINT,
  bint4          BIGINT,
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
  decs           DECIMAL(10,2),
  start          DATE,
  save           INT,
  nums           INT[],
  dur            INTERVAL(6) DEFAULT '2 months 5 days 3 seconds',
  epoch          INT DEFAULT 943997400,
  hiepoch        DECIMAL(16,6),
  bint1          BIGINT DEFAULT 9223372036854775800,
  bint2          BIGINT DEFAULT -9223372036854775800,
  bint3          BIGINT,
  bint4          BIGINT,
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test2
(
  id     SERIAL PRIMARY KEY,
  num    INT DEFAULT 123,
  flag   INT DEFAULT 1,
  f2     INT
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_private.rose_db_object_test2
(
  id     SERIAL PRIMARY KEY,
  num    INT DEFAULT 123,
  flag   INT DEFAULT 1,
  f2     INT
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test3
(
  id     SERIAL PRIMARY KEY,
  num    INT DEFAULT 123,
  flag   INT DEFAULT 1,
  dt     TIMESTAMP
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_private.rose_db_object_test3
(
  id     SERIAL PRIMARY KEY,
  num    INT DEFAULT 123,
  flag   INT DEFAULT 1,
  dt     TIMESTAMP
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyPgObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('pg') }

    MyPgObject->meta->default_update_changes_only(1);

    MyPgObject->meta->table('rose_db_object_test');

    MyPgObject->meta->columns
    (
      name     => { type => 'varchar', length => 32, overflow => 'truncate' },
      code     => { type => 'char', length => 6, overflow => 'truncate' },
      id       => { primary_key => 1, not_null => 1 },
      k1       => { type => 'int' },
      k2       => { type => 'int', lazy => 1 },
      k3       => { type => 'int' },
      ($PG_HAS_CHKPASS ? (passwd => { type => 'chkpass', alias => 'password' }) : ()),
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active', add_methods => [ qw(get set) ] },
      start    => { type => 'date', default => '12/24/1980', lazy => 1 },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      bitz     => { type => 'bitfield', bits => 5, default => 101, alias => 'bits' },
      decs     => { type => 'decimal', precision => 10, scale => 2 },
      dur      => { type => 'interval', scale => 6, default => '2 months 5 days 3 seconds' },
      epoch    => { type => 'epoch', default => '11/30/1999 9:30pm' },
      hiepoch  => { type => 'epoch hires', default => '1144004926.123456' },
      bint1    => { type => 'bigint', default => '9223372036854775800' },
      bint2    => { type => 'bigint', default => '-9223372036854775800' },
      bint3    => { type => 'bigint', with_init => 1, check_in => [ '9223372036854775000', 5 ] },
      bint4    => { type => 'bigint', with_init => 1 },
      #last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    sub init_bint4 { undef }

    MyPgObject->meta->add_unique_key('save');

    MyPgObject->meta->add_unique_key([ qw(k1 k2 k3) ]);

    MyPgObject->meta->add_columns(
      Rose::DB::Object::Metadata::Column::Timestamp->new(
        name => 'last_modified'));

    eval { MyPgObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MyPgObject->meta->alias_column(save => 'save_col');

    eval { MyPgObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() no override');

    MyPgObject->meta->initialize(preserve_existing => 1);

    Test::More::is(MyPgObject->meta->column('id')->is_primary_key_member, 1, 'is_primary_key_member - pg');
    Test::More::is(MyPgObject->meta->column('id')->primary_key_position, 1, 'primary_key_position 1 - pg');
    Test::More::ok(!defined MyPgObject->meta->column('k1')->primary_key_position, 'primary_key_position 2 - pg');
    MyPgObject->meta->column('k1')->primary_key_position(7);
    Test::More::ok(!defined MyPgObject->meta->column('k1')->primary_key_position, 'primary_key_position 3 - pg');

    sub init_bint3 { '9223372036854775000' }

    package MyPgObject2;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg') }
    MyPgObject2->meta->setup
    (
      table   => 'rose_db_object_test2',
      columns =>
      [
        id   => { type => 'serial', primary_key => 1 },
        num  => { type => 'int' }, # default is 123
        flag => { type => 'int', default => 2 },
        f2   => { type => 'int' },
      ],
    );

    package MyPgObject3;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg') }
    MyPgObject3->meta->setup
    (
      table   => 'rose_db_object_test3',
      columns =>
      [
        id   => { type => 'serial', primary_key => 1 },
        num  => { type => 'int' }, # default is 123
        flag => { type => 'int' }, # default is 1
        dt   => { type => 'timestamp' },
      ],
      default_insert_changes_only => 1,
    );
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
      $dbh->do('DROP TABLE rose_db_object_test3');
    }

    # MySQL 5.0.3 or later has a completely stupid "native" BIT type
    my $bit_col1 = 
      ($db_version >= 5_000_003) ?
        q(bitz  BIT(5) NOT NULL DEFAULT B'00101') :
        q(bitz  BIT(5) NOT NULL DEFAULT '00101');

    my $bit_col2 = 
      ($db_version >= 5_000_003) ?
        q(bitz2  BIT(2) NOT NULL DEFAULT B'00') :
        q(bitz2  BIT(2) NOT NULL DEFAULT '0');

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
  $bit_col1,
  $bit_col2,
  bitz3          BIT(4),
  decs           FLOAT(10,2),
  nums           VARCHAR(255),
  start          DATE,
  save           INT,
  enums          ENUM('foo', 'bar', 'baz') DEFAULT 'foo',
  ndate          DATE NOT NULL DEFAULT '0000-00-00',
  dur            VARCHAR(255) DEFAULT '2 months 5 days 3 seconds',
  epoch          INT DEFAULT 943997400,
  hiepoch        DECIMAL(16,6),
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
    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test3
(
  id     INT AUTO_INCREMENT PRIMARY KEY,
  num    INT DEFAULT 123,
  flag   INT DEFAULT 1
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyMySQLObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLObject->meta->allow_inline_column_values(1);

    MyMySQLObject->meta->default_update_changes_only(1);

    MyMySQLObject->meta->table('rose_db_object_test');

    MyMySQLObject->meta->columns
    (
      name     => { type => 'varchar', length => 32 },
      code     => { type => 'char', length => 6 },
      id       => { primary_key => 1, not_null => 1 },
      k1       => { type => 'int' },
      k2       => { type => 'int', lazy => 1 },
      k3       => { type => 'int' },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active', methods => [ qw(get_set get set) ] },
      start    => { type => 'date', default => '12/24/1980', lazy => 1 },
      ndate    => { type => 'date', not_null => 1, default => '0000-00-00' },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      enums    => { type => 'enum', values => [ qw(foo bar baz) ], default => 'foo' },
      bitz     => { type => 'bitfield', bits => 5, default => 101, alias => 'bits' },
      bitz2    => { type => 'bits', bits => 2, default => '0' },
      bitz3    => { type => 'bits', bits => 4 },
      decs     => { type => 'decimal', precision => 10, scale => 2 },
      dur      => { type => 'interval', scale => 6, default => '2 months 5 days 3 seconds' },
      epoch    => { type => 'epoch', default => '11/30/1999 9:30pm' },
      hiepoch  => { type => 'epoch hires', default => '1144004926.123456' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    eval { MyMySQLObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MyMySQLObject->meta->alias_column(save => 'save_col');

    eval { MyMySQLObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() no override');

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

    MyMPKMySQLObject->meta->default_update_changes_only(1);

    MyMPKMySQLObject->meta->table('rose_db_object_test2');

    MyMPKMySQLObject->meta->columns
    (
      k1          => { type => 'int', not_null => 1 },
      k2          => { type => 'int', not_null => 1 },
      name        => { type => 'varchar', length => 32 },
    );

    MyMPKMySQLObject->meta->primary_key_columns('k1', 'k2');

    my $i = 1;

    MyMPKMySQLObject->meta->setup
    (
      primary_key_generator => sub
      {
        my($meta, $db) = @_;

        my $k1 = $i++;
        my $k2 = $i++;

        return $k1, $k2;
      },
    );

    package MyMySQLObject3;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('mysql') }
    MyMySQLObject3->meta->setup
    (
      table   => 'rose_db_object_test3',
      columns =>
      [
        id   => { type => 'serial', primary_key => 1 },
        num  => { type => 'int' }, # default is 123
        flag => { type => 'int' }, # default is 1
      ],
      default_insert_changes_only => 1,
    );
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
  decs           DECIMAL(10,2),
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

    MyInformixObject->meta->allow_inline_column_values(1);

    MyInformixObject->meta->default_update_changes_only(1);

    MyInformixObject->meta->table('rose_db_object_test');

    MyInformixObject->meta->columns
    (
      name     => { type => 'varchar', length => 32, overflow => 'truncate' },
      code     => { type => 'char', length => 6, overflow => 'truncate' },
      id       => { type => 'serial', primary_key => 1, not_null => 1 },
      k1       => { type => 'int' },
      k2       => { type => 'int', lazy => 1 },
      k3       => { type => 'int' },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active', add_methods => [ qw(get set) ] },
      start    => { type => 'date', default => '12/24/1980', lazy => 1 },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      bitz     => { type => 'bitfield', bits => 5, default => 101, alias => 'bits' },
      decs     => { type => 'decimal', precision => 10, scale => 2 },
      names    => { type => 'set' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'datetime year to fraction(5)' },
    );

    eval { MyInformixObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MyInformixObject->meta->prepare_options({ix_CursorWithHold => 1});    

    MyInformixObject->meta->alias_column(save => 'save_col');

    eval { MyInformixObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() no override');

    MyInformixObject->meta->add_unique_key('save');
    MyInformixObject->meta->add_unique_key([ qw(k1 k2 k3) ]);

    MyInformixObject->meta->initialize(preserve_existing => 1);

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
      $dbh->do('DROP TABLE rose_db_object_test2');
      $dbh->do('DROP TABLE rose_db_object_test3');
      $dbh->do('DROP TABLE rose_db_object_test4');
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
  decs           DECIMAL(10,2),
  start          DATE,
  save           INT,
  nums           VARCHAR(255),
  nonmod         VARCHAR(255) DEFAULT 'defmod',
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

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test3
(
  id     INTEGER PRIMARY KEY AUTOINCREMENT,
  num    INT DEFAULT 123,
  flag   INT DEFAULT 1
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test4
(
  id INTEGER PRIMARY KEY
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MySQLiteObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteObject->meta->default_update_changes_only(1);

    MySQLiteObject->meta->table('rose_db_object_test');

    MySQLiteObject->meta->columns
    (
      name     => { type => 'varchar', length => 32, overflow => 'truncate' },
      code     => { type => 'char', length => 6, overflow => 'truncate' },
      id       => { primary_key => 1, not_null => 1 },
      k1       => { type => 'int' },
      k2       => { type => 'int', lazy => 1 },
      k3       => { type => 'int' },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active', add_methods => [ qw(get set) ] },
      start    => { type => 'date', default => '12/24/1980', lazy => 1 },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      nonmod   => { type => 'varchar', length => 255 },
      bitz     => { type => 'bitfield', bits => 5, default => 101, alias => 'bits' },
      decs     => { type => 'decimal', precision => 10, scale => 2 },
      #last_modified => { type => 'timestamp' },
      date_created  => { type => 'scalar' },
    );

    MySQLiteObject->meta->replace_column(date_created => { type => 'timestamp' });

    MySQLiteObject->meta->add_unique_key('save');

    MySQLiteObject->meta->add_unique_key([ qw(k1 k2 k3) ]);

    MySQLiteObject->meta->add_columns(
      Rose::DB::Object::Metadata::Column::Timestamp->new(
        name => 'last_modified'));

    MySQLiteObject->meta->column('id')->add_trigger(inflate => sub { defined $_[1] ? [ $_[1] ] : undef });
    MySQLiteObject->meta->column('id')->add_trigger(deflate => sub { ref $_[1] ? @{$_[1]}  : $_[1] });

    my $pre_inited = 0;
    MySQLiteObject->meta->pre_init_hook(sub { $pre_inited++ });

    eval { MySQLiteObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');
    Test::More::is($pre_inited, 1, 'meta->pre_init_hook()');

    MySQLiteObject->meta->alias_column(save => 'save_col');

    eval { MySQLiteObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() no override');

    MySQLiteObject->meta->initialize(preserve_existing => 1);

    Test::More::is(MySQLiteObject->meta->column('id')->is_primary_key_member, 1, 'is_primary_key_member - sqlite');
    Test::More::is(MySQLiteObject->meta->column('id')->primary_key_position, 1, 'primary_key_position 1 - sqlite');
    Test::More::ok(!defined MySQLiteObject->meta->column('k1')->primary_key_position, 'primary_key_position 2 - sqlite');
    MySQLiteObject->meta->column('k1')->primary_key_position(7);
    Test::More::ok(!defined MySQLiteObject->meta->column('k1')->primary_key_position, 'primary_key_position 3 - sqlite');

    package MyMPKSQLiteObject;

    use Rose::DB::Object;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MyMPKSQLiteObject->meta->default_update_changes_only(1);

    MyMPKSQLiteObject->meta->table('rose_db_object_test2');

    MyMPKSQLiteObject->meta->columns
    (
      k1          => { type => 'int', not_null => 1 },
      k2          => { type => 'int', not_null => 1 },
      name        => { type => 'varchar', length => 32 },
    );

    MyMPKSQLiteObject->meta->primary_key_columns('k1', 'k2');

    MyMPKSQLiteObject->meta->initialize;

    my $i = 1;

    MyMPKSQLiteObject->meta->primary_key_generator(sub
    {
      my($meta, $db) = @_;

      my $k1 = $i++;
      my $k2 = $i++;

      return $k1, $k2;
    });

    package MySQLiteObject3;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('sqlite') }
    MySQLiteObject3->meta->setup
    (
      table   => 'rose_db_object_test3',
      columns =>
      [
        id   => { type => 'serial', primary_key => 1 },
        num  => { type => 'int', smart_modification => 1 }, # default is 123
        flag => { type => 'int', default => 2 },
      ],
      default_insert_changes_only => 1,
      default_update_changes_only => 1,
    );

    package MySQLiteObject4;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('sqlite') }
    MySQLiteObject4->meta->setup
    (
      table   => 'rose_db_object_test4',
      columns =>
      [
        id   => { type => 'int', primary_key => 1 },
      ],
      default_insert_changes_only => 1,
      default_update_changes_only => 1,
    );
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
    $dbh->do('DROP TABLE rose_db_object_test2');
    $dbh->do('DROP TABLE rose_db_object_test3');
    $dbh->do('DROP TABLE rose_db_object_private.rose_db_object_test2');
    $dbh->do('DROP TABLE rose_db_object_private.rose_db_object_test3');
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
    $dbh->do('DROP TABLE rose_db_object_test3');

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
    $dbh->do('DROP TABLE rose_db_object_test2');
    $dbh->do('DROP TABLE rose_db_object_test3');
    $dbh->do('DROP TABLE rose_db_object_test4');

    $dbh->disconnect;
  }
}
