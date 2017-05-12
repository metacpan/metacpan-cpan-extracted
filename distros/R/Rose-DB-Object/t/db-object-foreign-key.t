#!/usr/bin/perl -w

use strict;

use Test::More tests => 199;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
}

our($PG_HAS_CHKPASS, $HAVE_PG, $HAVE_MYSQL, $HAVE_INFORMIX, $HAVE_SQLITE);

#
# PostgreSQL
#

SKIP: foreach my $db_type ('pg')
{
  skip("PostgreSQL tests", 60)  unless($HAVE_PG);

  Rose::DB->default_type($db_type);

  my $o = MyPgObject->new(name => 'John');

  ok(ref $o && $o->isa('MyPgObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);
  $o->other2_obj(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  is($o->other2_obj->name, 'def', "single column foreign key 1 - $db_type");

  my $old_fks = $o->fks;

  $o->other2_obj(undef);

  $o->fks(0);
  eval { $o->other2_obj };

  ok($@, "fatal referential_integrity - $db_type");
  ok(!defined $o->other2_obj_soft, "ok referential_integrity - $db_type");

  $o->fks($old_fks);

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

  $o2->other2_obj({ id => 3, name => 'foo' });

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->other2_obj->name, 'foo', "single column foreign key 2 - $db_type");
  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyPgObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyPgObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  $o->other2_obj(MyPgOtherObject2->new(name => 'bar'));
  $o->save;

  $o = MyPgObject->new(id => $o->id)->load;
  is($o->other2_obj->name, 'bar', "single column foreign key 3 - $db_type");

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
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  my $oo1 = MyPgOtherObject->new(k1 => 1, k2 => 2, k3 => 3, name => 'one');
  ok($oo1->save, 'other object save() 1');

  my $oo2 = MyPgOtherObject->new(k1 => 11, k2 => 12, k3 => 13, name => 'two');
  ok($oo2->save, 'other object save() 2');

  is($o->other_obj, undef, 'other_obj() 1');

  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);

  my $obj = $o->other_obj or warn "# ", $o->error, "\n";

  is(ref $obj, 'MyPgOtherObject', 'other_obj() 2');
  is($obj->name, 'one', 'other_obj() 3');
  is($obj->db, $o->db, 'share_db (default true)');

  $o->other_obj(undef);
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);

  $obj = $o->other_obj or warn "# ", $o->error, "\n";

  is(ref $obj, 'MyPgOtherObject', 'other_obj() 4');
  is($obj->name, 'two', 'other_obj() 5');

  $o->fk2(undef);  
  is($o->other_obj, undef, "key_column_triggers - $db_type");

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 34)  unless($HAVE_MYSQL);

  Rose::DB->default_type($db_type);

  my $o = MyMySQLObject->new(name => 'John');

  ok(ref $o && $o->isa('MyMySQLObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(22);
  $o->other2_obj(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  is($o->other2_obj->name, 'def', "single column foreign key 1 - $db_type");

  my $old_fks = $o->fks;
  $o->other2_obj(undef);
  $o->fks(0);
  eval { $o->other2_obj };

  ok($@, "fatal referential_integrity - $db_type");
  ok(!defined $o->other2_obj_soft, "ok referential_integrity - $db_type");

  $o->fks($old_fks);

  my $o2 = MyMySQLObject->new(id => $o->id);

  ok(ref $o2 && $o2->isa('MyMySQLObject'), "new() 2 - $db_type");

  is($o2->bits->to_Bin, '00101', "bits() (bitfield default value) - $db_type");

  ok($o2->load(with => [ 'other_obj' ]), "load() 2 - $db_type");
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

  $o2->other2_obj({ id => 3, name => 'foo' });

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');

  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->other2_obj->name, 'foo', "single column foreign key 2 - $db_type");
  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");
  is($o2->bits->to_Bin, '00101', "load() verify 10 (bitfield value) - $db_type");

  my $o3 = MyMySQLObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyMySQLObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  $o->other2_obj(MyMySQLOtherObject2->new(name => 'bar'));
  $o->save;

  $o = MyMySQLObject->new(id => $o->id)->load;
  is($o->other2_obj->name, 'bar', "single column foreign key 3 - $db_type");

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');
}

#
# Informix
#

SKIP: foreach my $db_type ('informix')
{
  skip("Informix tests", 51)  unless($HAVE_INFORMIX);

  Rose::DB->default_type($db_type);

  my $o = MyInformixObject->new(name => 'John', id => 1);

  ok(ref $o && $o->isa('MyInformixObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);
  $o->other2_obj(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  is($o->other2_obj->name, 'def', "single column foreign key 1 - $db_type");

  my $old_fks = $o->fks;
  $o->other2_obj(undef);
  $o->fks(0);
  eval { $o->other2_obj };

  ok($@, "fatal referential_integrity - $db_type");
  ok(!defined $o->other2_obj_soft, "ok referential_integrity - $db_type");

  $o->fks($old_fks);

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

  $o2->other2_obj({ id => 3, name => 'foo' });

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->other2_obj->name, 'foo', "single column foreign key 2 - $db_type");
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

  $o->other2_obj(MyInformixOtherObject2->new(name => 'bar'));
  $o->save;

  $o = MyInformixObject->new(id => $o->id)->load;
  is($o->other2_obj->name, 'bar', "single column foreign key 3 - $db_type");

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
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  my $oo1 = MyInformixOtherObject->new(k1 => 1, k2 => 2, k3 => 3, name => 'one');
  ok($oo1->save, 'other object save() 1');

  my $oo2 = MyInformixOtherObject->new(k1 => 11, k2 => 12, k3 => 13, name => 'two');
  ok($oo2->save, 'other object save() 2');

  is($o->other_obj, undef, 'other_obj() 1');

  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);

  my $obj = $o->other_obj or warn "# ", $o->error, "\n";

  is(ref $obj, 'MyInformixOtherObject', 'other_obj() 2');
  is($obj->name, 'one', 'other_obj() 3');

  $o->other_obj(undef);
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);

  $obj = $o->other_obj or warn "# ", $o->error, "\n";

  is(ref $obj, 'MyInformixOtherObject', 'other_obj() 4');
  is($obj->name, 'two', 'other_obj() 5');

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');
}

#
# SQLite
#

SKIP: foreach my $db_type ('sqlite')
{
  skip("SQLite tests", 53)  unless($HAVE_SQLITE);

  Rose::DB->default_type($db_type);

  is(MySQLiteObject->meta->foreign_key('other_obj')->key_column('fk1'), 'k1', "key_column 1 - $db_type");
  is(MySQLiteObject->meta->foreign_key('other_obj')->key_column('fk2'), 'k2', "key_column 2 - $db_type");

  my $o = MySQLiteObject->new(name => 'John', id => 1);

  ok(ref $o && $o->isa('MySQLiteObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);
  $o->other2_obj(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  is($o->other2_obj->name, 'def', "single column foreign key 1 - $db_type");

  my $old_fks = $o->fks;
  $o->other2_obj(undef);
  $o->fks(0);
  eval { $o->other2_obj };

  ok($@, "fatal referential_integrity - $db_type");
  ok(!defined $o->other2_obj_soft, "ok referential_integrity - $db_type");

  $o->fks($old_fks);

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

  $o2->other2_obj({ id => 3, name => 'foo' });

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->other2_obj->name, 'foo', "single column foreign key 2 - $db_type");
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

  $o->other2_obj(MySQLiteOtherObject2->new(name => 'bar'));
  $o->save;

  $o = MySQLiteObject->new(id => $o->id)->load;
  is($o->other2_obj->name, 'bar', "single column foreign key 3 - $db_type");

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
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  my $oo1 = MySQLiteOtherObject->new(k1 => 1, k2 => 2, k3 => 3, name => 'one');
  ok($oo1->save, 'other object save() 1');

  my $oo2 = MySQLiteOtherObject->new(k1 => 11, k2 => 12, k3 => 13, name => 'two');
  ok($oo2->save, 'other object save() 2');

  is($o->other_obj, undef, 'other_obj() 1');

  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);

  my $obj = $o->other_obj or warn "# ", $o->error, "\n";

  is(ref $obj, 'MySQLiteOtherObject', 'other_obj() 2');
  is($obj->name, 'one', 'other_obj() 3');

  $o->other_obj(undef);
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);

  $obj = $o->other_obj or warn "# ", $o->error, "\n";

  is(ref $obj, 'MySQLiteOtherObject', 'other_obj() 4');
  is($obj->name, 'two', 'other_obj() 5');

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');
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
      $dbh->do('DROP TABLE rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE rose_db_object_other');
      $dbh->do('DROP TABLE rose_db_object_other2');
      $dbh->do('DROP TABLE rose_db_object_chkpass_test');
    }

    our $PG_HAS_CHKPASS = pg_has_chkpass();

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other
(
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32),

  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other2
(
  id    SERIAL PRIMARY KEY,
  name  VARCHAR(32) DEFAULT 'def'
)
EOF

    # Create test foreign subclasses

    package MyPgOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('pg') }

    MyPgOtherObject->meta->table('rose_db_object_other');

    MyPgOtherObject->meta->columns
    (
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int' },
      k3   => { type => 'int' },
    );

    MyPgOtherObject->meta->primary_key_columns([ qw(k1 k2 k3) ]);

    MyPgOtherObject->meta->initialize;

    package MyPgOtherObject2;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyPgOtherObject2->meta->table('rose_db_object_other2');

    MyPgOtherObject2->meta->columns
    (
      id   => { primary_key => 1 },
      name => { type => 'varchar', default => 'def' },
    );

    MyPgOtherObject2->meta->initialize;

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
  fk1            INT,
  fk2            INT,
  fk3            INT,
  fks            INT REFERENCES rose_db_object_other2 (id),
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyPgObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('pg') }

    MyPgObject->meta->table('rose_db_object_test');

    MyPgObject->meta->columns
    (
      'name',
      id       => { primary_key => 1, type => 'serial' },
      ($PG_HAS_CHKPASS ? (password => { type => 'chkpass' }) : ()),
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active' },
      start    => { type => 'date', default => '12/24/1980' },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      bits     => { type => 'bitfield', bits => 5, default => 101 },
      fk1      => { type => 'int' },
      fk2      => { type => 'int' },
      fk3      => { type => 'int' },
      fks      => { type => 'int' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    MyPgObject->meta->foreign_keys
    (
      other_obj =>
      {
        class => 'MyPgOtherObject',
        key_columns =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        with_column_triggers => 1,
      },

      other2_obj =>
      {
        class => 'MyPgOtherObject2',
        key_columns =>
        {
          fks => 'id',
        },
        with_column_triggers => 1,
      },

      other2_obj_soft =>
      {
        class => 'MyPgOtherObject2',
        key_columns =>
        {
          fks => 'id',
        },
        referential_integrity => 0,
        with_column_triggers => 1,
      },
    );

    MyPgObject->meta->alias_column(fk1 => 'fkone');

    eval { MyPgObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MyPgObject->meta->alias_column(save => 'save_col');
    MyPgObject->meta->initialize(preserve_existing => 1);
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
      $dbh->do('DROP TABLE rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE rose_db_object_other');
      $dbh->do('DROP TABLE rose_db_object_other2');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other
(
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32),

  KEY(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other2
(
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(32) DEFAULT 'def'
)
EOF

    # Create test foreign subclasses

    package MyMySQLOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLOtherObject->meta->table('rose_db_object_other');

    MyMySQLOtherObject->meta->columns
    (
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int' },
      k3   => { type => 'int' },
    );

    MyMySQLOtherObject->meta->primary_key_columns([ qw(k1 k2 k3) ]);

    MyMySQLOtherObject->meta->initialize;

    package MyMySQLOtherObject2;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLOtherObject2->meta->table('rose_db_object_other2');

    MyMySQLOtherObject2->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', default => 'def' },
    );

    MyMySQLOtherObject2->meta->initialize;

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
  fk1            INT,
  fk2            INT,
  fk3            INT,
  fks            INT REFERENCES rose_db_object_other2 (id),
  last_modified  TIMESTAMP,
  date_created   DATETIME
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyMySQLObject;

    our @ISA = qw(Rose::DB::Object);

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
      fk1      => { type => 'int' },
      fk2      => { type => 'int' },
      fk3      => { type => 'int' },
      fks      => { type => 'int' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'datetime' },
    );

    MyMySQLObject->meta->foreign_keys
    (
      other_obj =>
      {
        class => 'MyMySQLOtherObject',
        key_columns =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        }
      },

      other2_obj =>
      {
        class => 'MyMySQLOtherObject2',
        key_columns =>
        {
          fks => 'id',
        },
      },

      other2_obj_soft =>
      {
        class => 'MyMySQLOtherObject2',
        key_columns =>
        {
          fks => 'id',
        },
        soft => 1,
      },
    );

    eval { MyMySQLObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MyMySQLObject->meta->alias_column(save => 'save_col');
    MyMySQLObject->meta->initialize(preserve_existing => 1);
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
      $dbh->do('DROP TABLE rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE rose_db_object_other');
      $dbh->do('DROP TABLE rose_db_object_other2');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other
(
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32),

  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other2
(
  id    SERIAL PRIMARY KEY,
  name  VARCHAR(32) DEFAULT 'def'
)
EOF

    # Create test foreign subclasses

    package MyInformixOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('informix') }

    MyInformixOtherObject->meta->table('rose_db_object_other');

    MyInformixOtherObject->meta->columns
    (
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int' },
      k3   => { type => 'int' },
    );

    MyInformixOtherObject->meta->primary_key_columns(qw(k1 k2 k3));

    MyInformixOtherObject->meta->initialize;

    package MyInformixOtherObject2;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('informix') }

    MyInformixOtherObject2->meta->table('rose_db_object_other2');

    MyInformixOtherObject2->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', default => 'def' },
    );

    MyInformixOtherObject2->meta->initialize;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INT NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           VARCHAR(5) DEFAULT '00101' NOT NULL,
  start          DATE,
  save           INT,
  nums           VARCHAR(255),
  fk1            INT,
  fk2            INT,
  fk3            INT,
  fks            INT REFERENCES rose_db_object_other2 (id),
  last_modified  DATETIME YEAR TO FRACTION(5),
  date_created   DATETIME YEAR TO FRACTION(5),

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyInformixObject;

    our @ISA = qw(Rose::DB::Object);

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
      fk1      => { type => 'int' },
      fk2      => { type => 'int' },
      fk3      => { type => 'int' },
      fks      => { type => 'int' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    MyInformixObject->meta->foreign_keys
    (
      other_obj =>
      {
        class => 'MyInformixOtherObject',
        key_columns =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        }
      },

      other2_obj =>
      {
        class => 'MyInformixOtherObject2',
        key_columns =>
        {
          fks => 'id',
        },
      },

      other2_obj_soft =>
      {
        class => 'MyInformixOtherObject2',
        key_columns =>
        {
          fks => 'id',
        },
        referential_integrity => 0,
      },
    );

    MyInformixObject->meta->alias_column(fk1 => 'fkone');

    eval { MyInformixObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MyInformixObject->meta->alias_column(save => 'save_col');
    MyInformixObject->meta->initialize(preserve_existing => 1);
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
      $dbh->do('DROP TABLE rose_db_object_other');
      $dbh->do('DROP TABLE rose_db_object_other2');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other
(
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32),

  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other2
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(32) DEFAULT 'def'
)
EOF

    # Create test foreign subclasses

    package MySQLiteOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteOtherObject->meta->table('rose_db_object_other');

    MySQLiteOtherObject->meta->columns
    (
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int' },
      k3   => { type => 'int' },
    );

    MySQLiteOtherObject->meta->primary_key_columns(qw(k1 k2 k3));

    MySQLiteOtherObject->meta->initialize;

    package MySQLiteOtherObject2;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteOtherObject2->meta->table('rose_db_object_other2');

    MySQLiteOtherObject2->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', default => 'def' },
    );

    MySQLiteOtherObject2->meta->initialize;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           VARCHAR(5) DEFAULT '00101' NOT NULL,
  start          DATE,
  save           INT,
  nums           VARCHAR(255),
  fk1            INT,
  fk2            INT,
  fk3            INT,
  fks            INT REFERENCES rose_db_object_other2 (id),
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MySQLiteObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteObject->meta->table('rose_db_object_test');

    MySQLiteObject->meta->columns
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
      fk1      => { type => 'int' },
      fk2      => { type => 'int' },
      fk3      => { type => 'int' },
      fks      => { type => 'int' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    MySQLiteObject->meta->foreign_keys
    (
      other_obj =>
      {
        class => 'MySQLiteOtherObject',
        key_columns =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        }
      },

      other2_obj =>
      {
        class => 'MySQLiteOtherObject2',
        key_columns =>
        {
          fks => 'id',
        },
      },

      other2_obj_soft =>
      {
        class => 'MySQLiteOtherObject2',
        key_columns =>
        {
          fks => 'id',
        },
        soft => 1,
      },
    );

    MySQLiteObject->meta->alias_column(fk1 => 'fkone');

    eval { MySQLiteObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MySQLiteObject->meta->alias_column(save => 'save_col');
    MySQLiteObject->meta->initialize(preserve_existing => 1);
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

    $dbh->do('DROP TABLE rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE rose_db_object_other');
    $dbh->do('DROP TABLE rose_db_object_other2');

    $dbh->disconnect;
  }

  if($HAVE_MYSQL)
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE rose_db_object_other');
    $dbh->do('DROP TABLE rose_db_object_other2');

    $dbh->disconnect;
  }

  if($HAVE_INFORMIX)
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE rose_db_object_other');
    $dbh->do('DROP TABLE rose_db_object_other2');

    $dbh->disconnect;
  }

  if($HAVE_SQLITE)
  {
    # SQLite
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->do('DROP TABLE rose_db_object_other');
    $dbh->do('DROP TABLE rose_db_object_other2');

    $dbh->disconnect;
  }
}
