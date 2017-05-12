#!/usr/bin/perl -w

use strict;

use Test::More tests => 1604;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Manager');
}

our($PG_HAS_CHKPASS, $HAVE_PG, $HAVE_MYSQL, $HAVE_INFORMIX, $HAVE_SQLITE);


use FindBin qw($Bin);

eval { require "$Bin/map-record-name-conflict.pl" };

ok($@ =~ /^\QAlready made a map record method named map_record in class JCS::B on behalf of the relationship 'bs' in class JCS::A.  Please choose another name for the map record method for the relationship named 'bs' in JCS::C.\E/,
   'many-to-many map record name conflict');

#
# PostgreSQL
#

SKIP: foreach my $db_type ('pg')
{
  skip("PostgreSQL tests", 398)  unless($HAVE_PG);

  Rose::DB->default_type($db_type);

  my $o = MyPgObject->new(name => 'John');

  ok(ref $o && $o->isa('MyPgObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  my $o_x = MyPgObject->new(id => 99, name => 'John X', flag => 0);
  $o_x->save;

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
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
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
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  my $oo1 = MyPgOtherObject->new(k1 => 1, k2 => 2, k3 => 3, name => 'one');
  ok($oo1->save, "other object save() 1 - $db_type");

  my $oo2 = MyPgOtherObject->new(k1 => 11, k2 => 12, k3 => 13, name => 'two');
  ok($oo2->save, "other object save() 2 - $db_type");

  is($o->other_obj, undef, "other_obj() 1 - $db_type");

  $o->fkone(99);
  $o->fk2(99);
  $o->fk3(99);

  eval { $o->other_obj };
  ok($@, "fatal referential_integrity - $db_type");
  ok(!defined $o->other_obj_osoft, "ok referential_integrity 1 - $db_type");
  ok(!defined $o->other_obj_msoft, "ok referential_integrity 2 - $db_type");

  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);

  my $obj = $o->other_obj or warn "# ", $o->error, "\n";

  is(ref $obj, 'MyPgOtherObject', "other_obj() 2 - $db_type");
  is($obj->name, 'one', "other_obj() 3 - $db_type");
  is($obj->db, $o->db, "share_db (default true) - $db_type");

  $o->other_obj(undef);
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);

  ok(!$o->has_loaded_related('other_obj'), "has_loaded_related() 1 - $db_type");

  $obj = $o->other_obj or warn "# ", $o->error, "\n";

  ok($o->has_loaded_related('other_obj'), "has_loaded_related() 2 - $db_type");

  $o->forget_related('other_obj');
  ok(!$o->has_loaded_related('other_obj'), "forget_related() 1 - $db_type");

  $obj = $o->other_obj or warn "# ", $o->error, "\n";
  ok($o->has_loaded_related('other_obj'), "forget_related() 2 - $db_type");

  eval { $o->forget_related(foreign_key => 'other_obj_nonesuch') };
  ok($@, "forget_related() 3 - $db_type");
  $o->forget_related(relationship => 'other_obj');
  ok(!$o->has_loaded_related('other_obj'), "forget_related() 4 - $db_type");

  $obj = $o->other_obj or warn "# ", $o->error, "\n";

  is(ref $obj, 'MyPgOtherObject', "other_obj() 4 - $db_type");
  is($obj->name, 'two', "other_obj() 5 - $db_type");

  my $oo21 = MyPgOtherObject2->new(id => 1, name => 'one', pid => $o->id);
  ok($oo21->save, "other object 2 save() 1 - $db_type");

  my $oo22 = MyPgOtherObject2->new(id => 2, name => 'two', pid => $o->id);
  ok($oo22->save, "other object 2 save() 2 - $db_type");

  my $oo23 = MyPgOtherObject2->new(id => 3, name => 'three', pid => $o_x->id);
  ok($oo23->save, "other object 2 save() 3 - $db_type");

  # Begin filtered collection tests

  my $x = MyPgObject->new(id => $o->id)->load;
  $x->other2_a_objs({ id => 100, name => 'aoo' }, { id => 101, name => 'abc' });

  $x->save;

  $x = MyPgObject->new(id => $o->id)->load;

  my $ao = $x->other2_a_objs;
  my $oo = $x->other2_objs;

  is(scalar @$ao, 2, "filtered one-to-many 1 - $db_type");
  is(join(',', map { $_->name } @$ao), 'abc,aoo', "filtered one-to-many 2 - $db_type");

  is(scalar @$oo, 4, "filtered one-to-many 3 - $db_type");
  is(join(',', sort map { $_->name } @$oo), 'abc,aoo,one,two', "filtered one-to-many 4 - $db_type");

  $x->other2_a_objs({ id => 102, name => 'axx' });
  $x->save;

  $x = MyPgObject->new(id => $o->id)->load;

  $ao = $x->other2_a_objs;
  $oo = $x->other2_objs;

  is(scalar @$ao, 1, "filtered one-to-many 5 - $db_type");
  is(join(',', map { $_->name } @$ao), 'axx', "filtered one-to-many 6 - $db_type");

  is(scalar @$oo, 3, "filtered one-to-many 7 - $db_type");
  is(join(',', sort map { $_->name } @$oo), 'axx,one,two', "filtered one-to-many 8 - $db_type");

  $x->other2_a_objs([]);
  $x->save;

  # End filtered collection tests

  ok(!$o->has_loaded_related('other2_objs'), "has_loaded_related() 3 - $db_type");

  my $o2s = $o->other2_objs;

  ok($o->has_loaded_related('other2_objs'), "has_loaded_related() 4 - $db_type");

  ok(ref $o2s eq 'ARRAY' && @$o2s == 2 && 
     $o2s->[0]->name eq 'two' && $o2s->[1]->name eq 'one',
     'other objects 1');

  my @o2s = $o->other2_objs;

  ok(@o2s == 2 && $o2s[0]->name eq 'two' && $o2s[1]->name eq 'one',
     'other objects 2');

  my $color = MyPgColor->new(id => 1, name => 'red');
  ok($color->save, "save color 1 - $db_type");

  $color = MyPgColor->new(id => 2, name => 'green');
  ok($color->save, "save color 2 - $db_type");

  $color = MyPgColor->new(id => 3, name => 'blue');
  ok($color->save, "save color 3 - $db_type");

  $color = MyPgColor->new(id => 4, name => 'pink');
  ok($color->save, "save color 4 - $db_type");

  my $map1 = MyPgColorMap->new(obj_id => 1, color_id => 1);
  ok($map1->save, "save color map record 1 - $db_type");

  my $map2 = MyPgColorMap->new(obj_id => 1, color_id => 3);
  ok($map2->save, "save color map record 2 - $db_type");

  my $map3 = MyPgColorMap->new(obj_id => 99, color_id => 4);
  ok($map3->save, "save color map record 3 - $db_type");

  my $colors = $o->colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'red',
     "colors 1 - $db_type");

  $colors = $o->find_colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'red',
     "find colors 1 - $db_type");

  $colors = $o->find_colors([ name => { like => 'r%' } ]);

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'red',
     "find colors 2 - $db_type");

  $colors = $o->find_colors(query => [ name => { like => 'r%' } ], cache => 1);

  my $colors2 = $o->find_colors(from_cache => 1);

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'red' &&
     ref $colors2 eq 'ARRAY' && @$colors2 == 1 && $colors2->[0]->name eq 'red' &&
     $colors->[0] eq $colors2->[0],
     "find colors from cache - $db_type");

  my $count = $o->colors_count;

  is($count, 2, "count colors 1 - $db_type");

  $count = $o->colors_count([ name => { like => 'r%' } ]);

  is($count, 1, "count colors 2 - $db_type");

  my @colors = $o->colors;

  ok(@colors == 2 && $colors[0]->name eq 'blue' && $colors[1]->name eq 'red',
     "colors 2 - $db_type");

  $colors = $o_x->colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'pink',
     "colors 3 - $db_type");

  @colors = $o_x->colors;

  ok(@colors == 1 && $colors[0]->name eq 'pink', "colors 4 - $db_type");

  $o = MyPgObject->new(id => 1)->load;
  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);
  $o->save;

  #local $Rose::DB::Object::Manager::Debug = 1;

  eval
  {
    local $o->dbh->{'PrintError'} = 0;
    $o->delete(cascade => 'null');
  };

  ok($@, "delete cascade null 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyPgOtherObject');

  is($count, 2, "delete cascade rollback confirm 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyPgOtherObject2');

  is($count, 3, "delete cascade rollback confirm 2 - $db_type");

  ok($o->delete(cascade => 'delete'), "delete cascade delete 1 - $db_type");

  $o = MyPgObject->new(id => 99)->load;
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);
  $o->save;

  eval
  {
    local $o->dbh->{'PrintError'} = 0;
    $o->delete(cascade => 'null');
  };

  ok($@, "delete cascade null 2 - $db_type");

  ok($o->delete(cascade => 'delete'), "delete cascade delete 2 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyPgColorMap');

  is($count, 0, "delete cascade confirm 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyPgOtherObject2');

  is($count, 0, "delete cascade confirm 2 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyPgOtherObject');

  is($count, 0, "delete cascade confirm 3 - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # Start foreign key method tests

  #
  # Foreign key get_set_now
  #

  $o = MyPgObject->new(id   => 50,
                       name => 'Alex',
                       flag => 1);

  eval { $o->other_obj('abc') };
  ok($@, "set foreign key object: one arg - $db_type");

  eval { $o->other_obj(k1 => 1, k2 => 2, k3 => 3) };
  ok($@, "set foreign key object: no save - $db_type");

  $o->save;

  eval
  {
    local $o->db->dbh->{'PrintError'} = 0;
    $o->other_obj(k1 => 1, k2 => 2);
  };

  ok($@, "set foreign key object: too few keys - $db_type");

  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "set foreign key object 1 - $db_type");
  ok($o->fkone == 1 && $o->fk2 == 2 && $o->fk3 == 3, "set foreign key object check keys 1 - $db_type");

  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "set foreign key object 2 - $db_type");
  ok($o->fkone == 1 && $o->fk2 == 2 && $o->fk3 == 3, "set foreign key object check keys 2 - $db_type");

  #
  # Foreign key delete_now
  #

  ok($o->delete_other_obj, "delete foreign key object 1 - $db_type");

  ok(!defined $o->fkone && !defined $o->fk2 && !defined $o->fk3, "delete foreign key object check keys 1 - $db_type");

  ok(!defined $o->other_obj && defined $o->error, "delete foreign key object confirm 1 - $db_type");

  ok(!defined $o->delete_other_obj, "delete foreign key object 2 - $db_type");

  #
  # Foreign key get_set_on_save
  #

  # TEST: Set, save
  $o = MyPgObject->new(id   => 100,
                       name => 'Bub',
                       flag => 1);

  ok($o->other_obj_on_save(k1 => 21, k2 => 22, k3 => 23), "set foreign key object on save 1 - $db_type");

  my $co = MyPgObject->new(id => 100);
  ok(!$co->load(speculative => 1), "set foreign key object on save 2 - $db_type");

  my $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 21 && $other_obj->k2 == 22 && $other_obj->k3 == 23,
     "set foreign key object on save 3 - $db_type");

  ok($o->save, "set foreign key object on save 4 - $db_type");

  $o = MyPgObject->new(id => 100);

  $o->load;

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj && $other_obj->k1 == 21 && $other_obj->k2 == 22 && $other_obj->k3 == 23,
     "set foreign key object on save 5 - $db_type");

  # TEST: Set, set to undef, save
  $o = MyPgObject->new(id   => 200,
                       name => 'Rose',
                       flag => 1);

  ok($o->other_obj_on_save(k1 => 51, k2 => 52, k3 => 53), "set foreign key object on save 6 - $db_type");

  $co = MyPgObject->new(id => 200);
  ok(!$co->load(speculative => 1), "set foreign key object on save 7 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 51 && $other_obj->k2 == 52 && $other_obj->k3 == 53,
     "set foreign key object on save 8 - $db_type");

  $o->other_obj_on_save(undef);

  ok($o->save, "set foreign key object on save 9 - $db_type");

  $o = MyPgObject->new(id => 200);

  $o->load;

  ok(!defined $o->other_obj_on_save, "set foreign key object on save 10 - $db_type");

  $co = MyPgOtherObject->new(k1 => 51, k2 => 52, k3 => 53);
  ok(!$co->load(speculative => 1), "set foreign key object on save 11 - $db_type");

  $o->delete(cascade => 1);

  # TEST: Set, delete, save
  $o = MyPgObject->new(id   => 200,
                       name => 'Rose',
                       flag => 1);

  ok($o->other_obj_on_save(k1 => 51, k2 => 52, k3 => 53), "set foreign key object on save 12 - $db_type");

  $co = MyPgObject->new(id => 200);
  ok(!$co->load(speculative => 1), "set foreign key object on save 13 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 51 && $other_obj->k2 == 52 && $other_obj->k3 == 53,
     "set foreign key object on save 14 - $db_type");

  ok($o->delete_other_obj, "set foreign key object on save 15 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "set foreign key object on save 16 - $db_type");

  ok($o->save, "set foreign key object on save 17 - $db_type");

  $o = MyPgObject->new(id => 200);

  $o->load;

  ok(!defined $o->other_obj_on_save, "set foreign key object on save 18 - $db_type");

  $co = MyPgOtherObject->new(k1 => 51, k2 => 52, k3 => 53);
  ok(!$co->load(speculative => 1), "set foreign key object on save 19 - $db_type");

  $o->delete(cascade => 1);

  #
  # Foreign key delete_on_save
  #

  $o = MyPgObject->new(id   => 500,
                       name => 'Kip',
                       flag => 1);

  $o->other_obj_on_save(k1 => 7, k2 => 8, k3 => 9);
  $o->save;

  $o = MyPgObject->new(id => 500);
  $o->load;

  # TEST: Delete, save
  $o->del_other_obj_on_save;

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete foreign key object on save 1 - $db_type");

  # ...but that the foreign object has not yet been deleted
  $co = MyPgOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok($co->load(speculative => 1), "delete foreign key object on save 2 - $db_type");

  # Do the save
  ok($o->save, "delete foreign key object on save 3 - $db_type");

  # Now it's deleted
  $co = MyPgOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok(!$co->load(speculative => 1), "delete foreign key object on save 4 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete foreign key object on save 5 - $db_type");

  # RESET
  $o->delete;

  $o = MyPgObject->new(id   => 700,
                       name => 'Ham',
                       flag => 0);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MyPgObject->new(id => 700);
  $o->load;

  # TEST: Delete, set on save, delete, save
  ok($o->del_other_obj_on_save, "delete 2 foreign key object on save 1 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete 2 foreign key object on save 2 - $db_type");

  # ...but that the foreign object has not yet been deleted
  $co = MyPgOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 3 - $db_type");

  # Set on save
  $o->other_obj_on_save(k1 => 44, k2 => 55, k3 => 66);

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are set...
  ok($other_obj &&  $other_obj->k1 == 44 && $other_obj->k2 == 55 && $other_obj->k3 == 66,
     "delete 2 foreign key object on save 4 - $db_type");

  # ...and that the foreign object has not yet been saved
  $co = MyPgOtherObject->new(k1 => 44, k2 => 55, k3 => 66);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 5 - $db_type");

  # Delete again
  ok($o->del_other_obj_on_save, "delete 2 foreign key object on save 6 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete 2 foreign key object on save 7 - $db_type");

  # Confirm that the foreign objects have not been saved
  $co = MyPgOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 8 - $db_type");
  $co = MyPgOtherObject->new(k1 => 44, k2 => 55, k3 => 66);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 9 - $db_type");

  # RESET
  $o->delete;

  $o = MyPgObject->new(id   => 800,
                       name => 'Lee',
                       flag => 1);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MyPgObject->new(id => 800);
  $o->load;

  # TEST: Set & save, delete on save, set on save, delete on save, save
  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "delete 3 foreign key object on save 1 - $db_type");

  # Confirm that both foreign objects are in the db
  $co = MyPgOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 2 - $db_type");
  $co = MyPgOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 3 - $db_type");

  # Delete on save
  $o->del_other_obj_on_save;

  # Set-on-save to old value
  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);

  # Delete on save
  $o->del_other_obj_on_save;  

  # Save
  $o->save;

  # Confirm that both foreign objects have been deleted
  $co = MyPgOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok(!$co->load(speculative => 1), "delete 3 foreign key object on save 4 - $db_type");
  $co = MyPgOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok(!$co->load(speculative => 1), "delete 3 foreign key object on save 5 - $db_type");

  # RESET
  $o->delete;

  $o = MyPgObject->new(id   => 900,
                       name => 'Kai',
                       flag => 1);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MyPgObject->new(id => 900);
  $o->load;

  # TEST: Delete on save, set on save, delete on save, set to same one, save
  $o->del_other_obj_on_save;

  # Set on save
  ok($o->other_obj_on_save(k1 => 1, k2 => 2, k3 => 3), "delete 4 foreign key object on save 1 - $db_type");

  # Delete on save
  $o->del_other_obj_on_save;

  # Set-on-save to previous value
  $o->other_obj_on_save(k1 => 1, k2 => 2, k3 => 3);

  # Save
  $o->save;

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are set...
  ok($other_obj &&  $other_obj->k1 == 1 && $other_obj->k2 == 2 && $other_obj->k3 == 3,
     "delete 4 foreign key object on save 2 - $db_type");

  # Confirm that the new foreign object is there and the old one is not
  $co = MyPgOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok($co->load(speculative => 1), "delete 4 foreign key object on save 3 - $db_type");
  $co = MyPgOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok(!$co->load(speculative => 1), "delete 4 foreign key object on save 4 - $db_type");

  # End foreign key method tests

  # Start "one to many" method tests

  #
  # "one to many" get_set_now
  #

  # SETUP
  $o = MyPgObject->new(id   => 111,
                       name => 'Boo',
                       flag => 1);

  MyPgOtherObject2->new(id => 1, name => 'one', pid => 900)->save;

  @o2s = 
  (
    1,
    MyPgOtherObject2->new(id => 2, name => 'two'),
    { id => 3, name => 'three', pid => 111 },
  );

  # Set before save, save, set
  eval { $o->other2_objs_now(@o2s) };
  ok($@, "set one to many now 1 - $db_type");

  $o->save;

  ok($o->other2_objs_now(@o2s), "set one to many now 2 - $db_type");

  @o2s = $o->other2_objs_now;
  ok(@o2s == 3, "set one to many now 3 - $db_type");

  ok($o2s[0]->id == 2 && $o2s[0]->pid == 111, "set one to many now 4 - $db_type");
  ok($o2s[1]->id == 3 && $o2s[1]->pid == 111, "set one to many now 5 - $db_type");
  ok($o2s[2]->id == 1 && $o2s[2]->pid == 111, "set one to many now 6 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 7 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 2)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 8 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 3)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 9 - $db_type");

  my $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 111');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set one to many now 10 - $db_type");

  # Set to undef
  $o->other2_objs_now(undef);

  @o2s = $o->other2_objs_now;
  ok(@o2s == 3, "set one to many now 11 - $db_type");

  ok($o2s[0]->id == 2 && $o2s[0]->pid == 111, "set one to many now 12 - $db_type");
  ok($o2s[1]->id == 3 && $o2s[1]->pid == 111, "set one to many now 13 - $db_type");
  ok($o2s[2]->id == 1 && $o2s[2]->pid == 111, "set one to many now 14 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 15 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 2)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 16 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 3)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 17 - $db_type");

  # RESET
  $o = MyPgObject->new(id => 111)->load;

  # Set (one existing, one new)
  @o2s = 
  (
    MyPgOtherObject2->new(id => 1, name => 'one'),
    MyPgOtherObject2->new(id => 7, name => 'seven'),
  );

  ok($o->other2_objs_now(\@o2s), "set 2 one to many now 1 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many now 2 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many now 3 - $db_type");

  @o2s = $o->other2_objs_now;
  ok(@o2s == 2, "set 2 one to many now 4 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 111, "set 2 one to many now 5 - $db_type");
  ok($o2s[1]->id == 1 && $o2s[1]->pid == 111, "set 2 one to many now 6 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 111');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 2, "set 2 one to many now 7 - $db_type");

  #
  # "one to many" get_set_on_save
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MyPgObject->new(id   => 222,
                       name => 'Hap',
                       flag => 1);

  @o2s = 
  (
    MyPgOtherObject2->new(id => 5, name => 'five'),
    MyPgOtherObject2->new(id => 6, name => 'six'),
    MyPgOtherObject2->new(id => 7, name => 'seven'),
  );

  $o->other2_objs_on_save(@o2s);

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 3, "set one to many on save 1 - $db_type");

  ok($o2s[0]->id == 5 && $o2s[0]->pid == 222, "set one to many on save 2 - $db_type");
  ok($o2s[1]->id == 6 && $o2s[1]->pid == 222, "set one to many on save 3 - $db_type");
  ok($o2s[2]->id == 7 && $o2s[2]->pid == 222, "set one to many on save 4 - $db_type");

  ok(!MyPgOtherObject2->new(id => 5)->load(speculative => 1), "set one to many on save 5 - $db_type");
  ok(!MyPgOtherObject2->new(id => 6)->load(speculative => 1), "set one to many on save 6 - $db_type");
  ok(!MyPgOtherObject2->new(id => 7)->load(speculative => 1), "set one to many on save 7 - $db_type");

  $o->save;

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 3, "set one to many on save 8 - $db_type");

  ok($o2s[0]->id == 6 && $o2s[0]->pid == 222, "set one to many on save 9 - $db_type");
  ok($o2s[1]->id == 7 && $o2s[1]->pid == 222, "set one to many on save 10 - $db_type");
  ok($o2s[2]->id == 5 && $o2s[2]->pid == 222, "set one to many on save 11 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 5)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 12 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 6)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 13 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 14 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set one to many on save 15 - $db_type");

  # RESET
  $o = MyPgObject->new(id => 222)->load;

  # Set (one existing, one new)
  @o2s = 
  (
    MyPgOtherObject2->new(id => 7, name => 'seven'),
    MyPgOtherObject2->new(id => 12, name => 'one'),
  );

  ok($o->other2_objs_on_save(\@o2s), "set 2 one to many on save 1 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 2 - $db_type");

  ok(!MyPgOtherObject2->new(id => 12)->load(speculative => 1), "set 2 one to many on save 3 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set 2 one to many on save 4 - $db_type");

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set 2 one to many on save 5 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 6 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 7 - $db_type");

  $o->save;

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set one to many on save 8 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 9 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 10 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 11 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 12)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 12 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 2, "set one to many on save 15 - $db_type");

  # Set to undef
  $o->other2_objs_on_save(undef);

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set one to many on save 16 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 17 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 18 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 19 - $db_type");

  $o2 = MyPgOtherObject2->new(id => 12)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 20 - $db_type");

  $o->save;

  @o2s = $o->other2_objs_on_save;

  push(@o2s, MyPgOtherObject2->new(name => 'added'));

  $o->other2_objs_on_save(\@o2s);

  $o->save;

  my $to = MyPgObject->new(id => $o->id)->load;

  @o2s = $o->other2_objs_on_save;

  is_deeply([ 'seven', 'one', 'added' ], [ map { $_->name } @o2s ], "add one to many on save 1 - $db_type");


  #
  # "one to many" add_now
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MyPgObject->new(id   => 333,
                       name => 'Zoom',
                       flag => 1);

  $o->save;

  @o2s = 
  (
    MyPgOtherObject2->new(id => 5, name => 'five'),
    MyPgOtherObject2->new(id => 6, name => 'six'),
    MyPgOtherObject2->new(id => 7, name => 'seven'),
  );

  $o->other2_objs_now(@o2s);

  # RESET
  $o = MyPgObject->new(id   => 333,
                       name => 'Zoom',
                       flag => 1);

  # Add, no args
  @o2s = ();
  ok($o->add_other2_objs_now(@o2s) == 0, "add one to many now 1 - $db_type");

  # Add before load/save
  @o2s = 
  (
    MyPgOtherObject2->new(id => 8, name => 'eight'),
  );

  eval { $o->add_other2_objs_now(@o2s) };

  ok($@, "add one to many now 2 - $db_type");

  # Add
  $o->load;

  my @oret = $o->add_other2_objs_now(@o2s);
  is(scalar @oret, scalar @o2s && $oret[0] eq $o2s[0] && 
     $oret[0]->isa('MyPgOtherObject2'), "add one to many now count - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 4, "add one to many now 3 - $db_type");

  ok($o2s[0]->id == 6 && $o2s[0]->pid == 333, "add one to many now 4 - $db_type");
  ok($o2s[1]->id == 7 && $o2s[1]->pid == 333, "add one to many now 5 - $db_type");
  ok($o2s[2]->id == 5 && $o2s[2]->pid == 333, "add one to many now 6 - $db_type");
  ok($o2s[3]->id == 8 && $o2s[3]->pid == 333, "add one to many now 7 - $db_type");

  ok(MyPgOtherObject2->new(id => 6)->load(speculative => 1), "add one to many now 8 - $db_type");
  ok(MyPgOtherObject2->new(id => 7)->load(speculative => 1), "add one to many now 9 - $db_type");
  ok(MyPgOtherObject2->new(id => 5)->load(speculative => 1), "add one to many now 10 - $db_type");
  ok(MyPgOtherObject2->new(id => 8)->load(speculative => 1), "add one to many now 11 - $db_type");

  #
  # "one to many" add_on_save
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MyPgObject->new(id   => 444,
                       name => 'Blargh',
                       flag => 1);

  # Set on save, add on save, save
  @o2s = 
  (
    MyPgOtherObject2->new(id => 10, name => 'ten'),
  );

  # Set on save
  $o->other2_objs_on_save(@o2s);

  @o2s = $o->other2_objs;
  ok(@o2s == 1, "add one to many on save 1 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 2 - $db_type");
  ok(!MyPgOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 3 - $db_type");

  @o2s = 
  (
    MyPgOtherObject2->new(id => 9, name => 'nine'),
  );

  # Add on save
  ok($o->add_other2_objs(@o2s), "add one to many on save 4 - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 5 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 6 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[0]->pid == 444, "add one to many on save 7 - $db_type");

  ok(!MyPgOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 8 - $db_type");
  ok(!MyPgOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 9 - $db_type");

  $o->save;

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 10 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 11 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 12 - $db_type");

  ok(MyPgOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 13 - $db_type");
  ok(MyPgOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 14 - $db_type");

  # RESET
  $o = MyPgObject->new(id   => 444,
                       name => 'Blargh',
                       flag => 1);

  $o->load;

  # Add on save, save
  @o2s = 
  (
    MyPgOtherObject2->new(id => 11, name => 'eleven'),
  );

  # Add on save
  ok($o->add_other2_objs(\@o2s), "add one to many on save 15 - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 16 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 17 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 18 - $db_type");

  ok(MyPgOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 19 - $db_type");
  ok(MyPgOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 20 - $db_type");
  ok(!MyPgOtherObject2->new(id => 11)->load(speculative => 1), "add one to many on save 21 - $db_type");

  # Save
  $o->save;

  @o2s = $o->other2_objs;
  ok(@o2s == 3, "add one to many on save 22 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 23 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 24 - $db_type");
  ok($o2s[2]->id == 11 && $o2s[2]->pid == 444, "add one to many on save 25 - $db_type");

  ok(MyPgOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 26 - $db_type");
  ok(MyPgOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 27 - $db_type");
  ok(MyPgOtherObject2->new(id => 11)->load(speculative => 1), "add one to many on save 28 - $db_type");

  # End "one to many" method tests

  # Start "load with ..." tests

  ok($o = MyPgObject->new(id => 444)->load(with => [ qw(other_obj other2_objs colors) ]),
     "load with 1 - $db_type");

  ok($o->{'other2_objs'} && $o->{'other2_objs'}[1]->name eq 'nine',
     "load with 2 - $db_type");

  $o = MyPgObject->new(id => 999);

  ok(!$o->load(with => [ qw(other_obj other2_objs colors) ], speculative => 1),
     "load with 3 - $db_type");

  $o = MyPgObject->new(id => 222);

  ok($o->load(with => 'colors'), "load with 4 - $db_type");

  # End "load with ..." tests

  # Start "many to many" tests

  #
  # "many to many" get_set_now
  #

  # SETUP

  $o = MyPgObject->new(id   => 30,
                       name => 'Color',
                       flag => 1);

  # Set
  @colors =
  (
    1, # red
    MyPgColor->new(id => 3), # blue
    { id => 5, name => 'orange' },
  );

  #MyPgColor->new(id => 2), # green
  #MyPgColor->new(id => 4), # pink

  # Set before save, save, set
  eval { $o->colors_now(@colors) };
  ok($@, "set many to many now 1 - $db_type");

  $o->save;

  ok($o->colors_now(@colors), "set many to many now 2 - $db_type");

  @colors = $o->colors_now;
  ok(@colors == 3, "set many to many now 3 - $db_type");

  ok($colors[0]->id == 3, "set many to many now 4 - $db_type");
  ok($colors[1]->id == 5, "set many to many now 5 - $db_type");
  ok($colors[2]->id == 1, "set many to many now 6 - $db_type");

  $color = MyPgColor->new(id => 5);
  ok($color->load(speculative => 1), "set many to many now 7 - $db_type");

  ok(MyPgColorMap->new(obj_id => 30, color_id => 3)->load(speculative => 1),
     "set many to many now 8 - $db_type");
  ok(MyPgColorMap->new(obj_id => 30, color_id => 5)->load(speculative => 1),
     "set many to many now 9 - $db_type");
  ok(MyPgColorMap->new(obj_id => 30, color_id => 1)->load(speculative => 1),
     "set many to many now 10 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 30');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set many to many now 11 - $db_type");

  # Set to undef
  $o->colors_now(undef);

  @colors = $o->colors_now;
  ok(@colors == 3, "set 2 many to many now 1 - $db_type");

  ok($colors[0]->id == 3, "set 2 many to many now 2 - $db_type");
  ok($colors[1]->id == 5, "set 2 many to many now 3 - $db_type");
  ok($colors[2]->id == 1, "set 2 many to many now 4 - $db_type");

  $color = MyPgColor->new(id => 5);
  ok($color->load(speculative => 1), "set 2 many to many now 5 - $db_type");

  $color = MyPgColor->new(id => 3);
  ok($color->load(speculative => 1), "set 2 many to many now 6 - $db_type");

  $color = MyPgColor->new(id => 1);
  ok($color->load(speculative => 1), "set 2 many to many now 7 - $db_type");

  ok(MyPgColorMap->new(obj_id => 30, color_id => 3)->load(speculative => 1),
     "set 2 many to many now 8 - $db_type");
  ok(MyPgColorMap->new(obj_id => 30, color_id => 5)->load(speculative => 1),
     "set 2 many to many now 9 - $db_type");
  ok(MyPgColorMap->new(obj_id => 30, color_id => 1)->load(speculative => 1),
     "set 2 many to many now 10 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 30');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set 2 many to many now 11 - $db_type");

  #
  # "many to many" get_set_on_save
  #

  # SETUP
  $o = MyPgObject->new(id   => 40,
                       name => 'Cool',
                       flag => 1);

  # Set
  @colors =
  (
    MyPgColor->new(id => 1), # red
    3, # blue
    { id => 6, name => 'ochre' },
  );

  #MyPgColor->new(id => 2), # green
  #MyPgColor->new(id => 4), # pink

  $o->colors_on_save(@colors);

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set many to many on save 1 - $db_type");

  ok($colors[0]->id == 1, "set many to many on save 2 - $db_type");
  ok($colors[1]->id == 3, "set many to many on save 3 - $db_type");
  ok($colors[2]->id == 6, "set many to many on save 4 - $db_type");

  ok(MyPgColor->new(id => 1)->load(speculative => 1), "set many to many on save 5 - $db_type");
  ok(MyPgColor->new(id => 3)->load(speculative => 1), "set many to many on save 6 - $db_type");
  ok(!MyPgColor->new(id => 6)->load(speculative => 1), "set many to many on save 7 - $db_type");

  ok(!MyPgColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set many to many on save 8 - $db_type");
  ok(!MyPgColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set many to many on save 9 - $db_type");
  ok(!MyPgColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set many to many on save 10 - $db_type");

  $o->save;

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set many to many on save 11 - $db_type");

  ok($colors[0]->id == 3, "set many to many on save 12 - $db_type");
  ok($colors[1]->id == 6, "set many to many on save 13 - $db_type");
  ok($colors[2]->id == 1, "set many to many on save 14 - $db_type");

  ok(MyPgColor->new(id => 1)->load(speculative => 1), "set many to many on save 15 - $db_type");
  ok(MyPgColor->new(id => 3)->load(speculative => 1), "set many to many on save 16 - $db_type");
  ok(MyPgColor->new(id => 6)->load(speculative => 1), "set many to many on save 17 - $db_type");

  ok(MyPgColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 18 - $db_type");
  ok(MyPgColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 19 - $db_type");
  ok(MyPgColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set 2 many to many on save 20 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 40');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set many to many on save 21 - $db_type");

  # RESET
  $o = MyPgObject->new(id => 40)->load;

  # Set to undef
  $o->colors_on_save(undef);

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set 2 many to many on save 1 - $db_type");

  ok($colors[0]->id == 3, "set 2 many to many on save 2 - $db_type");
  ok($colors[1]->id == 6, "set 2 many to many on save 3 - $db_type");
  ok($colors[2]->id == 1, "set 2 many to many on save 4 - $db_type");

  ok(MyPgColor->new(id => 1)->load(speculative => 1), "set 2 many to many on save 5 - $db_type");
  ok(MyPgColor->new(id => 3)->load(speculative => 1), "set 2 many to many on save 6 - $db_type");
  ok(MyPgColor->new(id => 6)->load(speculative => 1), "set 2 many to many on save 7 - $db_type");

  ok(MyPgColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 8 - $db_type");
  ok(MyPgColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 9 - $db_type");
  ok(MyPgColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set 2 many to many on save 10 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 40');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set 2 many to many on save 11 - $db_type");

  # Tests for SQL efficiency of __check_and_merge
  # $DB::single = 1;
  #   $o->save(changes_only => 1);
  #   $o->colors_on_save({ id => 2 });
  # $Rose::DB::Object::Manager::Debug = 1;
  # $Rose::DB::Object::Debug = 1;
  #   $o->save(changes_only => 1);
  # exit;

  $o->colors([]);
  $o->save(changes_only => 1);

  $o->colors_on_save({ id => 1, name => 'redx' }, { id => 3 });
  $o->save(changes_only => 1);

  $o->colors_on_save(undef);
  $colors = $o->colors_on_save;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'redx',
     "colors merge 1 - $db_type");

  $o->colors_on_save({ id => 2 }, { id => 3, name => 'bluex' });
  $o->save(changes_only => 1);

  $o->colors_on_save(undef);
  $colors = $o->colors_on_save;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'bluex' && $colors->[1]->name eq 'green',
     "colors merge 2 - $db_type");

  #
  # "many to many" add_now
  #

  # SETUP
  $o = MyPgObject->new(id   => 50,
                       name => 'Blat',
                       flag => 1);

  $o->delete;

  @colors =
  (
    MyPgColor->new(id => 1), # red
    MyPgColor->new(id => 3), # blue  
  );

  #MyPgColor->new(id => 4), # pink

  $o->colors_on_save(\@colors);
  $o->save;

  $o = MyPgObject->new(id   => 50,
                       name => 'Blat',
                       flag => 1);
  # Add, no args
  @colors = ();
  ok($o->add_colors(@colors) == 0, "add many to many now 1 - $db_type");

  # Add before load/save
  @colors = 
  (
    MyPgColor->new(id => 7, name => 'puce'),
    MyPgColor->new(id => 2), # green
  );

  eval { $o->add_colors(@colors) };

  ok($@, "add many to many now 2 - $db_type");

  # Add
  $o->load;

  $o->add_colors(@colors);

  @colors = $o->colors;
  ok(@colors == 4, "add many to many now 3 - $db_type");

  ok($colors[0]->id == 3, "add many to many now 4 - $db_type");
  ok($colors[1]->id == 2, "add many to many now 5 - $db_type");
  ok($colors[2]->id == 7, "add many to many now 6 - $db_type");
  ok($colors[3]->id == 1, "add many to many now 7 - $db_type");

  ok(MyPgColor->new(id => 3)->load(speculative => 1), "add many to many now 8 - $db_type");
  ok(MyPgColor->new(id => 2)->load(speculative => 1), "add many to many now 9 - $db_type");
  ok(MyPgColor->new(id => 7)->load(speculative => 1), "add many to many now 10 - $db_type");
  ok(MyPgColor->new(id => 1)->load(speculative => 1), "add many to many now 11 - $db_type");

  ok(MyPgColorMap->new(obj_id => 50, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 12 - $db_type");
  ok(MyPgColorMap->new(obj_id => 50, color_id => 2)->load(speculative => 1),
     "set 2 many to many on save 13 - $db_type");
  ok(MyPgColorMap->new(obj_id => 50, color_id => 7)->load(speculative => 1),
     "set 2 many to many on save 14 - $db_type");
  ok(MyPgColorMap->new(obj_id => 50, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 15 - $db_type");

  #
  # "many to many" add_on_save
  #

  # SETUP
  $o = MyPgObject->new(id   => 60,
                       name => 'Cretch',
                       flag => 1);

  $o->delete;

  # Set on save, add on save, save
  @colors = 
  (
    MyPgColor->new(id => 1), # red
    MyPgColor->new(id => 2), # green
  );

  # Set on save
  $o->colors_on_save(@colors);

  @colors = 
  (
    MyPgColor->new(id => 7), # puce
    MyPgColor->new(id => 8, name => 'tan'),
  );

  # Add on save
  my $num = $o->add_colors_on_save(@colors);
  is($num, scalar @colors, "add many to many on save 1 - $db_type");

  @colors = $o->colors;
  ok(@colors == 4, "add many to many on save 2 - $db_type");

  ok($colors[0]->id == 1, "add many to many on save 3 - $db_type");
  ok($colors[1]->id == 2, "add many to many on save 4 - $db_type");
  ok($colors[2]->id == 7, "add many to many on save 5 - $db_type");
  ok($colors[3]->id == 8, "add many to many on save 6 - $db_type");

  ok(MyPgColor->new(id => 1)->load(speculative => 1), "add many to many on save 7 - $db_type");
  ok(MyPgColor->new(id => 2)->load(speculative => 1), "add many to many on save 8 - $db_type");
  ok(MyPgColor->new(id => 7)->load(speculative => 1), "add many to many on save 9 - $db_type");
  ok(!MyPgColor->new(id => 8)->load(speculative => 1), "add many to many on save 10 - $db_type");

  ok(!MyPgColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "set many to many on save 11 - $db_type");
  ok(!MyPgColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "set many to many on save 12 - $db_type");
  ok(!MyPgColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "set many to many on save 13 - $db_type");
  ok(!MyPgColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "set many to many on save 14 - $db_type");

  $o->save;

  @colors = $o->colors;
  ok(@colors == 4, "add many to many on save 15 - $db_type");

  ok($colors[0]->id == 2, "add many to many on save 16 - $db_type");
  ok($colors[1]->id == 7, "add many to many on save 17 - $db_type");
  ok($colors[2]->id == 1, "add many to many on save 18 - $db_type");
  ok($colors[3]->id == 8, "add many to many on save 19 - $db_type");

  ok(MyPgColor->new(id => 2)->load(speculative => 1), "add many to many on save 20 - $db_type");
  ok(MyPgColor->new(id => 7)->load(speculative => 1), "add many to many on save 21 - $db_type");
  ok(MyPgColor->new(id => 1)->load(speculative => 1), "add many to many on save 22 - $db_type");
  ok(MyPgColor->new(id => 8)->load(speculative => 1), "add many to many on save 21 - $db_type");

  ok(MyPgColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add many to many on save 22 - $db_type");
  ok(MyPgColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add many to many on save 23 - $db_type");
  ok(MyPgColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add many to many on save 24 - $db_type");
  ok(MyPgColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add many to many on save 25 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 4, "add many to many on save 26 - $db_type");

  # RESET
  $o = MyPgObject->new(id   => 60,
                       name => 'Cretch',
                       flag => 1);

  $o->load(with => 'colors');

  # Add on save, save
  @colors = 
  (
    MyPgColor->new(id => 9, name => 'aqua'),
  );

  # Add on save
  ok($o->add_colors_on_save(@colors), "add 2 many to many on save 1 - $db_type");

  @colors = $o->colors;
  ok(@colors == 5, "add 2 many to many on save 16 - $db_type");

  ok($colors[0]->id == 2, "add 2 many to many on save 2 - $db_type");
  ok($colors[1]->id == 7, "add 2 many to many on save 3 - $db_type");
  ok($colors[2]->id == 1, "add 2 many to many on save 4 - $db_type");
  ok($colors[3]->id == 8, "add 2 many to many on save 5 - $db_type");
  ok($colors[4]->id == 9, "add 2 many to many on save 6 - $db_type");

  ok(MyPgColor->new(id => 2)->load(speculative => 1), "add many to many on save 7 - $db_type");
  ok(MyPgColor->new(id => 7)->load(speculative => 1), "add many to many on save 8 - $db_type");
  ok(MyPgColor->new(id => 1)->load(speculative => 1), "add many to many on save 9 - $db_type");
  ok(MyPgColor->new(id => 8)->load(speculative => 1), "add many to many on save 10 - $db_type");
  ok(!MyPgColor->new(id => 9)->load(speculative => 1), "add many to many on save 11 - $db_type");

  ok(MyPgColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add 2 many to many on save 12 - $db_type");
  ok(MyPgColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add 2 many to many on save 13 - $db_type");
  ok(MyPgColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add 2 many to many on save 14 - $db_type");
  ok(MyPgColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add 2 many to many on save 15 - $db_type");
  ok(!MyPgColorMap->new(obj_id => 60, color_id => 9)->load(speculative => 1),
     "add 2 many to many on save 16 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 4, "add 2 many to many on save 17 - $db_type");

  # Save
  $o->save;

  @colors = $o->colors;
  ok(@colors == 5, "add 2 many to many on save 18 - $db_type");

  ok($colors[0]->id == 9, "add 2 many to many on save 19 - $db_type");
  ok($colors[1]->id == 2, "add 2 many to many on save 20 - $db_type");
  ok($colors[2]->id == 7, "add 2 many to many on save 21 - $db_type");
  ok($colors[3]->id == 1, "add 2 many to many on save 22 - $db_type");
  ok($colors[4]->id == 8, "add 2 many to many on save 23 - $db_type");

  ok(MyPgColor->new(id => 9)->load(speculative => 1), "add many to many on save 24 - $db_type");
  ok(MyPgColor->new(id => 2)->load(speculative => 1), "add many to many on save 25 - $db_type");
  ok(MyPgColor->new(id => 7)->load(speculative => 1), "add many to many on save 26 - $db_type");
  ok(MyPgColor->new(id => 1)->load(speculative => 1), "add many to many on save 27 - $db_type");
  ok(MyPgColor->new(id => 8)->load(speculative => 1), "add many to many on save 28 - $db_type");

  ok(MyPgColorMap->new(obj_id => 60, color_id => 9)->load(speculative => 1),
     "add 2 many to many on save 29 - $db_type");
  ok(MyPgColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add 2 many to many on save 20 - $db_type");
  ok(MyPgColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add 2 many to many on save 31 - $db_type");
  ok(MyPgColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add 2 many to many on save 32 - $db_type");
  ok(MyPgColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add 2 many to many on save 33 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 5, "add 2 many to many on save 34 - $db_type");

  # End "many to many" tests

  test_meta(MyPgOtherObject2->meta, 'MyPg', $db_type);
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 359)  unless($HAVE_MYSQL);

  Rose::DB->default_type($db_type);

  my $o = MyMySQLObject->new(name => 'John');

  ok(ref $o && $o->isa('MyMySQLObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(22);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  my $o_x = MyMySQLObject->new(id => 99, name => 'John X', flag => 0);
  $o_x->save;

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
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyMySQLObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyMySQLObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  my $oo21 = MyMySQLOtherObject2->new(id => 1, name => 'one', pid => $o->id);
  ok($oo21->save, "other object 2 save() 1 - $db_type");

  my $oo22 = MyMySQLOtherObject2->new(id => 2, name => 'two', pid => $o->id);
  ok($oo22->save, "other object 2 save() 2 - $db_type");

  my $oo23 = MyMySQLOtherObject2->new(id => 3, name => 'three', pid => $o_x->id);
  ok($oo23->save, "other object 2 save() 3 - $db_type");

  # Begin filtered collection tests

  my $x = MyMySQLObject->new(id => $o->id)->load;
  $x->other2_a_objs({ name => 'aoo' }, { name => 'abc' });

  $x->save;

  $x = MyMySQLObject->new(id => $o->id)->load;

  my $ao = $x->other2_a_objs;
  my $oo = $x->other2_objs;

  is(scalar @$ao, 2, "filtered one-to-many 1 - $db_type");
  is(join(',', map { $_->name } @$ao), 'abc,aoo', "filtered one-to-many 2 - $db_type");

  is(scalar @$oo, 4, "filtered one-to-many 3 - $db_type");
  is(join(',', sort map { $_->name } @$oo), 'abc,aoo,one,two', "filtered one-to-many 4 - $db_type");

  $x->other2_a_objs({ name => 'axx' });
  $x->save;

  $x = MyMySQLObject->new(id => $o->id)->load;

  $ao = $x->other2_a_objs;
  $oo = $x->other2_objs;

  is(scalar @$ao, 1, "filtered one-to-many 5 - $db_type");
  is(join(',', map { $_->name } @$ao), 'axx', "filtered one-to-many 6 - $db_type");

  is(scalar @$oo, 3, "filtered one-to-many 7 - $db_type");
  is(join(',', sort map { $_->name } @$oo), 'axx,one,two', "filtered one-to-many 8 - $db_type");

  $x->other2_a_objs([]);
  $x->save;

  # End filtered collection tests

  ok(!$o->has_loaded_related('other2_objs'), "has_loaded_related() 1 - $db_type");

  my $o2s = $o->other2_objs;

  ok($o->has_loaded_related('other2_objs'), "has_loaded_related() 2 - $db_type");

  ok(ref $o2s eq 'ARRAY' && @$o2s == 2 && 
     $o2s->[0]->name eq 'two' && $o2s->[1]->name eq 'one',
     'other objects 1');

  my @o2s = $o->other2_objs;

  ok(@o2s == 2 && $o2s[0]->name eq 'two' && $o2s[1]->name eq 'one',
     'other objects 2');

  my $color = MyMySQLColor->new(id => 1, name => 'red');
  ok($color->save, "save color 1 - $db_type");

  $color = MyMySQLColor->new(id => 2, name => 'green');
  ok($color->save, "save color 2 - $db_type");

  $color = MyMySQLColor->new(id => 3, name => 'blue');
  ok($color->save, "save color 3 - $db_type");

  $color = MyMySQLColor->new(id => 4, name => 'pink');
  ok($color->save, "save color 4 - $db_type");

  my $map1 = MyMySQLColorMap->new(obj_id => 1, color_id => 1);
  ok($map1->save, "save color map record 1 - $db_type");

  my $map2 = MyMySQLColorMap->new(obj_id => 1, color_id => 3);
  ok($map2->save, "save color map record 2 - $db_type");

  my $map3 = MyMySQLColorMap->new(obj_id => 99, color_id => 4);
  ok($map3->save, "save color map record 3 - $db_type");

  my $colors = $o->colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'red',
     "colors 1 - $db_type");

  $colors = $o->find_colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'red',
     "find colors 1 - $db_type");

  $colors = $o->find_colors([ name => { like => 'r%' } ]);

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'red',
     "find colors 2 - $db_type");

  $colors = $o->find_colors(query => [ name => { like => 'r%' } ], cache => 1);

  my $colors2 = $o->find_colors(from_cache => 1);

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'red' &&
     ref $colors2 eq 'ARRAY' && @$colors2 == 1 && $colors2->[0]->name eq 'red' &&
     $colors->[0] eq $colors2->[0],
     "find colors from cache - $db_type");

  my $count = $o->colors_count;

  is($count, 2, "count colors 1 - $db_type");

  $count = $o->colors_count([ name => { like => 'r%' } ]);

  is($count, 1, "count colors 2 - $db_type");

  my @colors = $o->colors;

  ok(@colors == 2 && $colors[0]->name eq 'blue' && $colors[1]->name eq 'red',
     "colors 2 - $db_type");

  $colors = $o_x->colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'pink',
     "colors 3 - $db_type");

  @colors = $o_x->colors;

  ok(@colors == 1 && $colors[0]->name eq 'pink', "colors 4 - $db_type");

  $o = MyMySQLObject->new(id => 1)->load;

  $o->fk1(99);
  $o->fk2(99);
  $o->fk3(99);

  eval { $o->other_obj };
  ok($@, "fatal referential_integrity - $db_type");
  ok(!defined $o->other_obj_osoft, "ok referential_integrity 1 - $db_type");
  ok(!defined $o->other_obj_msoft, "ok referential_integrity 2 - $db_type");

  $o->fk1(1);
  $o->fk2(2);
  $o->fk3(3);
  $o->save;

  #local $Rose::DB::Object::Manager::Debug = 1;

  my $ret;

  eval
  {
    local $o->dbh->{'PrintError'} = 0;
    $ret = $o->delete(cascade => 'null');
  };

  # Allow for exceptions in case some fancy new version of MySQL actually
  # tries preserve referential integrity.  Hey, you never know...
  ok($ret || $@, "delete cascade null 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyMySQLOtherObject2');

  is($count, 3, "delete cascade rollback confirm 2 - $db_type");

  $o = MyMySQLObject->new(id => 99)->load;
  $o->fk1(11);
  $o->fk2(12);
  $o->fk3(13);
  $o->save;

  eval
  {
    local $o->dbh->{'PrintError'} = 0;
    $ret = $o->delete(cascade => 'null');
  };

  ok($ret || $@, "delete cascade null 2 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyMySQLColorMap');

  is($count, 3, "delete cascade confirm 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyMySQLOtherObject2');

  is($count, 3, "delete cascade confirm 2 - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # Start foreign key method tests

  #
  # Foreign key get_set_now
  #

  $o = MyMySQLObject->new(id   => 50,
                          name => 'Alex',
                          flag => 1);

  eval { $o->other_obj('abc') };
  ok($@, "set foreign key object: one arg - $db_type");

  eval { $o->other_obj(k1 => 1, k2 => 2, k3 => 3) };
  ok($@, "set foreign key object: no save - $db_type");

  $o->save;

  eval
  {
    local $o->db->dbh->{'PrintError'} = 0;
    $o->other_obj(k1 => 1, k2 => 2);
  };

  ok($@, "set foreign key object: too few keys - $db_type");

  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "set foreign key object 1 - $db_type");
  ok($o->fk1 == 1 && $o->fk2 == 2 && $o->fk3 == 3, "set foreign key object check keys 1 - $db_type");

  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "set foreign key object 2 - $db_type");
  ok($o->fk1 == 1 && $o->fk2 == 2 && $o->fk3 == 3, "set foreign key object check keys 2 - $db_type");

  #
  # Foreign key delete_now
  #

  ok($o->delete_other_obj, "delete foreign key object 1 - $db_type");

  ok(!defined $o->fk1 && !defined $o->fk2 && !defined $o->fk3, "delete foreign key object check keys 1 - $db_type");

  ok(!defined $o->other_obj && defined $o->error, "delete foreign key object confirm 1 - $db_type");

  ok(!defined $o->delete_other_obj, "delete foreign key object 2 - $db_type");

  #
  # Foreign key get_set_on_save
  #

  # TEST: Set, save
  $o = MyMySQLObject->new(id   => 100,
                          name => 'Bub',
                          flag => 1);

  ok($o->other_obj_on_save(k1 => 21, k2 => 22, k3 => 23), "set foreign key object on save 1 - $db_type");

  my $co = MyMySQLObject->new(id => 100);
  ok(!$co->load(speculative => 1), "set foreign key object on save 2 - $db_type");

  my $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 21 && $other_obj->k2 == 22 && $other_obj->k3 == 23,
     "set foreign key object on save 3 - $db_type");

  ok($o->save, "set foreign key object on save 4 - $db_type");

  $o = MyMySQLObject->new(id => 100);

  $o->load;

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj && $other_obj->k1 == 21 && $other_obj->k2 == 22 && $other_obj->k3 == 23,
     "set foreign key object on save 5 - $db_type");

  # TEST: Set, set to undef, save
  $o = MyMySQLObject->new(id   => 200,
                          name => 'Rose',
                          flag => 1);

  ok($o->other_obj_on_save(k1 => 51, k2 => 52, k3 => 53), "set foreign key object on save 6 - $db_type");

  $co = MyMySQLObject->new(id => 200);
  ok(!$co->load(speculative => 1), "set foreign key object on save 7 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 51 && $other_obj->k2 == 52 && $other_obj->k3 == 53,
     "set foreign key object on save 8 - $db_type");

  $o->other_obj_on_save(undef);

  ok($o->save, "set foreign key object on save 9 - $db_type");

  $o = MyMySQLObject->new(id => 200);

  $o->load;

  ok(!defined $o->other_obj_on_save, "set foreign key object on save 10 - $db_type");

  $co = MyMySQLOtherObject->new(k1 => 51, k2 => 52, k3 => 53);
  ok(!$co->load(speculative => 1), "set foreign key object on save 11 - $db_type");

  $o->delete(cascade => 1);

  # TEST: Set, delete, save
  $o = MyMySQLObject->new(id   => 200,
                          name => 'Rose',
                          flag => 1);

  ok($o->other_obj_on_save(k1 => 51, k2 => 52, k3 => 53), "set foreign key object on save 12 - $db_type");

  $co = MyMySQLObject->new(id => 200);
  ok(!$co->load(speculative => 1), "set foreign key object on save 13 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 51 && $other_obj->k2 == 52 && $other_obj->k3 == 53,
     "set foreign key object on save 14 - $db_type");

  ok($o->delete_other_obj, "set foreign key object on save 15 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok(!defined $other_obj && !defined $o->fk1 && !defined $o->fk2 && !defined $o->fk3,
     "set foreign key object on save 16 - $db_type");

  ok($o->save, "set foreign key object on save 17 - $db_type");

  $o = MyMySQLObject->new(id => 200);

  $o->load;

  ok(!defined $o->other_obj_on_save, "set foreign key object on save 18 - $db_type");

  $co = MyMySQLOtherObject->new(k1 => 51, k2 => 52, k3 => 53);
  ok(!$co->load(speculative => 1), "set foreign key object on save 19 - $db_type");

  $o->delete(cascade => 1);

  #
  # Foreign key delete_on_save
  #

  $o = MyMySQLObject->new(id   => 500,
                          name => 'Kip',
                          flag => 1);

  $o->other_obj_on_save(k1 => 7, k2 => 8, k3 => 9);
  $o->save;

  $o = MyMySQLObject->new(id => 500);
  $o->load;

  # TEST: Delete, save
  $o->del_other_obj_on_save;

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fk1 && !defined $o->fk2 && !defined $o->fk3,
     "delete foreign key object on save 1 - $db_type");

  # ...but that the foreign object has not yet been deleted
  $co = MyMySQLOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok($co->load(speculative => 1), "delete foreign key object on save 2 - $db_type");

  # Do the save
  ok($o->save, "delete foreign key object on save 3 - $db_type");

  # Now it's deleted
  $co = MyMySQLOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok(!$co->load(speculative => 1), "delete foreign key object on save 4 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef
  ok(!defined $other_obj && !defined $o->fk1 && !defined $o->fk2 && !defined $o->fk3,
     "delete foreign key object on save 5 - $db_type");

  # RESET
  $o->delete;

  $o = MyMySQLObject->new(id   => 700,
                          name => 'Ham',
                          flag => 0);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MyMySQLObject->new(id => 700);
  $o->load;

  # TEST: Delete, set on save, delete, save
  ok($o->del_other_obj_on_save, "delete 2 foreign key object on save 1 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fk1 && !defined $o->fk2 && !defined $o->fk3,
     "delete 2 foreign key object on save 2 - $db_type");

  # ...but that the foreign object has not yet been deleted
  $co = MyMySQLOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 3 - $db_type");

  # Set on save
  $o->other_obj_on_save(k1 => 44, k2 => 55, k3 => 66);

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are set...
  ok($other_obj &&  $other_obj->k1 == 44 && $other_obj->k2 == 55 && $other_obj->k3 == 66,
     "delete 2 foreign key object on save 4 - $db_type");

  # ...and that the foreign object has not yet been saved
  $co = MyMySQLOtherObject->new(k1 => 44, k2 => 55, k3 => 66);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 5 - $db_type");

  # Delete again
  ok($o->del_other_obj_on_save, "delete 2 foreign key object on save 6 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fk1 && !defined $o->fk2 && !defined $o->fk3,
     "delete 2 foreign key object on save 7 - $db_type");

  # Confirm that the foreign objects have not been saved
  $co = MyMySQLOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 8 - $db_type");
  $co = MyMySQLOtherObject->new(k1 => 44, k2 => 55, k3 => 66);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 9 - $db_type");

  # RESET
  $o->delete;

  $o = MyMySQLObject->new(id   => 800,
                          name => 'Lee',
                          flag => 1);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MyMySQLObject->new(id => 800);
  $o->load;

  # TEST: Set & save, delete on save, set on save, delete on save, save
  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "delete 3 foreign key object on save 1 - $db_type");

  # Confirm that both foreign objects are in the db
  $co = MyMySQLOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 2 - $db_type");
  $co = MyMySQLOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 3 - $db_type");

  # Delete on save
  $o->del_other_obj_on_save;

  # Set-on-save to old value
  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);

  # Delete on save
  $o->del_other_obj_on_save;  

  # Save
  $o->save;

  # Confirm that both foreign objects have been deleted
  $co = MyMySQLOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok(!$co->load(speculative => 1), "delete 3 foreign key object on save 4 - $db_type");
  $co = MyMySQLOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok(!$co->load(speculative => 1), "delete 3 foreign key object on save 5 - $db_type");

  # RESET
  $o->delete;

  $o = MyMySQLObject->new(id   => 900,
                          name => 'Kai',
                          flag => 1);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MyMySQLObject->new(id => 900);
  $o->load;

  # TEST: Delete on save, set on save, delete on save, set to same one, save
  $o->del_other_obj_on_save;

  # Set on save
  ok($o->other_obj_on_save(k1 => 1, k2 => 2, k3 => 3), "delete 4 foreign key object on save 1 - $db_type");

  # Delete on save
  $o->del_other_obj_on_save;

  # Set-on-save to previous value
  $o->other_obj_on_save(k1 => 1, k2 => 2, k3 => 3);

  # Save
  $o->save;

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are set...
  ok($other_obj &&  $other_obj->k1 == 1 && $other_obj->k2 == 2 && $other_obj->k3 == 3,
     "delete 4 foreign key object on save 2 - $db_type");

  # Confirm that the new foreign object is there and the old one is not
  $co = MyMySQLOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok($co->load(speculative => 1), "delete 4 foreign key object on save 3 - $db_type");
  $co = MyMySQLOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok(!$co->load(speculative => 1), "delete 4 foreign key object on save 4 - $db_type");

  # End foreign key method tests

  # Start "one to many" method tests

  #
  # "one to many" get_set_now
  #

  # SETUP
  $o = MyMySQLObject->new(id   => 111,
                          name => 'Boo',
                          flag => 1);

  @o2s = 
  (
    1,
    MyMySQLOtherObject2->new(id => 2, name => 'two'),
    { id => 3, name => 'three' },
  );

  # Set before save, save, set
  eval { $o->other2_objs_now(@o2s) };
  ok($@, "set one to many now 1 - $db_type");

  $o->save;

  ok($o->other2_objs_now(@o2s), "set one to many now 2 - $db_type");

  @o2s = $o->other2_objs_now;
  ok(@o2s == 3, "set one to many now 3 - $db_type");

  ok($o2s[0]->id == 2 && $o2s[0]->pid == 111, "set one to many now 4 - $db_type");
  ok($o2s[1]->id == 3 && $o2s[1]->pid == 111, "set one to many now 5 - $db_type");
  ok($o2s[2]->id == 1 && $o2s[2]->pid == 111, "set one to many now 6 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 7 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 2)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 8 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 3)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 9 - $db_type");

  my $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 111');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set one to many now 10 - $db_type");

  # Set to undef
  $o->other2_objs_now(undef);

  @o2s = $o->other2_objs_now;
  ok(@o2s == 3, "set one to many now 11 - $db_type");

  ok($o2s[0]->id == 2 && $o2s[0]->pid == 111, "set one to many now 12 - $db_type");
  ok($o2s[1]->id == 3 && $o2s[1]->pid == 111, "set one to many now 13 - $db_type");
  ok($o2s[2]->id == 1 && $o2s[2]->pid == 111, "set one to many now 14 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 15 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 2)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 16 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 3)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 17 - $db_type");

  # RESET
  $o = MyMySQLObject->new(id => 111)->load;

  # Set (one existing, one new)
  @o2s = 
  (
    MyMySQLOtherObject2->new(id => 1, name => 'one'),
    MyMySQLOtherObject2->new(id => 7, name => 'seven'),
  );

  ok($o->other2_objs_now(\@o2s), "set 2 one to many now 1 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many now 2 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many now 3 - $db_type");

  @o2s = $o->other2_objs_now;
  ok(@o2s == 2, "set 2 one to many now 4 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 111, "set 2 one to many now 5 - $db_type");
  ok($o2s[1]->id == 1 && $o2s[1]->pid == 111, "set 2 one to many now 6 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 111');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 2, "set 2 one to many now 7 - $db_type");

  #
  # "one to many" get_set_on_save
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MyMySQLObject->new(id   => 222,
                          name => 'Hap',
                          flag => 1);

  @o2s = 
  (
    MyMySQLOtherObject2->new(id => 5, name => 'five'),
    MyMySQLOtherObject2->new(id => 6, name => 'six'),
    MyMySQLOtherObject2->new(id => 7, name => 'seven'),
  );

  $o->other2_objs_on_save(@o2s);

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 3, "set one to many on save 1 - $db_type");

  ok($o2s[0]->id == 5 && $o2s[0]->pid == 222, "set one to many on save 2 - $db_type");
  ok($o2s[1]->id == 6 && $o2s[1]->pid == 222, "set one to many on save 3 - $db_type");
  ok($o2s[2]->id == 7 && $o2s[2]->pid == 222, "set one to many on save 4 - $db_type");

  ok(!MyMySQLOtherObject2->new(id => 5)->load(speculative => 1), "set one to many on save 5 - $db_type");
  ok(!MyMySQLOtherObject2->new(id => 6)->load(speculative => 1), "set one to many on save 6 - $db_type");
  ok(!MyMySQLOtherObject2->new(id => 7)->load(speculative => 1), "set one to many on save 7 - $db_type");

  $o->save;

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 3, "set one to many on save 8 - $db_type");

  ok($o2s[0]->id == 6 && $o2s[0]->pid == 222, "set one to many on save 9 - $db_type");
  ok($o2s[1]->id == 7 && $o2s[1]->pid == 222, "set one to many on save 10 - $db_type");
  ok($o2s[2]->id == 5 && $o2s[2]->pid == 222, "set one to many on save 11 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 5)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 12 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 6)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 13 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 14 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set one to many on save 15 - $db_type");

  # RESET
  $o = MyMySQLObject->new(id => 222)->load;

  # Set (one existing, one new)
  @o2s = 
  (
    MyMySQLOtherObject2->new(id => 7, name => 'seven'),
    MyMySQLOtherObject2->new(id => 12, name => 'one'),
  );

  ok($o->other2_objs_on_save(\@o2s), "set 2 one to many on save 1 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 2 - $db_type");

  ok(!MyMySQLOtherObject2->new(id => 12)->load(speculative => 1), "set 2 one to many on save 3 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set 2 one to many on save 4 - $db_type");

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set 2 one to many on save 5 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 6 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 7 - $db_type");

  $o->save;

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set one to many on save 8 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 9 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 10 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 11 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 12)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 12 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 2, "set one to many on save 15 - $db_type");

  # Set to undef
  $o->other2_objs_on_save(undef);

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set one to many on save 16 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 17 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 18 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 19 - $db_type");

  $o2 = MyMySQLOtherObject2->new(id => 12)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 20 - $db_type");

  #
  # "one to many" add_now
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MyMySQLObject->new(id   => 333,
                          name => 'Zoom',
                          flag => 1);

  $o->save;

  @o2s = 
  (
    MyMySQLOtherObject2->new(id => 5, name => 'five'),
    MyMySQLOtherObject2->new(id => 6, name => 'six'),
    MyMySQLOtherObject2->new(id => 7, name => 'seven'),
  );

  $o->other2_objs_now(@o2s);

  # RESET
  $o = MyMySQLObject->new(id   => 333,
                          name => 'Zoom',
                          flag => 1);

  # Add, no args
  @o2s = ();
  ok($o->add_other2_objs_now(@o2s) == 0, "add one to many now 1 - $db_type");

  # Add before load/save
  @o2s = 
  (
    MyMySQLOtherObject2->new(id => 8, name => 'eight'),
  );

  eval { $o->add_other2_objs_now(@o2s) };

  ok($@, "add one to many now 2 - $db_type");

  # Add
  $o->load;

  my @oret = $o->add_other2_objs_now(@o2s);
  is(scalar @oret, scalar @o2s && $oret[0] eq $o2s[0] && 
     $oret[0]->isa('MyMySQLOtherObject2'), "add one to many now count - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 4, "add one to many now 3 - $db_type");

  ok($o2s[0]->id == 6 && $o2s[0]->pid == 333, "add one to many now 4 - $db_type");
  ok($o2s[1]->id == 7 && $o2s[1]->pid == 333, "add one to many now 5 - $db_type");
  ok($o2s[2]->id == 5 && $o2s[2]->pid == 333, "add one to many now 6 - $db_type");
  ok($o2s[3]->id == 8 && $o2s[3]->pid == 333, "add one to many now 7 - $db_type");

  ok(MyMySQLOtherObject2->new(id => 6)->load(speculative => 1), "add one to many now 8 - $db_type");
  ok(MyMySQLOtherObject2->new(id => 7)->load(speculative => 1), "add one to many now 9 - $db_type");
  ok(MyMySQLOtherObject2->new(id => 5)->load(speculative => 1), "add one to many now 10 - $db_type");
  ok(MyMySQLOtherObject2->new(id => 8)->load(speculative => 1), "add one to many now 11 - $db_type");

  #
  # "one to many" add_on_save
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MyMySQLObject->new(id   => 444,
                          name => 'Blargh',
                          flag => 1);

  # Set on save, add on save, save
  @o2s = 
  (
    MyMySQLOtherObject2->new(id => 10, name => 'ten'),
  );

  # Set on save
  $o->other2_objs_on_save(@o2s);

  @o2s = $o->other2_objs;
  ok(@o2s == 1, "add one to many on save 1 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 2 - $db_type");
  ok(!MyMySQLOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 3 - $db_type");

  @o2s = 
  (
    MyMySQLOtherObject2->new(id => 9, name => 'nine'),
  );

  # Add on save
  ok($o->add_other2_objs(@o2s), "add one to many on save 4 - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 5 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 6 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[0]->pid == 444, "add one to many on save 7 - $db_type");

  ok(!MyMySQLOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 8 - $db_type");
  ok(!MyMySQLOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 9 - $db_type");

  $o->save;

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 10 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 11 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 12 - $db_type");

  ok(MyMySQLOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 13 - $db_type");
  ok(MyMySQLOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 14 - $db_type");

  # RESET
  $o = MyMySQLObject->new(id   => 444,
                          name => 'Blargh',
                          flag => 1);

  $o->load;

  # Add on save, save
  @o2s = 
  (
    MyMySQLOtherObject2->new(id => 11, name => 'eleven'),
  );

  # Add on save
  ok($o->add_other2_objs(\@o2s), "add one to many on save 15 - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 16 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 17 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 18 - $db_type");

  ok(MyMySQLOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 19 - $db_type");
  ok(MyMySQLOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 20 - $db_type");
  ok(!MyMySQLOtherObject2->new(id => 11)->load(speculative => 1), "add one to many on save 21 - $db_type");

  # Save
  $o->save;

  @o2s = $o->other2_objs;
  ok(@o2s == 3, "add one to many on save 22 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 23 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 24 - $db_type");
  ok($o2s[2]->id == 11 && $o2s[2]->pid == 444, "add one to many on save 25 - $db_type");

  ok(MyMySQLOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 26 - $db_type");
  ok(MyMySQLOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 27 - $db_type");
  ok(MyMySQLOtherObject2->new(id => 11)->load(speculative => 1), "add one to many on save 28 - $db_type");

  # End "one to many" method tests

  # Start "load with ..." tests

  ok($o = MyMySQLObject->new(id => 444)->load(with => [ qw(other_obj other2_objs colors) ]),
     "load with 1 - $db_type");

  ok($o->{'other2_objs'} && $o->{'other2_objs'}[1]->name eq 'nine',
     "load with 2 - $db_type");

  $o = MyMySQLObject->new(id => 999);

  ok(!$o->load(with => [ qw(other_obj other2_objs colors) ], speculative => 1),
     "load with 3 - $db_type");

  $o = MyMySQLObject->new(id => 222);

  ok($o->load(with => 'colors'), "load with 4 - $db_type");

  # End "load with ..." tests

  # Start "many to many" tests

  #
  # "many to many" get_set_now
  #

  # SETUP

  $o = MyMySQLObject->new(id   => 30,
                          name => 'Color',
                          flag => 1);

  # Set
  @colors =
  (
    1, # red
    MyMySQLColor->new(id => 3), # blue
    { id => 5, name => 'orange' },
  );

  #MyMySQLColor->new(id => 2), # green
  #MyMySQLColor->new(id => 4), # pink

  # Set before save, save, set
  eval { $o->colors_now(@colors) };
  ok($@, "set many to many now 1 - $db_type");

  $o->save;

  ok($o->colors_now(@colors), "set many to many now 2 - $db_type");

  @colors = $o->colors_now;
  ok(@colors == 3, "set many to many now 3 - $db_type");

  ok($colors[0]->id == 3, "set many to many now 4 - $db_type");
  ok($colors[1]->id == 5, "set many to many now 5 - $db_type");
  ok($colors[2]->id == 1, "set many to many now 6 - $db_type");

  $color = MyMySQLColor->new(id => 5);
  ok($color->load(speculative => 1), "set many to many now 7 - $db_type");

  ok(MyMySQLColorMap->new(obj_id => 30, color_id => 3)->load(speculative => 1),
     "set many to many now 8 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 30, color_id => 5)->load(speculative => 1),
     "set many to many now 9 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 30, color_id => 1)->load(speculative => 1),
     "set many to many now 10 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 30');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set many to many now 11 - $db_type");

  # Set to undef
  $o->colors_now(undef);

  @colors = $o->colors_now;
  ok(@colors == 3, "set 2 many to many now 1 - $db_type");

  ok($colors[0]->id == 3, "set 2 many to many now 2 - $db_type");
  ok($colors[1]->id == 5, "set 2 many to many now 3 - $db_type");
  ok($colors[2]->id == 1, "set 2 many to many now 4 - $db_type");

  $color = MyMySQLColor->new(id => 5);
  ok($color->load(speculative => 1), "set 2 many to many now 5 - $db_type");

  $color = MyMySQLColor->new(id => 3);
  ok($color->load(speculative => 1), "set 2 many to many now 6 - $db_type");

  $color = MyMySQLColor->new(id => 1);
  ok($color->load(speculative => 1), "set 2 many to many now 7 - $db_type");

  ok(MyMySQLColorMap->new(obj_id => 30, color_id => 3)->load(speculative => 1),
     "set 2 many to many now 8 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 30, color_id => 5)->load(speculative => 1),
     "set 2 many to many now 9 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 30, color_id => 1)->load(speculative => 1),
     "set 2 many to many now 10 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 30');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set 2 many to many now 11 - $db_type");

  #
  # "many to many" get_set_on_save
  #

  # SETUP
  $o = MyMySQLObject->new(id   => 40,
                          name => 'Cool',
                          flag => 1);

  # Set
  @colors =
  (
    MyMySQLColor->new(id => 1), # red
    3, # blue
    { id => 6, name => 'ochre' },
  );

  #MyMySQLColor->new(id => 2), # green
  #MyMySQLColor->new(id => 4), # pink

  $o->colors_on_save(@colors);

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set many to many on save 1 - $db_type");

  ok($colors[0]->id == 1, "set many to many on save 2 - $db_type");
  ok($colors[1]->id == 3, "set many to many on save 3 - $db_type");
  ok($colors[2]->id == 6, "set many to many on save 4 - $db_type");

  ok(MyMySQLColor->new(id => 1)->load(speculative => 1), "set many to many on save 5 - $db_type");
  ok(MyMySQLColor->new(id => 3)->load(speculative => 1), "set many to many on save 6 - $db_type");
  ok(!MyMySQLColor->new(id => 6)->load(speculative => 1), "set many to many on save 7 - $db_type");

  ok(!MyMySQLColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set many to many on save 8 - $db_type");
  ok(!MyMySQLColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set many to many on save 9 - $db_type");
  ok(!MyMySQLColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set many to many on save 10 - $db_type");

  $o->save;

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set many to many on save 11 - $db_type");

  ok($colors[0]->id == 3, "set many to many on save 12 - $db_type");
  ok($colors[1]->id == 6, "set many to many on save 13 - $db_type");
  ok($colors[2]->id == 1, "set many to many on save 14 - $db_type");

  ok(MyMySQLColor->new(id => 1)->load(speculative => 1), "set many to many on save 15 - $db_type");
  ok(MyMySQLColor->new(id => 3)->load(speculative => 1), "set many to many on save 16 - $db_type");
  ok(MyMySQLColor->new(id => 6)->load(speculative => 1), "set many to many on save 17 - $db_type");

  ok(MyMySQLColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 18 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 19 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set 2 many to many on save 20 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 40');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set many to many on save 21 - $db_type");

  # RESET
  $o = MyMySQLObject->new(id => 40)->load;

  # Set to undef
  $o->colors_on_save(undef);

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set 2 many to many on save 1 - $db_type");

  ok($colors[0]->id == 3, "set 2 many to many on save 2 - $db_type");
  ok($colors[1]->id == 6, "set 2 many to many on save 3 - $db_type");
  ok($colors[2]->id == 1, "set 2 many to many on save 4 - $db_type");

  ok(MyMySQLColor->new(id => 1)->load(speculative => 1), "set 2 many to many on save 5 - $db_type");
  ok(MyMySQLColor->new(id => 3)->load(speculative => 1), "set 2 many to many on save 6 - $db_type");
  ok(MyMySQLColor->new(id => 6)->load(speculative => 1), "set 2 many to many on save 7 - $db_type");

  ok(MyMySQLColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 8 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 9 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set 2 many to many on save 10 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 40');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set 2 many to many on save 11 - $db_type");

  $o->colors([]);
  $o->save(changes_only => 1);

  $o->colors_on_save({ id => 1, name => 'redx' }, { id => 3 });
  $o->save(changes_only => 1);

  $o->colors_on_save(undef);
  $colors = $o->colors_on_save;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'redx',
     "colors merge 1 - $db_type");

  $o->colors_on_save({ id => 2 }, { id => 3, name => 'bluex' });
  $o->save(changes_only => 1);

  $o->colors_on_save(undef);
  $colors = $o->colors_on_save;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'bluex' && $colors->[1]->name eq 'green',
     "colors merge 2 - $db_type");

  #
  # "many to many" add_now
  #

  # SETUP
  $o = MyMySQLObject->new(id   => 50,
                          name => 'Blat',
                          flag => 1);

  $o->delete;

  @colors =
  (
    MyMySQLColor->new(id => 1), # red
    MyMySQLColor->new(id => 3), # blue  
  );

  #MyMySQLColor->new(id => 4), # pink

  $o->colors_on_save(\@colors);
  $o->save;

  $o = MyMySQLObject->new(id   => 50,
                          name => 'Blat',
                          flag => 1);
  # Add, no args
  @colors = ();
  ok($o->add_colors(@colors) == 0, "add many to many now 1 - $db_type");

  # Add before load/save
  @colors = 
  (
    MyMySQLColor->new(id => 7, name => 'puce'),
    MyMySQLColor->new(id => 2), # green
  );

  eval { $o->add_colors(@colors) };

  ok($@, "add many to many now 2 - $db_type");

  # Add
  $o->load;

  $o->add_colors(@colors);

  @colors = $o->colors;
  ok(@colors == 4, "add many to many now 3 - $db_type");

  ok($colors[0]->id == 3, "add many to many now 4 - $db_type");
  ok($colors[1]->id == 2, "add many to many now 5 - $db_type");
  ok($colors[2]->id == 7, "add many to many now 6 - $db_type");
  ok($colors[3]->id == 1, "add many to many now 7 - $db_type");

  ok(MyMySQLColor->new(id => 3)->load(speculative => 1), "add many to many now 8 - $db_type");
  ok(MyMySQLColor->new(id => 2)->load(speculative => 1), "add many to many now 9 - $db_type");
  ok(MyMySQLColor->new(id => 7)->load(speculative => 1), "add many to many now 10 - $db_type");
  ok(MyMySQLColor->new(id => 1)->load(speculative => 1), "add many to many now 11 - $db_type");

  ok(MyMySQLColorMap->new(obj_id => 50, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 12 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 50, color_id => 2)->load(speculative => 1),
     "set 2 many to many on save 13 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 50, color_id => 7)->load(speculative => 1),
     "set 2 many to many on save 14 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 50, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 15 - $db_type");

  #
  # "many to many" add_on_save
  #

  # SETUP
  $o = MyMySQLObject->new(id   => 60,
                          name => 'Cretch',
                          flag => 1);

  $o->delete;

  # Set on save, add on save, save
  @colors = 
  (
    MyMySQLColor->new(id => 1), # red
    MyMySQLColor->new(id => 2), # green
  );

  # Set on save
  $o->colors_on_save(@colors);

  @colors = 
  (
    MyMySQLColor->new(id => 7), # puce
    MyMySQLColor->new(id => 8, name => 'tan'),
  );

  # Add on save
  ok($o->add_colors_on_save(@colors), "add many to many on save 1 - $db_type");

  @colors = $o->colors;
  ok(@colors == 4, "add many to many on save 2 - $db_type");

  ok($colors[0]->id == 1, "add many to many on save 3 - $db_type");
  ok($colors[1]->id == 2, "add many to many on save 4 - $db_type");
  ok($colors[2]->id == 7, "add many to many on save 5 - $db_type");
  ok($colors[3]->id == 8, "add many to many on save 6 - $db_type");

  ok(MyMySQLColor->new(id => 1)->load(speculative => 1), "add many to many on save 7 - $db_type");
  ok(MyMySQLColor->new(id => 2)->load(speculative => 1), "add many to many on save 8 - $db_type");
  ok(MyMySQLColor->new(id => 7)->load(speculative => 1), "add many to many on save 9 - $db_type");
  ok(!MyMySQLColor->new(id => 8)->load(speculative => 1), "add many to many on save 10 - $db_type");

  ok(!MyMySQLColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "set many to many on save 11 - $db_type");
  ok(!MyMySQLColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "set many to many on save 12 - $db_type");
  ok(!MyMySQLColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "set many to many on save 13 - $db_type");
  ok(!MyMySQLColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "set many to many on save 14 - $db_type");

  $o->save;

  @colors = $o->colors;
  ok(@colors == 4, "add many to many on save 15 - $db_type");

  ok($colors[0]->id == 2, "add many to many on save 16 - $db_type");
  ok($colors[1]->id == 7, "add many to many on save 17 - $db_type");
  ok($colors[2]->id == 1, "add many to many on save 18 - $db_type");
  ok($colors[3]->id == 8, "add many to many on save 19 - $db_type");

  ok(MyMySQLColor->new(id => 2)->load(speculative => 1), "add many to many on save 20 - $db_type");
  ok(MyMySQLColor->new(id => 7)->load(speculative => 1), "add many to many on save 21 - $db_type");
  ok(MyMySQLColor->new(id => 1)->load(speculative => 1), "add many to many on save 22 - $db_type");
  ok(MyMySQLColor->new(id => 8)->load(speculative => 1), "add many to many on save 21 - $db_type");

  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add many to many on save 22 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add many to many on save 23 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add many to many on save 24 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add many to many on save 25 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 4, "add many to many on save 26 - $db_type");

  # RESET
  $o = MyMySQLObject->new(id   => 60,
                          name => 'Cretch',
                          flag => 1);

  $o->load(with => 'colors');

  # Add on save, save
  @colors = 
  (
    MyMySQLColor->new(id => 9, name => 'aqua'),
  );

  # Add on save
  ok($o->add_colors_on_save(@colors), "add 2 many to many on save 1 - $db_type");

  @colors = $o->colors;
  ok(@colors == 5, "add 2 many to many on save 16 - $db_type");

  ok($colors[0]->id == 2, "add 2 many to many on save 2 - $db_type");
  ok($colors[1]->id == 7, "add 2 many to many on save 3 - $db_type");
  ok($colors[2]->id == 1, "add 2 many to many on save 4 - $db_type");
  ok($colors[3]->id == 8, "add 2 many to many on save 5 - $db_type");
  ok($colors[4]->id == 9, "add 2 many to many on save 6 - $db_type");

  ok(MyMySQLColor->new(id => 2)->load(speculative => 1), "add many to many on save 7 - $db_type");
  ok(MyMySQLColor->new(id => 7)->load(speculative => 1), "add many to many on save 8 - $db_type");
  ok(MyMySQLColor->new(id => 1)->load(speculative => 1), "add many to many on save 9 - $db_type");
  ok(MyMySQLColor->new(id => 8)->load(speculative => 1), "add many to many on save 10 - $db_type");
  ok(!MyMySQLColor->new(id => 9)->load(speculative => 1), "add many to many on save 11 - $db_type");

  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add 2 many to many on save 12 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add 2 many to many on save 13 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add 2 many to many on save 14 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add 2 many to many on save 15 - $db_type");
  ok(!MyMySQLColorMap->new(obj_id => 60, color_id => 9)->load(speculative => 1),
     "add 2 many to many on save 16 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 4, "add 2 many to many on save 17 - $db_type");

  # Save
  $o->save;

  @colors = $o->colors;
  ok(@colors == 5, "add 2 many to many on save 18 - $db_type");

  ok($colors[0]->id == 9, "add 2 many to many on save 19 - $db_type");
  ok($colors[1]->id == 2, "add 2 many to many on save 20 - $db_type");
  ok($colors[2]->id == 7, "add 2 many to many on save 21 - $db_type");
  ok($colors[3]->id == 1, "add 2 many to many on save 22 - $db_type");
  ok($colors[4]->id == 8, "add 2 many to many on save 23 - $db_type");

  ok(MyMySQLColor->new(id => 9)->load(speculative => 1), "add many to many on save 24 - $db_type");
  ok(MyMySQLColor->new(id => 2)->load(speculative => 1), "add many to many on save 25 - $db_type");
  ok(MyMySQLColor->new(id => 7)->load(speculative => 1), "add many to many on save 26 - $db_type");
  ok(MyMySQLColor->new(id => 1)->load(speculative => 1), "add many to many on save 27 - $db_type");
  ok(MyMySQLColor->new(id => 8)->load(speculative => 1), "add many to many on save 28 - $db_type");

  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 9)->load(speculative => 1),
     "add 2 many to many on save 29 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add 2 many to many on save 20 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add 2 many to many on save 31 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add 2 many to many on save 32 - $db_type");
  ok(MyMySQLColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add 2 many to many on save 33 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 5, "add 2 many to many on save 34 - $db_type");

  # End "many to many" tests

  # Start "one to one" cascaded delete tests

  #local $Rose::DB::Object::Debug = 1;
  #local $Rose::DB::Object::Manager::Debug = 1;
  $o = MyMySQLObject->new(name => '1to1bug',
                          fk1 => 10,
                          fk2 => 20,
                          fk3 => 30,
                          other_obj_otoo =>
                          {
                            name => '1to1bugfo',
                            k1 => 10,
                            k2 => 20,
                            k3 => 30,
                          });

  $o->save;

  $o = MyMySQLObject->new(id => $o->id)->load;

  ok(defined $o->other_obj_otoo, "delete(cascade => 1) one to one prep - $db_type");

  $o = MyMySQLObject->new(id => $o->id);
  $o->delete(cascade => 1);

  ok(!MyMySQLOtherObject->new(k1 => 10, k2 => 20, k3 => 30)->load(speculative => 1),
     "delete(cascade => 1) one to one delete - $db_type");

  # XXX: This relies on MySQL's creepy behavior of setting not-null
  # XXX: columns to 0 when they are set to NULL by a query.
  #
  # $o = MyMySQLObject->new(name => '1to1bug2',
  #                         fk1 => 10,
  #                         fk2 => 20,
  #                         fk3 => 30,
  #                         other_obj_otoo =>
  #                         {
  #                           name => '1to1bugfo2',
  #                           k1 => 10,
  #                           k2 => 20,
  #                           k3 => 30,
  #                         });
  # 
  # $o->save;
  # 
  # $o = MyMySQLObject->new(id => $o->id)->load;
  # 
  # ok(defined $o->other_obj_otoo, "delete(cascade => 1) one to one prep - $db_type");
  # 
  # $o = MyMySQLObject->new(id => $o->id);
  # $o->delete(cascade => 'null');
  # 
  # ok(MyMySQLOtherObject->new(k1 => 0, k2 => 0, k3 => 0)->load(speculative => 1),
  #    "delete(cascade => 1) one to one null - $db_type");

  # End "one to one" cascaded delete tests

  # Start fk hook-up tests

  $o2 = MyMySQLOtherObject2->new(name => 'B', pid => 11);
  $o2->save;

  $o = MyMySQLObject->new(name => 'John', id => 12);

  $o->add_other2_objs2($o2);
  $o2->name('John2');
  $o->save;

  $o2 = MyMySQLOtherObject2->new(id => $o2->id)->load;

  is($o2->pid, $o->id, "fk hook-up 1 - $db_type");
  is($o2->name, 'John2', "fk hook-up 2 - $db_type");

  # End fk hook-up tests
}

#
# Informix
#

SKIP: foreach my $db_type ('informix')
{
  skip("Informix tests", 378)  unless($HAVE_INFORMIX);

  Rose::DB->default_type($db_type);

  my $o = MyInformixObject->new(name => 'John', id => 1);

  ok(ref $o && $o->isa('MyInformixObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  my $o_x = MyInformixObject->new(id => 99, name => 'John X', flag => 0);
  $o_x->save;

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
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
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
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  my $oo1 = MyInformixOtherObject->new(k1 => 1, k2 => 2, k3 => 3, name => 'one');
  ok($oo1->save, "other object save() 1 - $db_type");

  my $oo2 = MyInformixOtherObject->new(k1 => 11, k2 => 12, k3 => 13, name => 'two');
  ok($oo2->save, "other object save() 2 - $db_type");

  is($o->other_obj, undef, "other_obj() 1 - $db_type");

  $o->fkone(99);
  $o->fk2(99);
  $o->fk3(99);

  eval { $o->other_obj };
  ok($@, "fatal referential_integrity - $db_type");
  ok(!defined $o->other_obj_osoft, "ok referential_integrity 1 - $db_type");
  ok(!defined $o->other_obj_msoft, "ok referential_integrity 2 - $db_type");

  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);

  my $obj = $o->other_obj or warn "# ", $o->error, "\n";

  is(ref $obj, 'MyInformixOtherObject', "other_obj() 2 - $db_type");
  is($obj->name, 'one', "other_obj() 3 - $db_type");

  $o->other_obj(undef);
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);

  ok(!$o->has_loaded_related('other_obj'), "has_loaded_related() 1 - $db_type");

  $obj = $o->other_obj or warn "# ", $o->error, "\n";

  ok($o->has_loaded_related('other_obj'), "has_loaded_related() 2 - $db_type");

  is(ref $obj, 'MyInformixOtherObject', "other_obj() 4 - $db_type");
  is($obj->name, 'two', "other_obj() 5 - $db_type");

  my $oo21 = MyInformixOtherObject2->new(id => 1, name => 'one', pid => $o->id);
  ok($oo21->save, "other object 2 save() 1 - $db_type");

  my $oo22 = MyInformixOtherObject2->new(id => 2, name => 'two', pid => $o->id);
  ok($oo22->save, "other object 2 save() 2 - $db_type");

  my $oo23 = MyInformixOtherObject2->new(id => 3, name => 'three', pid => $o_x->id);
  ok($oo23->save, "other object 2 save() 3 - $db_type");

  # Begin filtered collection tests

  my $x = MyInformixObject->new(id => $o->id)->load;
  $x->other2_a_objs({ id => 100, name => 'aoo' }, { id => 101, name => 'abc' });

  $x->save;

  $x = MyInformixObject->new(id => $o->id)->load;

  my $ao = $x->other2_a_objs;
  my $oo = $x->other2_objs;

  is(scalar @$ao, 2, "filtered one-to-many 1 - $db_type");
  is(join(',', map { $_->name } @$ao), 'abc,aoo', "filtered one-to-many 2 - $db_type");

  is(scalar @$oo, 4, "filtered one-to-many 3 - $db_type");
  is(join(',', sort map { $_->name } @$oo), 'abc,aoo,one,two', "filtered one-to-many 4 - $db_type");

  $x->other2_a_objs({ id => 102, name => 'axx' });
  $x->save;

  $x = MyInformixObject->new(id => $o->id)->load;

  $ao = $x->other2_a_objs;
  $oo = $x->other2_objs;

  is(scalar @$ao, 1, "filtered one-to-many 5 - $db_type");
  is(join(',', map { $_->name } @$ao), 'axx', "filtered one-to-many 6 - $db_type");

  is(scalar @$oo, 3, "filtered one-to-many 7 - $db_type");
  is(join(',', sort map { $_->name } @$oo), 'axx,one,two', "filtered one-to-many 8 - $db_type");

  $x->other2_a_objs([]);
  $x->save;

  # End filtered collection tests

  ok(!$o->has_loaded_related('other2_objs'), "has_loaded_related() 3 - $db_type");

  my $o2s = $o->other2_objs;

  ok($o->has_loaded_related('other2_objs'), "has_loaded_related() 4 - $db_type");

  ok(ref $o2s eq 'ARRAY' && @$o2s == 2 && 
     $o2s->[0]->name eq 'two' && $o2s->[1]->name eq 'one',
     'other objects 1');

  my @o2s = $o->other2_objs;

  ok(@o2s == 2 && $o2s[0]->name eq 'two' && $o2s[1]->name eq 'one',
     'other objects 2');

  my $color = MyInformixColor->new(id => 1, name => 'red');
  ok($color->save, "save color 1 - $db_type");

  $color = MyInformixColor->new(id => 2, name => 'green');
  ok($color->save, "save color 2 - $db_type");

  $color = MyInformixColor->new(id => 3, name => 'blue');
  ok($color->save, "save color 3 - $db_type");

  $color = MyInformixColor->new(id => 4, name => 'pink');
  ok($color->save, "save color 4 - $db_type");

  my $map1 = MyInformixColorMap->new(obj_id => 1, color_id => 1);
  ok($map1->save, "save color map record 1 - $db_type");

  my $map2 = MyInformixColorMap->new(obj_id => 1, color_id => 3);
  ok($map2->save, "save color map record 2 - $db_type");

  my $map3 = MyInformixColorMap->new(obj_id => 99, color_id => 4);
  ok($map3->save, "save color map record 3 - $db_type");

  my $colors = $o->colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'red',
     "colors 1 - $db_type");

  $colors = $o->find_colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'red',
     "find colors 1 - $db_type");

  $colors = $o->find_colors([ name => { like => 'r%' } ]);

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'red',
     "find colors 2 - $db_type");

  $colors = $o->find_colors(query => [ name => { like => 'r%' } ], cache => 1);

  my $colors2 = $o->find_colors(from_cache => 1);

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'red' &&
     ref $colors2 eq 'ARRAY' && @$colors2 == 1 && $colors2->[0]->name eq 'red' &&
     $colors->[0] eq $colors2->[0],
     "find colors from cache - $db_type");

  my $count = $o->colors_count;

  is($count, 2, "count colors 1 - $db_type");

  $count = $o->colors_count([ name => { like => 'r%' } ]);

  is($count, 1, "count colors 2 - $db_type");

  my @colors = $o->colors;

  ok(@colors == 2 && $colors[0]->name eq 'blue' && $colors[1]->name eq 'red',
     "colors 2 - $db_type");

  $colors = $o_x->colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'pink',
     "colors 3 - $db_type");

  @colors = $o_x->colors;

  ok(@colors == 1 && $colors[0]->name eq 'pink', "colors 4 - $db_type");

  $o = MyInformixObject->new(id => 1)->load;
  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);
  $o->save;

  #local $Rose::DB::Object::Manager::Debug = 1;

  eval
  {
    local $o->dbh->{'PrintError'} = 0;
    $o->delete(cascade => 'null');
  };

  ok($@, "delete cascade null 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyInformixOtherObject');

  is($count, 2, "delete cascade rollback confirm 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyInformixOtherObject2');

  is($count, 3, "delete cascade rollback confirm 2 - $db_type");

  ok($o->delete(cascade => 'delete'), "delete cascade delete 1 - $db_type");

  $o = MyInformixObject->new(id => 99)->load;
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);
  $o->save;

  eval
  {
    local $o->dbh->{'PrintError'} = 0;
    $o->delete(cascade => 'null');
  };

  ok($@, "delete cascade null 2 - $db_type");

  ok($o->delete(cascade => 'delete'), "delete cascade delete 2 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyInformixColorMap');

  is($count, 0, "delete cascade confirm 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyInformixOtherObject2');

  is($count, 0, "delete cascade confirm 2 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MyInformixOtherObject');

  is($count, 0, "delete cascade confirm 3 - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # Start foreign key method tests

  #
  # Foreign key get_set_now
  #

  $o = MyInformixObject->new(id   => 50,
                       name => 'Alex',
                       flag => 1);

  eval { $o->other_obj('abc') };
  ok($@, "set foreign key object: one arg - $db_type");

  eval { $o->other_obj(k1 => 1, k2 => 2, k3 => 3) };
  ok($@, "set foreign key object: no save - $db_type");

  $o->save;

  eval
  {
    local $o->db->dbh->{'PrintError'} = 0;
    $o->other_obj(k1 => 1, k2 => 2);
  };

  ok($@, "set foreign key object: too few keys - $db_type");

  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "set foreign key object 1 - $db_type");
  ok($o->fkone == 1 && $o->fk2 == 2 && $o->fk3 == 3, "set foreign key object check keys 1 - $db_type");

  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "set foreign key object 2 - $db_type");
  ok($o->fkone == 1 && $o->fk2 == 2 && $o->fk3 == 3, "set foreign key object check keys 2 - $db_type");

  #
  # Foreign key delete_now
  #

  ok($o->delete_other_obj, "delete foreign key object 1 - $db_type");

  ok(!defined $o->fkone && !defined $o->fk2 && !defined $o->fk3, "delete foreign key object check keys 1 - $db_type");

  ok(!defined $o->other_obj && defined $o->error, "delete foreign key object confirm 1 - $db_type");

  ok(!defined $o->delete_other_obj, "delete foreign key object 2 - $db_type");

  #
  # Foreign key get_set_on_save
  #

  # TEST: Set, save
  $o = MyInformixObject->new(id   => 100,
                       name => 'Bub',
                       flag => 1);

  ok($o->other_obj_on_save(k1 => 21, k2 => 22, k3 => 23), "set foreign key object on save 1 - $db_type");

  my $co = MyInformixObject->new(id => 100);
  ok(!$co->load(speculative => 1), "set foreign key object on save 2 - $db_type");

  my $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 21 && $other_obj->k2 == 22 && $other_obj->k3 == 23,
     "set foreign key object on save 3 - $db_type");

  ok($o->save, "set foreign key object on save 4 - $db_type");

  $o = MyInformixObject->new(id => 100);

  $o->load;

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj && $other_obj->k1 == 21 && $other_obj->k2 == 22 && $other_obj->k3 == 23,
     "set foreign key object on save 5 - $db_type");

  # TEST: Set, set to undef, save
  $o = MyInformixObject->new(id   => 200,
                       name => 'Rose',
                       flag => 1);

  ok($o->other_obj_on_save(k1 => 51, k2 => 52, k3 => 53), "set foreign key object on save 6 - $db_type");

  $co = MyInformixObject->new(id => 200);
  ok(!$co->load(speculative => 1), "set foreign key object on save 7 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 51 && $other_obj->k2 == 52 && $other_obj->k3 == 53,
     "set foreign key object on save 8 - $db_type");

  $o->other_obj_on_save(undef);

  ok($o->save, "set foreign key object on save 9 - $db_type");

  $o = MyInformixObject->new(id => 200);

  $o->load;

  ok(!defined $o->other_obj_on_save, "set foreign key object on save 10 - $db_type");

  $co = MyInformixOtherObject->new(k1 => 51, k2 => 52, k3 => 53);
  ok(!$co->load(speculative => 1), "set foreign key object on save 11 - $db_type");

  $o->delete(cascade => 1);

  # TEST: Set, delete, save
  $o = MyInformixObject->new(id   => 200,
                       name => 'Rose',
                       flag => 1);

  ok($o->other_obj_on_save(k1 => 51, k2 => 52, k3 => 53), "set foreign key object on save 12 - $db_type");

  $co = MyInformixObject->new(id => 200);
  ok(!$co->load(speculative => 1), "set foreign key object on save 13 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 51 && $other_obj->k2 == 52 && $other_obj->k3 == 53,
     "set foreign key object on save 14 - $db_type");

  ok($o->delete_other_obj, "set foreign key object on save 15 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "set foreign key object on save 16 - $db_type");

  ok($o->save, "set foreign key object on save 17 - $db_type");

  $o = MyInformixObject->new(id => 200);

  $o->load;

  ok(!defined $o->other_obj_on_save, "set foreign key object on save 18 - $db_type");

  $co = MyInformixOtherObject->new(k1 => 51, k2 => 52, k3 => 53);
  ok(!$co->load(speculative => 1), "set foreign key object on save 19 - $db_type");

  $o->delete(cascade => 1);

  #
  # Foreign key delete_on_save
  #

  $o = MyInformixObject->new(id   => 500,
                       name => 'Kip',
                       flag => 1);

  $o->other_obj_on_save(k1 => 7, k2 => 8, k3 => 9);
  $o->save;

  $o = MyInformixObject->new(id => 500);
  $o->load;

  # TEST: Delete, save
  $o->del_other_obj_on_save;

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete foreign key object on save 1 - $db_type");

  # ...but that the foreign object has not yet been deleted
  $co = MyInformixOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok($co->load(speculative => 1), "delete foreign key object on save 2 - $db_type");

  # Do the save
  ok($o->save, "delete foreign key object on save 3 - $db_type");

  # Now it's deleted
  $co = MyInformixOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok(!$co->load(speculative => 1), "delete foreign key object on save 4 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete foreign key object on save 5 - $db_type");

  # RESET
  $o->delete;

  $o = MyInformixObject->new(id   => 700,
                       name => 'Ham',
                       flag => 0);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MyInformixObject->new(id => 700);
  $o->load;

  # TEST: Delete, set on save, delete, save
  ok($o->del_other_obj_on_save, "delete 2 foreign key object on save 1 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete 2 foreign key object on save 2 - $db_type");

  # ...but that the foreign object has not yet been deleted
  $co = MyInformixOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 3 - $db_type");

  # Set on save
  $o->other_obj_on_save(k1 => 44, k2 => 55, k3 => 66);

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are set...
  ok($other_obj &&  $other_obj->k1 == 44 && $other_obj->k2 == 55 && $other_obj->k3 == 66,
     "delete 2 foreign key object on save 4 - $db_type");

  # ...and that the foreign object has not yet been saved
  $co = MyInformixOtherObject->new(k1 => 44, k2 => 55, k3 => 66);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 5 - $db_type");

  # Delete again
  ok($o->del_other_obj_on_save, "delete 2 foreign key object on save 6 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete 2 foreign key object on save 7 - $db_type");

  # Confirm that the foreign objects have not been saved
  $co = MyInformixOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 8 - $db_type");
  $co = MyInformixOtherObject->new(k1 => 44, k2 => 55, k3 => 66);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 9 - $db_type");

  # RESET
  $o->delete;

  $o = MyInformixObject->new(id   => 800,
                       name => 'Lee',
                       flag => 1);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MyInformixObject->new(id => 800);
  $o->load;

  # TEST: Set & save, delete on save, set on save, delete on save, save
  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "delete 3 foreign key object on save 1 - $db_type");

  # Confirm that both foreign objects are in the db
  $co = MyInformixOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 2 - $db_type");
  $co = MyInformixOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 3 - $db_type");

  # Delete on save
  $o->del_other_obj_on_save;

  # Set-on-save to old value
  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);

  # Delete on save
  $o->del_other_obj_on_save;  

  # Save
  $o->save;

  # Confirm that both foreign objects have been deleted
  $co = MyInformixOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok(!$co->load(speculative => 1), "delete 3 foreign key object on save 4 - $db_type");
  $co = MyInformixOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok(!$co->load(speculative => 1), "delete 3 foreign key object on save 5 - $db_type");

  # RESET
  $o->delete;

  $o = MyInformixObject->new(id   => 900,
                       name => 'Kai',
                       flag => 1);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MyInformixObject->new(id => 900);
  $o->load;

  # TEST: Delete on save, set on save, delete on save, set to same one, save
  $o->del_other_obj_on_save;

  # Set on save
  ok($o->other_obj_on_save(k1 => 1, k2 => 2, k3 => 3), "delete 4 foreign key object on save 1 - $db_type");

  # Delete on save
  $o->del_other_obj_on_save;

  # Set-on-save to previous value
  $o->other_obj_on_save(k1 => 1, k2 => 2, k3 => 3);

  # Save
  $o->save;

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are set...
  ok($other_obj &&  $other_obj->k1 == 1 && $other_obj->k2 == 2 && $other_obj->k3 == 3,
     "delete 4 foreign key object on save 2 - $db_type");

  # Confirm that the new foreign object is there and the old one is not
  $co = MyInformixOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok($co->load(speculative => 1), "delete 4 foreign key object on save 3 - $db_type");
  $co = MyInformixOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok(!$co->load(speculative => 1), "delete 4 foreign key object on save 4 - $db_type");

  # End foreign key method tests

  # Start "one to many" method tests

  #
  # "one to many" get_set_now
  #

  #local $Rose::DB::Object::Debug = 1;
  #local $Rose::DB::Object::Manager::Debug = 1;

  # SETUP
  $o = MyInformixObject->new(id   => 111,
                       name => 'Boo',
                       flag => 1);

  @o2s = 
  (
    1,
    MyInformixOtherObject2->new(id => 2, name => 'two'),
    { id => 3, name => 'three' },
  );

  # Set before save, save, set
  eval { $o->other2_objs_now(@o2s) };
  ok($@, "set one to many now 1 - $db_type");

  $o->save;

  ok($o->other2_objs_now(@o2s), "set one to many now 2 - $db_type");

  @o2s = $o->other2_objs_now;
  ok(@o2s == 3, "set one to many now 3 - $db_type");

  ok($o2s[0]->id == 2 && $o2s[0]->pid == 111, "set one to many now 4 - $db_type");
  ok($o2s[1]->id == 3 && $o2s[1]->pid == 111, "set one to many now 5 - $db_type");
  ok($o2s[2]->id == 1 && $o2s[2]->pid == 111, "set one to many now 6 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 7 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 2)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 8 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 3)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 9 - $db_type");

  my $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 111');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set one to many now 10 - $db_type");

  # Set to undef
  $o->other2_objs_now(undef);

  @o2s = $o->other2_objs_now;
  ok(@o2s == 3, "set one to many now 11 - $db_type");

  ok($o2s[0]->id == 2 && $o2s[0]->pid == 111, "set one to many now 12 - $db_type");
  ok($o2s[1]->id == 3 && $o2s[1]->pid == 111, "set one to many now 13 - $db_type");
  ok($o2s[2]->id == 1 && $o2s[2]->pid == 111, "set one to many now 14 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 15 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 2)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 16 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 3)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 17 - $db_type");

  # RESET
  $o = MyInformixObject->new(id => 111)->load;

  # Set (one existing, one new)
  @o2s = 
  (
    MyInformixOtherObject2->new(id => 1, name => 'one'),
    MyInformixOtherObject2->new(id => 7, name => 'seven'),
  );

  ok($o->other2_objs_now(\@o2s), "set 2 one to many now 1 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many now 2 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many now 3 - $db_type");

  @o2s = $o->other2_objs_now;
  ok(@o2s == 2, "set 2 one to many now 4 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 111, "set 2 one to many now 5 - $db_type");
  ok($o2s[1]->id == 1 && $o2s[1]->pid == 111, "set 2 one to many now 6 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 111');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 2, "set 2 one to many now 7 - $db_type");

  #
  # "one to many" get_set_on_save
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MyInformixObject->new(id   => 222,
                       name => 'Hap',
                       flag => 1);

  @o2s = 
  (
    MyInformixOtherObject2->new(id => 5, name => 'five'),
    MyInformixOtherObject2->new(id => 6, name => 'six'),
    MyInformixOtherObject2->new(id => 7, name => 'seven'),
  );

  $o->other2_objs_on_save(@o2s);

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 3, "set one to many on save 1 - $db_type");

  ok($o2s[0]->id == 5 && $o2s[0]->pid == 222, "set one to many on save 2 - $db_type");
  ok($o2s[1]->id == 6 && $o2s[1]->pid == 222, "set one to many on save 3 - $db_type");
  ok($o2s[2]->id == 7 && $o2s[2]->pid == 222, "set one to many on save 4 - $db_type");

  ok(!MyInformixOtherObject2->new(id => 5)->load(speculative => 1), "set one to many on save 5 - $db_type");
  ok(!MyInformixOtherObject2->new(id => 6)->load(speculative => 1), "set one to many on save 6 - $db_type");
  ok(!MyInformixOtherObject2->new(id => 7)->load(speculative => 1), "set one to many on save 7 - $db_type");

  $o->save;

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 3, "set one to many on save 8 - $db_type");

  ok($o2s[0]->id == 6 && $o2s[0]->pid == 222, "set one to many on save 9 - $db_type");
  ok($o2s[1]->id == 7 && $o2s[1]->pid == 222, "set one to many on save 10 - $db_type");
  ok($o2s[2]->id == 5 && $o2s[2]->pid == 222, "set one to many on save 11 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 5)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 12 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 6)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 13 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 14 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set one to many on save 15 - $db_type");

  # RESET
  $o = MyInformixObject->new(id => 222)->load;

  # Set (one existing, one new)
  @o2s = 
  (
    MyInformixOtherObject2->new(id => 7, name => 'seven'),
    MyInformixOtherObject2->new(id => 12, name => 'one'),
  );

  ok($o->other2_objs_on_save(\@o2s), "set 2 one to many on save 1 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 2 - $db_type");

  ok(!MyInformixOtherObject2->new(id => 12)->load(speculative => 1), "set 2 one to many on save 3 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set 2 one to many on save 4 - $db_type");

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set 2 one to many on save 5 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 6 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 7 - $db_type");

  $o->save;

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set one to many on save 8 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 9 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 10 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 11 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 12)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 12 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 2, "set one to many on save 15 - $db_type");

  # Set to undef
  $o->other2_objs_on_save(undef);

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set one to many on save 16 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 17 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 18 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 19 - $db_type");

  $o2 = MyInformixOtherObject2->new(id => 12)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 20 - $db_type");

  #
  # "one to many" add_now
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MyInformixObject->new(id   => 333,
                       name => 'Zoom',
                       flag => 1);

  $o->save;

  @o2s = 
  (
    MyInformixOtherObject2->new(id => 5, name => 'five'),
    MyInformixOtherObject2->new(id => 6, name => 'six'),
    MyInformixOtherObject2->new(id => 7, name => 'seven'),
  );

  $o->other2_objs_now(@o2s);

  # RESET
  $o = MyInformixObject->new(id   => 333,
                       name => 'Zoom',
                       flag => 1);

  # Add, no args
  @o2s = ();
  ok($o->add_other2_objs_now(@o2s) == 0, "add one to many now 1 - $db_type");

  # Add before load/save
  @o2s = 
  (
    MyInformixOtherObject2->new(id => 8, name => 'eight'),
  );

  eval { $o->add_other2_objs_now(@o2s) };

  ok($@, "add one to many now 2 - $db_type");

  # Add
  $o->load;

  $o->add_other2_objs_now(@o2s);

  @o2s = $o->other2_objs;
  ok(@o2s == 4, "add one to many now 3 - $db_type");

  ok($o2s[0]->id == 6 && $o2s[0]->pid == 333, "add one to many now 4 - $db_type");
  ok($o2s[1]->id == 7 && $o2s[1]->pid == 333, "add one to many now 5 - $db_type");
  ok($o2s[2]->id == 5 && $o2s[2]->pid == 333, "add one to many now 6 - $db_type");
  ok($o2s[3]->id == 8 && $o2s[3]->pid == 333, "add one to many now 7 - $db_type");

  ok(MyInformixOtherObject2->new(id => 6)->load(speculative => 1), "add one to many now 8 - $db_type");
  ok(MyInformixOtherObject2->new(id => 7)->load(speculative => 1), "add one to many now 9 - $db_type");
  ok(MyInformixOtherObject2->new(id => 5)->load(speculative => 1), "add one to many now 10 - $db_type");
  ok(MyInformixOtherObject2->new(id => 8)->load(speculative => 1), "add one to many now 11 - $db_type");

  #
  # "one to many" add_on_save
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MyInformixObject->new(id   => 444,
                       name => 'Blargh',
                       flag => 1);

  # Set on save, add on save, save
  @o2s = 
  (
    MyInformixOtherObject2->new(id => 10, name => 'ten'),
  );

  # Set on save
  $o->other2_objs_on_save(@o2s);

  @o2s = $o->other2_objs;
  ok(@o2s == 1, "add one to many on save 1 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 2 - $db_type");
  ok(!MyInformixOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 3 - $db_type");

  @o2s = 
  (
    MyInformixOtherObject2->new(id => 9, name => 'nine'),
  );

  # Add on save
  ok($o->add_other2_objs(@o2s), "add one to many on save 4 - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 5 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 6 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[0]->pid == 444, "add one to many on save 7 - $db_type");

  ok(!MyInformixOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 8 - $db_type");
  ok(!MyInformixOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 9 - $db_type");

  $o->save;

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 10 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 11 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 12 - $db_type");

  ok(MyInformixOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 13 - $db_type");
  ok(MyInformixOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 14 - $db_type");

  # RESET
  $o = MyInformixObject->new(id   => 444,
                       name => 'Blargh',
                       flag => 1);

  $o->load;

  # Add on save, save
  @o2s = 
  (
    MyInformixOtherObject2->new(id => 11, name => 'eleven'),
  );

  # Add on save
  ok($o->add_other2_objs(\@o2s), "add one to many on save 15 - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 16 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 17 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 18 - $db_type");

  ok(MyInformixOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 19 - $db_type");
  ok(MyInformixOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 20 - $db_type");
  ok(!MyInformixOtherObject2->new(id => 11)->load(speculative => 1), "add one to many on save 21 - $db_type");

  # Save
  $o->save;

  @o2s = $o->other2_objs;
  ok(@o2s == 3, "add one to many on save 22 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 23 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 24 - $db_type");
  ok($o2s[2]->id == 11 && $o2s[2]->pid == 444, "add one to many on save 25 - $db_type");

  ok(MyInformixOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 26 - $db_type");
  ok(MyInformixOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 27 - $db_type");
  ok(MyInformixOtherObject2->new(id => 11)->load(speculative => 1), "add one to many on save 28 - $db_type");

  # End "one to many" method tests

  # Start "load with ..." tests

  ok($o = MyInformixObject->new(id => 444)->load(with => [ qw(other_obj other2_objs colors) ]),
     "load with 1 - $db_type");

  ok($o->{'other2_objs'} && $o->{'other2_objs'}[1]->name eq 'nine',
     "load with 2 - $db_type");

  $o = MyInformixObject->new(id => 999);

  ok(!$o->load(with => [ qw(other_obj other2_objs colors) ], speculative => 1),
     "load with 3 - $db_type");

  $o = MyInformixObject->new(id => 222);

  ok($o->load(with => 'colors'), "load with 4 - $db_type");

  # End "load with ..." tests

  # Start "many to many" tests

  #
  # "many to many" get_set_now
  #

  # SETUP

  $o = MyInformixObject->new(id   => 30,
                             name => 'Color',
                             flag => 1);

  # Set
  @colors =
  (
    1, # red
    MyInformixColor->new(id => 3), # blue
    { id => 5, name => 'orange' },
  );

  #MyInformixColor->new(id => 2), # green
  #MyInformixColor->new(id => 4), # pink

  # Set before save, save, set
  eval { $o->colors_now(@colors) };
  ok($@, "set many to many now 1 - $db_type");

  $o->save;

  ok($o->colors_now(@colors), "set many to many now 2 - $db_type");

  @colors = $o->colors_now;
  ok(@colors == 3, "set many to many now 3 - $db_type");

  ok($colors[0]->id == 3, "set many to many now 4 - $db_type");
  ok($colors[1]->id == 5, "set many to many now 5 - $db_type");
  ok($colors[2]->id == 1, "set many to many now 6 - $db_type");

  $color = MyInformixColor->new(id => 5);
  ok($color->load(speculative => 1), "set many to many now 7 - $db_type");

  ok(MyInformixColorMap->new(obj_id => 30, color_id => 3)->load(speculative => 1),
     "set many to many now 8 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 30, color_id => 5)->load(speculative => 1),
     "set many to many now 9 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 30, color_id => 1)->load(speculative => 1),
     "set many to many now 10 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 30');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set many to many now 11 - $db_type");

  # Set to undef
  $o->colors_now(undef);

  @colors = $o->colors_now;
  ok(@colors == 3, "set 2 many to many now 1 - $db_type");

  ok($colors[0]->id == 3, "set 2 many to many now 2 - $db_type");
  ok($colors[1]->id == 5, "set 2 many to many now 3 - $db_type");
  ok($colors[2]->id == 1, "set 2 many to many now 4 - $db_type");

  $color = MyInformixColor->new(id => 5);
  ok($color->load(speculative => 1), "set 2 many to many now 5 - $db_type");

  $color = MyInformixColor->new(id => 3);
  ok($color->load(speculative => 1), "set 2 many to many now 6 - $db_type");

  $color = MyInformixColor->new(id => 1);
  ok($color->load(speculative => 1), "set 2 many to many now 7 - $db_type");

  ok(MyInformixColorMap->new(obj_id => 30, color_id => 3)->load(speculative => 1),
     "set 2 many to many now 8 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 30, color_id => 5)->load(speculative => 1),
     "set 2 many to many now 9 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 30, color_id => 1)->load(speculative => 1),
     "set 2 many to many now 10 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 30');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set 2 many to many now 11 - $db_type");

  #
  # "many to many" get_set_on_save
  #

  # SETUP
  $o = MyInformixObject->new(id   => 40,
                             name => 'Cool',
                             flag => 1);

  # Set
  @colors =
  (
    MyInformixColor->new(id => 1), # red
    3, # blue
    { id => 6, name => 'ochre' },
  );

  #MyInformixColor->new(id => 2), # green
  #MyInformixColor->new(id => 4), # pink

  $o->colors_on_save(@colors);

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set many to many on save 1 - $db_type");

  ok($colors[0]->id == 1, "set many to many on save 2 - $db_type");
  ok($colors[1]->id == 3, "set many to many on save 3 - $db_type");
  ok($colors[2]->id == 6, "set many to many on save 4 - $db_type");

  ok(MyInformixColor->new(id => 1)->load(speculative => 1), "set many to many on save 5 - $db_type");
  ok(MyInformixColor->new(id => 3)->load(speculative => 1), "set many to many on save 6 - $db_type");
  ok(!MyInformixColor->new(id => 6)->load(speculative => 1), "set many to many on save 7 - $db_type");

  ok(!MyInformixColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set many to many on save 8 - $db_type");
  ok(!MyInformixColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set many to many on save 9 - $db_type");
  ok(!MyInformixColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set many to many on save 10 - $db_type");

  $o->save;

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set many to many on save 11 - $db_type");

  ok($colors[0]->id == 3, "set many to many on save 12 - $db_type");
  ok($colors[1]->id == 6, "set many to many on save 13 - $db_type");
  ok($colors[2]->id == 1, "set many to many on save 14 - $db_type");

  ok(MyInformixColor->new(id => 1)->load(speculative => 1), "set many to many on save 15 - $db_type");
  ok(MyInformixColor->new(id => 3)->load(speculative => 1), "set many to many on save 16 - $db_type");
  ok(MyInformixColor->new(id => 6)->load(speculative => 1), "set many to many on save 17 - $db_type");

  ok(MyInformixColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 18 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 19 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set 2 many to many on save 20 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 40');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set many to many on save 21 - $db_type");

  # RESET
  $o = MyInformixObject->new(id => 40)->load;

  # Set to undef
  $o->colors_on_save(undef);

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set 2 many to many on save 1 - $db_type");

  ok($colors[0]->id == 3, "set 2 many to many on save 2 - $db_type");
  ok($colors[1]->id == 6, "set 2 many to many on save 3 - $db_type");
  ok($colors[2]->id == 1, "set 2 many to many on save 4 - $db_type");

  ok(MyInformixColor->new(id => 1)->load(speculative => 1), "set 2 many to many on save 5 - $db_type");
  ok(MyInformixColor->new(id => 3)->load(speculative => 1), "set 2 many to many on save 6 - $db_type");
  ok(MyInformixColor->new(id => 6)->load(speculative => 1), "set 2 many to many on save 7 - $db_type");

  ok(MyInformixColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 8 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 9 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set 2 many to many on save 10 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 40');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 3, "set 2 many to many on save 11 - $db_type");

  $o->colors([]);
  $o->save(changes_only => 1);

  $o->colors_on_save({ id => 1, name => 'redx' }, { id => 3 });
  $o->save(changes_only => 1);

  $o->colors_on_save(undef);
  $colors = $o->colors_on_save;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'redx',
     "colors merge 1 - $db_type");

  $o->colors_on_save({ id => 2 }, { id => 3, name => 'bluex' });
  $o->save(changes_only => 1);

  $o->colors_on_save(undef);
  $colors = $o->colors_on_save;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'bluex' && $colors->[1]->name eq 'green',
     "colors merge 2 - $db_type");

  #
  # "many to many" add_now
  #

  # SETUP
  $o = MyInformixObject->new(id   => 50,
                             name => 'Blat',
                             flag => 1);

  $o->delete;

  @colors =
  (
    MyInformixColor->new(id => 1), # red
    MyInformixColor->new(id => 3), # blue  
  );

  #MyInformixColor->new(id => 4), # pink

  $o->colors_on_save(\@colors);
  $o->save;

  $o = MyInformixObject->new(id   => 50,
                             name => 'Blat',
                             flag => 1);
  # Add, no args
  @colors = ();
  ok($o->add_colors(@colors) == 0, "add many to many now 1 - $db_type");

  # Add before load/save
  @colors = 
  (
    MyInformixColor->new(id => 7, name => 'puce'),
    MyInformixColor->new(id => 2), # green
  );

  eval { $o->add_colors(@colors) };

  ok($@, "add many to many now 2 - $db_type");

  # Add
  $o->load;

  $o->add_colors(@colors);

  @colors = $o->colors;
  ok(@colors == 4, "add many to many now 3 - $db_type");

  ok($colors[0]->id == 3, "add many to many now 4 - $db_type");
  ok($colors[1]->id == 2, "add many to many now 5 - $db_type");
  ok($colors[2]->id == 7, "add many to many now 6 - $db_type");
  ok($colors[3]->id == 1, "add many to many now 7 - $db_type");

  ok(MyInformixColor->new(id => 3)->load(speculative => 1), "add many to many now 8 - $db_type");
  ok(MyInformixColor->new(id => 2)->load(speculative => 1), "add many to many now 9 - $db_type");
  ok(MyInformixColor->new(id => 7)->load(speculative => 1), "add many to many now 10 - $db_type");
  ok(MyInformixColor->new(id => 1)->load(speculative => 1), "add many to many now 11 - $db_type");

  ok(MyInformixColorMap->new(obj_id => 50, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 12 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 50, color_id => 2)->load(speculative => 1),
     "set 2 many to many on save 13 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 50, color_id => 7)->load(speculative => 1),
     "set 2 many to many on save 14 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 50, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 15 - $db_type");

  #
  # "many to many" add_on_save
  #

  # SETUP
  $o = MyInformixObject->new(id   => 60,
                             name => 'Cretch',
                             flag => 1);

  $o->delete;

  # Set on save, add on save, save
  @colors = 
  (
    MyInformixColor->new(id => 1), # red
    MyInformixColor->new(id => 2), # green
  );

  # Set on save
  $o->colors_on_save(@colors);

  @colors = 
  (
    MyInformixColor->new(id => 7), # puce
    MyInformixColor->new(id => 8, name => 'tan'),
  );

  # Add on save
  ok($o->add_colors_on_save(@colors), "add many to many on save 1 - $db_type");

  @colors = $o->colors;
  ok(@colors == 4, "add many to many on save 2 - $db_type");

  ok($colors[0]->id == 1, "add many to many on save 3 - $db_type");
  ok($colors[1]->id == 2, "add many to many on save 4 - $db_type");
  ok($colors[2]->id == 7, "add many to many on save 5 - $db_type");
  ok($colors[3]->id == 8, "add many to many on save 6 - $db_type");

  ok(MyInformixColor->new(id => 1)->load(speculative => 1), "add many to many on save 7 - $db_type");
  ok(MyInformixColor->new(id => 2)->load(speculative => 1), "add many to many on save 8 - $db_type");
  ok(MyInformixColor->new(id => 7)->load(speculative => 1), "add many to many on save 9 - $db_type");
  ok(!MyInformixColor->new(id => 8)->load(speculative => 1), "add many to many on save 10 - $db_type");

  ok(!MyInformixColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "set many to many on save 11 - $db_type");
  ok(!MyInformixColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "set many to many on save 12 - $db_type");
  ok(!MyInformixColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "set many to many on save 13 - $db_type");
  ok(!MyInformixColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "set many to many on save 14 - $db_type");

  $o->save;

  @colors = $o->colors;
  ok(@colors == 4, "add many to many on save 15 - $db_type");

  ok($colors[0]->id == 2, "add many to many on save 16 - $db_type");
  ok($colors[1]->id == 7, "add many to many on save 17 - $db_type");
  ok($colors[2]->id == 1, "add many to many on save 18 - $db_type");
  ok($colors[3]->id == 8, "add many to many on save 19 - $db_type");

  ok(MyInformixColor->new(id => 2)->load(speculative => 1), "add many to many on save 20 - $db_type");
  ok(MyInformixColor->new(id => 7)->load(speculative => 1), "add many to many on save 21 - $db_type");
  ok(MyInformixColor->new(id => 1)->load(speculative => 1), "add many to many on save 22 - $db_type");
  ok(MyInformixColor->new(id => 8)->load(speculative => 1), "add many to many on save 21 - $db_type");

  ok(MyInformixColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add many to many on save 22 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add many to many on save 23 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add many to many on save 24 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add many to many on save 25 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 4, "add many to many on save 26 - $db_type");

  # RESET
  $o = MyInformixObject->new(id   => 60,
                             name => 'Cretch',
                             flag => 1);

  $o->load(with => 'colors');

  # Add on save, save
  @colors = 
  (
    MyInformixColor->new(id => 9, name => 'aqua'),
  );

  # Add on save
  ok($o->add_colors_on_save(@colors), "add 2 many to many on save 1 - $db_type");

  @colors = $o->colors;
  ok(@colors == 5, "add 2 many to many on save 16 - $db_type");

  ok($colors[0]->id == 2, "add 2 many to many on save 2 - $db_type");
  ok($colors[1]->id == 7, "add 2 many to many on save 3 - $db_type");
  ok($colors[2]->id == 1, "add 2 many to many on save 4 - $db_type");
  ok($colors[3]->id == 8, "add 2 many to many on save 5 - $db_type");
  ok($colors[4]->id == 9, "add 2 many to many on save 6 - $db_type");

  ok(MyInformixColor->new(id => 2)->load(speculative => 1), "add many to many on save 7 - $db_type");
  ok(MyInformixColor->new(id => 7)->load(speculative => 1), "add many to many on save 8 - $db_type");
  ok(MyInformixColor->new(id => 1)->load(speculative => 1), "add many to many on save 9 - $db_type");
  ok(MyInformixColor->new(id => 8)->load(speculative => 1), "add many to many on save 10 - $db_type");
  ok(!MyInformixColor->new(id => 9)->load(speculative => 1), "add many to many on save 11 - $db_type");

  ok(MyInformixColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add 2 many to many on save 12 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add 2 many to many on save 13 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add 2 many to many on save 14 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add 2 many to many on save 15 - $db_type");
  ok(!MyInformixColorMap->new(obj_id => 60, color_id => 9)->load(speculative => 1),
     "add 2 many to many on save 16 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  is($count, 4, "add 2 many to many on save 17 - $db_type");

  # Save
  $o->save;

  @colors = $o->colors;
  ok(@colors == 5, "add 2 many to many on save 18 - $db_type");

  ok($colors[0]->id == 9, "add 2 many to many on save 19 - $db_type");
  ok($colors[1]->id == 2, "add 2 many to many on save 20 - $db_type");
  ok($colors[2]->id == 7, "add 2 many to many on save 21 - $db_type");
  ok($colors[3]->id == 1, "add 2 many to many on save 22 - $db_type");
  ok($colors[4]->id == 8, "add 2 many to many on save 23 - $db_type");

  ok(MyInformixColor->new(id => 9)->load(speculative => 1), "add many to many on save 24 - $db_type");
  ok(MyInformixColor->new(id => 2)->load(speculative => 1), "add many to many on save 25 - $db_type");
  ok(MyInformixColor->new(id => 7)->load(speculative => 1), "add many to many on save 26 - $db_type");
  ok(MyInformixColor->new(id => 1)->load(speculative => 1), "add many to many on save 27 - $db_type");
  ok(MyInformixColor->new(id => 8)->load(speculative => 1), "add many to many on save 28 - $db_type");

  ok(MyInformixColorMap->new(obj_id => 60, color_id => 9)->load(speculative => 1),
     "add 2 many to many on save 29 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add 2 many to many on save 20 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add 2 many to many on save 31 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add 2 many to many on save 32 - $db_type");
  ok(MyInformixColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add 2 many to many on save 33 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 5, "add 2 many to many on save 34 - $db_type");

  # End "many to many" tests
}

#
# SQLite
#

SKIP: foreach my $db_type ('sqlite')
{
  skip("SQLite tests", 466)  unless($HAVE_SQLITE);

  Rose::DB->default_type($db_type);

  my $o = MySQLiteObject->new(name => 'John', id => 1);

  ok(ref $o && $o->isa('MySQLiteObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  my $o_x = MySQLiteObject->new(id => 99, name => 'John X', flag => 0);
  $o_x->save;

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
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
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
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  my $oo1 = MySQLiteOtherObject->new(k1 => 1, k2 => 2, k3 => 3, name => 'one');
  ok($oo1->save, "other object save() 1 - $db_type");

  my $oo2 = MySQLiteOtherObject->new(k1 => 11, k2 => 12, k3 => 13, name => 'two');
  ok($oo2->save, "other object save() 2 - $db_type");

  is($o->other_obj, undef, "other_obj() 1 - $db_type");

  $o->fkone(99);
  $o->fk2(99);
  $o->fk3(99);

  eval { $o->other_obj };
  ok($@, "fatal referential_integrity - $db_type");
  ok(!defined $o->other_obj_osoft, "ok referential_integrity 1 - $db_type");
  ok(!defined $o->other_obj_msoft, "ok referential_integrity 2 - $db_type");

  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);

  my $obj = $o->other_obj or warn "# ", $o->error, "\n";

  is(ref $obj, 'MySQLiteOtherObject', "other_obj() 2 - $db_type");
  is($obj->name, 'one', "other_obj() 3 - $db_type");

  $o->other_obj(undef);
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);

  ok(!$o->has_loaded_related('other_obj'), "has_loaded_related() 1 - $db_type");

  $obj = $o->other_obj or warn "# ", $o->error, "\n";

  ok($o->has_loaded_related('other_obj'), "has_loaded_related() 2 - $db_type");

  is(ref $obj, 'MySQLiteOtherObject', "other_obj() 4 - $db_type");
  is($obj->name, 'two', "other_obj() 5 - $db_type");

  my $oo21 = MySQLiteOtherObject2->new(id => 1, name => 'one', pid => $o->id);
  ok($oo21->save, "other object 2 save() 1 - $db_type");

  my $oo22 = MySQLiteOtherObject2->new(id => 2, name => 'two', pid => $o->id);
  ok($oo22->save, "other object 2 save() 2 - $db_type");

  my $oo23 = MySQLiteOtherObject2->new(id => 3, name => 'three', pid => $o_x->id);
  ok($oo23->save, "other object 2 save() 3 - $db_type");

  # Begin experiment
  #local $Rose::DB::Object::Manager::Debug = 1;
  my $no2s = $o->not_other2_objs;

  is(scalar @$no2s, 2, "not equal one-to-many 1 - $db_type");

  my $nobjs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      require_objects => [ 'not_other2_objs' ]);

  is(scalar @$nobjs, 2, "not equal one-to-many 2 - $db_type");

  MySQLiteObject->meta->delete_relationship('not_other2_objs');
  # End experiment

  # Begin manager_*_method tests
  my $manager_method_obj = MySQLiteObject->new(id => $o->id)->load;

  is($manager_method_obj->custom_manager_method_other2_objs, 'ima-get-objects', 
    "custom manager method ima-get-objects - $db_type");

  is($manager_method_obj->meta->relationship('custom_manager_method_other_obj_msoft')->manager_delete_method, 
     'other_obj_delete', "custom manager method ima-delete - $db_type");

  is($manager_method_obj->find_custom_manager_method_other2_objs, 'ima-find', 
     "custom manager method ima-find - $db_type");

  is($manager_method_obj->custom_manager_method_other2_objs_iterator, 'ima-iterator', 
     "custom manager method ima-iterator - $db_type");

  is($manager_method_obj->custom_manager_method_other2_objs_count, 'ima-count', 
     "custom manager method ima-count - $db_type");
  # End manager_*_method tests

  # Begin filtered collection tests

  my $x = MySQLiteObject->new(id => $o->id)->load;
  $x->other2_a_objs({ name => 'aoo' }, { name => 'abc' });

  $x->save;

  $x = MySQLiteObject->new(id => $o->id)->load;

  my $one_o = $x->other2_one_obj;
  my $ao = $x->other2_a_objs;
  my $oo = $x->other2_objs;

  is($one_o->id, 1, "filtered one-to-one 1 - $db_type");
  is(scalar @$ao, 2, "filtered one-to-many 1 - $db_type");
  is(join(',', map { $_->name } @$ao), 'abc,aoo', "filtered one-to-many 2 - $db_type");

  is(scalar @$oo, 4, "filtered one-to-many 3 - $db_type");
  is(join(',', sort map { $_->name } @$oo), 'abc,aoo,one,two', "filtered one-to-many 4 - $db_type");

  $x->other2_a_objs({ name => 'axx' });
  $x->save;

  $x = MySQLiteObject->new(id => $o->id)->load;

  $ao = $x->other2_a_objs;
  $oo = $x->other2_objs;

  is(scalar @$ao, 1, "filtered one-to-many 5 - $db_type");
  is(join(',', map { $_->name } @$ao), 'axx', "filtered one-to-many 6 - $db_type");

  is(scalar @$oo, 3, "filtered one-to-many 7 - $db_type");
  is(join(',', sort map { $_->name } @$oo), 'axx,one,two', "filtered one-to-many 8 - $db_type");

  $x->other2_a_objs([]);
  $x->save;

  # End filtered collection tests

  ok(!$o->has_loaded_related('other2_objs'), "has_loaded_related() 3 - $db_type");

  my $o2s = $o->other2_objs;

  ok($o->has_loaded_related('other2_objs'), "has_loaded_related() 4 - $db_type");

  ok(ref $o2s eq 'ARRAY' && @$o2s == 2 && 
     $o2s->[0]->name eq 'two' && $o2s->[1]->name eq 'one',
     'other objects 1');

  my @o2s = $o->other2_objs;

  ok(@o2s == 2 && $o2s[0]->name eq 'two' && $o2s[1]->name eq 'one',
     'other objects 2');

  my $color = MySQLiteColor->new(id => 1, name => 'red');
  ok($color->save, "save color 1 - $db_type");

  $color = MySQLiteColor->new(id => 2, name => 'green');
  ok($color->save, "save color 2 - $db_type");

  $color = MySQLiteColor->new(id => 3, name => 'blue');
  ok($color->save, "save color 3 - $db_type");

  $color = MySQLiteColor->new(id => 4, name => 'pink');
  ok($color->save, "save color 4 - $db_type");

  my $map1 = MySQLiteColorMap->new(obj_id => 1, color_id => 1);
  ok($map1->save, "save color map record 1 - $db_type");

  my $map2 = MySQLiteColorMap->new(obj_id => 1, color_id => 3);
  ok($map2->save, "save color map record 2 - $db_type");

  my $map3 = MySQLiteColorMap->new(obj_id => 99, color_id => 4);
  ok($map3->save, "save color map record 3 - $db_type");

  my $colors = $o->colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'red',
     "colors 1 - $db_type");

  $colors = $o->find_colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'red',
     "find colors 1 - $db_type");

  $colors = $o->find_colors([ name => { like => 'r%' } ]);

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'red',
     "find colors 2 - $db_type");

  $colors = $o->find_colors(query => [ name => { like => 'r%' } ], cache => 1);

  my $colors2 = $o->find_colors(from_cache => 1);

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'red' &&
     ref $colors2 eq 'ARRAY' && @$colors2 == 1 && $colors2->[0]->name eq 'red' &&
     $colors->[0] eq $colors2->[0],
     "find colors from cache - $db_type");

  ok(my $iterator = $o->colors_iterator, "get colors_iterator - $db_type");

  ok($iterator->isa('Rose::DB::Object::Iterator'),  "colors iterator isa Iterator - $db_type");

  while(my $color = $iterator->next)
  {
    ok($color->name, "color has a name (" . $color->name . ") - $db_type");
  }

  is($iterator->total, 2, "iterator total - $db_type");

  my $count = $o->colors_count;

  is($count, 2, "count colors 1 - $db_type");

  $count = $o->colors_count([ name => { like => 'r%' } ]);

  is($count, 1, "count colors 2 - $db_type");

  my @colors = $o->colors;

  ok(@colors == 2 && $colors[0]->name eq 'blue' && $colors[1]->name eq 'red',
     "colors 2 - $db_type");

  $colors = $o_x->colors;

  ok(ref $colors eq 'ARRAY' && @$colors == 1 && $colors->[0]->name eq 'pink',
     "colors 3 - $db_type");

  @colors = $o_x->colors;

  ok(@colors == 1 && $colors[0]->name eq 'pink', "colors 4 - $db_type");

  $o = MySQLiteObject->new(id => 1)->load;
  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);
  $o->save;

  #local $Rose::DB::Object::Manager::Debug = 1;

  eval
  {
    local $o->dbh->{'PrintError'} = 0;
    $o->delete(cascade => 'null');
  };

  ok($@, "delete cascade null 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MySQLiteOtherObject');

  is($count, 2, "delete cascade rollback confirm 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MySQLiteOtherObject2');

  is($count, 3, "delete cascade rollback confirm 2 - $db_type");

  ok($o->delete(cascade => 'delete'), "delete cascade delete 1 - $db_type");

  $o = MySQLiteObject->new(id => 99)->load;
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);
  $o->save;

  eval
  {
    local $o->dbh->{'PrintError'} = 0;
    $o->delete(cascade => 'null');
  };

  ok($@, "delete cascade null 2 - $db_type");

  ok($o->delete(cascade => 'delete'), "delete cascade delete 2 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MySQLiteColorMap');

  is($count, 0, "delete cascade confirm 1 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MySQLiteOtherObject2');

  is($count, 0, "delete cascade confirm 2 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db => $o->db,
      object_class => 'MySQLiteOtherObject');

  is($count, 0, "delete cascade confirm 3 - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # Start foreign key method tests

  #
  # Foreign key get_set_now
  #

  $o = MySQLiteObject->new(id   => 50,
                       name => 'Alex',
                       flag => 1);

  eval { $o->other_obj('abc') };
  ok($@, "set foreign key object: one arg - $db_type");

  eval { $o->other_obj(k1 => 1, k2 => 2, k3 => 3) };
  ok($@, "set foreign key object: no save - $db_type");

  $o->save;

  eval
  {
    local $o->db->dbh->{'PrintError'} = 0;
    $o->other_obj(k1 => 1, k2 => 2);
  };

  ok($@, "set foreign key object: too few keys - $db_type");

  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "set foreign key object 1 - $db_type");
  ok($o->fkone == 1 && $o->fk2 == 2 && $o->fk3 == 3, "set foreign key object check keys 1 - $db_type");

  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "set foreign key object 2 - $db_type");
  ok($o->fkone == 1 && $o->fk2 == 2 && $o->fk3 == 3, "set foreign key object check keys 2 - $db_type");

  #
  # Foreign key delete_now
  #

  ok($o->delete_other_obj, "delete foreign key object 1 - $db_type");

  ok(!defined $o->fkone && !defined $o->fk2 && !defined $o->fk3, "delete foreign key object check keys 1 - $db_type");

  ok(!defined $o->other_obj && defined $o->error, "delete foreign key object confirm 1 - $db_type");

  ok(!defined $o->delete_other_obj, "delete foreign key object 2 - $db_type");

  #
  # Foreign key get_set_on_save
  #

  # TEST: Set, save
  $o = MySQLiteObject->new(id   => 100,
                       name => 'Bub',
                       flag => 1);

  ok($o->other_obj_on_save(k1 => 21, k2 => 22, k3 => 23), "set foreign key object on save 1 - $db_type");

  my $co = MySQLiteObject->new(id => 100);
  ok(!$co->load(speculative => 1), "set foreign key object on save 2 - $db_type");

  my $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 21 && $other_obj->k2 == 22 && $other_obj->k3 == 23,
     "set foreign key object on save 3 - $db_type");

  ok($o->save, "set foreign key object on save 4 - $db_type");

  $o = MySQLiteObject->new(id => 100);

  $o->load;

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj && $other_obj->k1 == 21 && $other_obj->k2 == 22 && $other_obj->k3 == 23,
     "set foreign key object on save 5 - $db_type");

  # TEST: Set, set to undef, save
  $o = MySQLiteObject->new(id   => 200,
                       name => 'Rose',
                       flag => 1);

  ok($o->other_obj_on_save(k1 => 51, k2 => 52, k3 => 53), "set foreign key object on save 6 - $db_type");

  $co = MySQLiteObject->new(id => 200);
  ok(!$co->load(speculative => 1), "set foreign key object on save 7 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 51 && $other_obj->k2 == 52 && $other_obj->k3 == 53,
     "set foreign key object on save 8 - $db_type");

  $o->other_obj_on_save(undef);

  ok($o->save, "set foreign key object on save 9 - $db_type");

  $o = MySQLiteObject->new(id => 200);

  $o->load;

  ok(!defined $o->other_obj_on_save, "set foreign key object on save 10 - $db_type");

  $co = MySQLiteOtherObject->new(k1 => 51, k2 => 52, k3 => 53);
  ok(!$co->load(speculative => 1), "set foreign key object on save 11 - $db_type");

  $o->delete(cascade => 1);

  # TEST: Set, delete, save
  $o = MySQLiteObject->new(id   => 200,
                       name => 'Rose',
                       flag => 1);

  ok($o->other_obj_on_save(k1 => 51, k2 => 52, k3 => 53), "set foreign key object on save 12 - $db_type");

  $co = MySQLiteObject->new(id => 200);
  ok(!$co->load(speculative => 1), "set foreign key object on save 13 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok($other_obj && $other_obj->k1 == 51 && $other_obj->k2 == 52 && $other_obj->k3 == 53,
     "set foreign key object on save 14 - $db_type");

  ok($o->delete_other_obj, "set foreign key object on save 15 - $db_type");

  $other_obj = $o->other_obj_on_save;

  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "set foreign key object on save 16 - $db_type");

  ok($o->save, "set foreign key object on save 17 - $db_type");

  $o = MySQLiteObject->new(id => 200);

  $o->load;

  ok(!defined $o->other_obj_on_save, "set foreign key object on save 18 - $db_type");

  $co = MySQLiteOtherObject->new(k1 => 51, k2 => 52, k3 => 53);
  ok(!$co->load(speculative => 1), "set foreign key object on save 19 - $db_type");

  $o->delete(cascade => 1);

  #
  # Foreign key delete_on_save
  #

  $o = MySQLiteObject->new(id   => 500,
                       name => 'Kip',
                       flag => 1);

  $o->other_obj_on_save(k1 => 7, k2 => 8, k3 => 9);
  $o->save;

  $o = MySQLiteObject->new(id => 500);
  $o->load;

  # TEST: Delete, save
  $o->del_other_obj_on_save;

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete foreign key object on save 1 - $db_type");

  # ...but that the foreign object has not yet been deleted
  $co = MySQLiteOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok($co->load(speculative => 1), "delete foreign key object on save 2 - $db_type");

  # Do the save
  ok($o->save, "delete foreign key object on save 3 - $db_type");

  # Now it's deleted
  $co = MySQLiteOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok(!$co->load(speculative => 1), "delete foreign key object on save 4 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete foreign key object on save 5 - $db_type");

  # RESET
  $o->delete;

  $o = MySQLiteObject->new(id   => 700,
                       name => 'Ham',
                       flag => 0);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MySQLiteObject->new(id => 700);
  $o->load;

  # TEST: Delete, set on save, delete, save
  ok($o->del_other_obj_on_save, "delete 2 foreign key object on save 1 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete 2 foreign key object on save 2 - $db_type");

  # ...but that the foreign object has not yet been deleted
  $co = MySQLiteOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 3 - $db_type");

  # Set on save
  $o->other_obj_on_save(k1 => 44, k2 => 55, k3 => 66);

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are set...
  ok($other_obj &&  $other_obj->k1 == 44 && $other_obj->k2 == 55 && $other_obj->k3 == 66,
     "delete 2 foreign key object on save 4 - $db_type");

  # ...and that the foreign object has not yet been saved
  $co = MySQLiteOtherObject->new(k1 => 44, k2 => 55, k3 => 66);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 5 - $db_type");

  # Delete again
  ok($o->del_other_obj_on_save, "delete 2 foreign key object on save 6 - $db_type");

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are undef...
  ok(!defined $other_obj && !defined $o->fkone && !defined $o->fk2 && !defined $o->fk3,
     "delete 2 foreign key object on save 7 - $db_type");

  # Confirm that the foreign objects have not been saved
  $co = MySQLiteOtherObject->new(k1 => 7, k2 => 8, k3 => 9);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 8 - $db_type");
  $co = MySQLiteOtherObject->new(k1 => 44, k2 => 55, k3 => 66);
  ok(!$co->load(speculative => 1), "delete 2 foreign key object on save 9 - $db_type");

  # RESET
  $o->delete;

  $o = MySQLiteObject->new(id   => 800,
                       name => 'Lee',
                       flag => 1);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MySQLiteObject->new(id => 800);
  $o->load;

  # TEST: Set & save, delete on save, set on save, delete on save, save
  ok($o->other_obj(k1 => 1, k2 => 2, k3 => 3), "delete 3 foreign key object on save 1 - $db_type");

  # Confirm that both foreign objects are in the db
  $co = MySQLiteOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 2 - $db_type");
  $co = MySQLiteOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok($co->load(speculative => 1), "delete 3 foreign key object on save 3 - $db_type");

  # Delete on save
  $o->del_other_obj_on_save;

  # Set-on-save to old value
  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);

  # Delete on save
  $o->del_other_obj_on_save;  

  # Save
  $o->save;

  # Confirm that both foreign objects have been deleted
  $co = MySQLiteOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok(!$co->load(speculative => 1), "delete 3 foreign key object on save 4 - $db_type");
  $co = MySQLiteOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok(!$co->load(speculative => 1), "delete 3 foreign key object on save 5 - $db_type");

  # RESET
  $o->delete;

  $o = MySQLiteObject->new(id   => 900,
                       name => 'Kai',
                       flag => 1);

  $o->other_obj_on_save(k1 => 12, k2 => 34, k3 => 56);
  $o->save;

  $o = MySQLiteObject->new(id => 900);
  $o->load;

  # TEST: Delete on save, set on save, delete on save, set to same one, save
  $o->del_other_obj_on_save;

  # Set on save
  ok($o->other_obj_on_save(k1 => 1, k2 => 2, k3 => 3), "delete 4 foreign key object on save 1 - $db_type");

  # Delete on save
  $o->del_other_obj_on_save;

  # Set-on-save to previous value
  $o->other_obj_on_save(k1 => 1, k2 => 2, k3 => 3);

  # Save
  $o->save;

  $other_obj = $o->other_obj_on_save;

  # Confirm that fk attrs are set...
  ok($other_obj &&  $other_obj->k1 == 1 && $other_obj->k2 == 2 && $other_obj->k3 == 3,
     "delete 4 foreign key object on save 2 - $db_type");

  # Confirm that the new foreign object is there and the old one is not
  $co = MySQLiteOtherObject->new(k1 => 1, k2 => 2, k3 => 3);
  ok($co->load(speculative => 1), "delete 4 foreign key object on save 3 - $db_type");
  $co = MySQLiteOtherObject->new(k1 => 12, k2 => 34, k3 => 56);
  ok(!$co->load(speculative => 1), "delete 4 foreign key object on save 4 - $db_type");

  # End foreign key method tests

  # Start "one to many" method tests

  #
  # "one to many" get_set_now
  #

  #local $Rose::DB::Object::Debug = 1;
  #local $Rose::DB::Object::Manager::Debug = 1;

  # SETUP
  $o = MySQLiteObject->new(id   => 111,
                       name => 'Boo',
                       flag => 1);

  @o2s = 
  (
    1,
    MySQLiteOtherObject2->new(id => 2, name => 'two'),
    { id => 3, name => 'three' },
  );

  # Set before save, save, set
  eval { $o->other2_objs_now(@o2s) };
  ok($@, "set one to many now 1 - $db_type");

  $o->save;

  ok($o->other2_objs_now(@o2s), "set one to many now 2 - $db_type");

  @o2s = $o->other2_objs_now;
  ok(@o2s == 3, "set one to many now 3 - $db_type");

  ok($o2s[0]->id == 2 && $o2s[0]->pid == 111, "set one to many now 4 - $db_type");
  ok($o2s[1]->id == 3 && $o2s[1]->pid == 111, "set one to many now 5 - $db_type");
  ok($o2s[2]->id == 1 && $o2s[2]->pid == 111, "set one to many now 6 - $db_type");

  my @fos = $o->find_other2_objs(query    => [ id => { gt => 1 } ],
                                 sort_by  => 'id desc', 
                                 share_db => 0);

  ok($fos[0]->id == 3 && $fos[0]->pid == 111, "find one to many 1 - $db_type");
  ok($fos[1]->id == 2 && $fos[1]->pid == 111, "find one to many 2 - $db_type");
  ok(!defined $fos[0]->{'db'}, "find one to many 3 - $db_type");
  ok(!defined $fos[1]->{'db'}, "find one to many 4 - $db_type");

  @fos = $o->find_other2_objs([ id => { gt => 1 } ],
                              sort_by  => 'id desc', 
                              share_db => 0);

  ok($fos[0]->id == 3 && $fos[0]->pid == 111, "find one to many array query 1 - $db_type");
  ok($fos[1]->id == 2 && $fos[1]->pid == 111, "find one to many array query 2 - $db_type");
  ok(!defined $fos[0]->{'db'}, "find one to many array query 3 - $db_type");
  ok(!defined $fos[1]->{'db'}, "find one to many array query 4 - $db_type");

  @fos = $o->find_other2_objs([ id => 2 ]);

  ok($fos[0]->id == 2 && $fos[0]->pid == 111, "find one to many array query 5 - $db_type");

  @fos = $o->find_other2_objs({ id => { gt => 1 } },
                              sort_by  => 'id desc', 
                              share_db => 0);

  ok($fos[0]->id == 3 && $fos[0]->pid == 111, "find one to many hash query 1 - $db_type");
  ok($fos[1]->id == 2 && $fos[1]->pid == 111, "find one to many hash query 2 - $db_type");
  ok(!defined $fos[0]->{'db'}, "find one to many hash query 3 - $db_type");
  ok(!defined $fos[1]->{'db'}, "find one to many hash query 4 - $db_type");

  @fos = $o->find_other2_objs({ id => 2 });

  ok($fos[0]->id == 2 && $fos[0]->pid == 111, "find one to many hash query 5 - $db_type");

  @fos = $o->find_other2_objs(query    => [ id => { le => 2 } ],
                              sort_by  => 'id desc', 
                              cache    => 1);

  ok($fos[0]->id == 2 && $fos[0]->pid == 111, "find one to many cache 1 - $db_type");
  ok($fos[1]->id == 1 && $fos[1]->pid == 111, "find one to many cache 2 - $db_type");

  my @fos2 = $o->find_other2_objs(from_cache => 1);

  ok($fos2[0] eq $fos[0], "find one to many from_cache 1 - $db_type");
  ok($fos2[1] eq $fos[1], "find one to many from_cache 2 - $db_type");

  ok(my $o2objects_iterator = $o->other2_objs_iterator, "other2_objs_iterator - $db_type");
  ok($o2objects_iterator->isa('Rose::DB::Object::Iterator'), "isa Iterator - $db_type");

  while(my $o2i = $o2objects_iterator->next)
  {
    ok($o2i->isa('MySQLiteOtherObject2'), "isa MySQLiteOtherObject2 - $db_type");
  }

  is($o2objects_iterator->total, 3, "MySQLiteOtherObject2 iterator total - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 7 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 2)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 8 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 3)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 9 - $db_type");

  my $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 111');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 3, "set one to many now 10 - $db_type");

  # Set to undef
  $o->other2_objs_now(undef);

  @o2s = $o->other2_objs_now;
  ok(@o2s == 3, "set one to many now 11 - $db_type");

  ok($o2s[0]->id == 2 && $o2s[0]->pid == 111, "set one to many now 12 - $db_type");
  ok($o2s[1]->id == 3 && $o2s[1]->pid == 111, "set one to many now 13 - $db_type");
  ok($o2s[2]->id == 1 && $o2s[2]->pid == 111, "set one to many now 14 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 15 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 2)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 16 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 3)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many now 17 - $db_type");

  # RESET
  $o = MySQLiteObject->new(id => 111)->load;

  # Set (one existing, one new)
  @o2s = 
  (
    MySQLiteOtherObject2->new(id => 1, name => 'one'),
    MySQLiteOtherObject2->new(id => 7, name => 'seven'),
  );

  ok($o->other2_objs_now(\@o2s), "set 2 one to many now 1 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 1)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many now 2 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many now 3 - $db_type");

  @o2s = $o->other2_objs_now;
  ok(@o2s == 2, "set 2 one to many now 4 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 111, "set 2 one to many now 5 - $db_type");
  ok($o2s[1]->id == 1 && $o2s[1]->pid == 111, "set 2 one to many now 6 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 111');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 2, "set 2 one to many now 7 - $db_type");

  #
  # "one to many" get_set_on_save
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MySQLiteObject->new(id   => 222,
                       name => 'Hap',
                       flag => 1);

  @o2s = 
  (
    MySQLiteOtherObject2->new(id => 5, name => 'five'),
    MySQLiteOtherObject2->new(id => 6, name => 'six'),
    MySQLiteOtherObject2->new(id => 7, name => 'seven'),
  );

  $o->other2_objs_on_save(@o2s);

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 3, "set one to many on save 1 - $db_type");

  ok($o2s[0]->id == 5 && $o2s[0]->pid == 222, "set one to many on save 2 - $db_type");
  ok($o2s[1]->id == 6 && $o2s[1]->pid == 222, "set one to many on save 3 - $db_type");
  ok($o2s[2]->id == 7 && $o2s[2]->pid == 222, "set one to many on save 4 - $db_type");

  ok(!MySQLiteOtherObject2->new(id => 5)->load(speculative => 1), "set one to many on save 5 - $db_type");
  ok(!MySQLiteOtherObject2->new(id => 6)->load(speculative => 1), "set one to many on save 6 - $db_type");
  ok(!MySQLiteOtherObject2->new(id => 7)->load(speculative => 1), "set one to many on save 7 - $db_type");

  $o->save;

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 3, "set one to many on save 8 - $db_type");

  ok($o2s[0]->id == 6 && $o2s[0]->pid == 222, "set one to many on save 9 - $db_type");
  ok($o2s[1]->id == 7 && $o2s[1]->pid == 222, "set one to many on save 10 - $db_type");
  ok($o2s[2]->id == 5 && $o2s[2]->pid == 222, "set one to many on save 11 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 5)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 12 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 6)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 13 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set one to many on save 14 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 3, "set one to many on save 15 - $db_type");

  # RESET
  $o = MySQLiteObject->new(id => 222)->load;

  # Set (one existing, one new)
  @o2s = 
  (
    MySQLiteOtherObject2->new(id => 7, name => 'seven'),
    MySQLiteOtherObject2->new(id => 12, name => 'one'),
  );

  ok($o->other2_objs_on_save(\@o2s), "set 2 one to many on save 1 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 2 - $db_type");

  ok(!MySQLiteOtherObject2->new(id => 12)->load(speculative => 1), "set 2 one to many on save 3 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 3, "set 2 one to many on save 4 - $db_type");

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set 2 one to many on save 5 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 6 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 7 - $db_type");

  $o->save;

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set one to many on save 8 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 9 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 10 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 11 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 12)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 12 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_other2 WHERE pid = 222');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 2, "set one to many on save 15 - $db_type");

  # Set to undef
  $o->other2_objs_on_save(undef);

  @o2s = $o->other2_objs_on_save;
  ok(@o2s == 2, "set one to many on save 16 - $db_type");

  ok($o2s[0]->id == 7 && $o2s[0]->pid == 222, "set 2 one to many on save 17 - $db_type");
  ok($o2s[1]->id == 12 && $o2s[1]->pid == 222, "set 2 one to many on save 18 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 7)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 19 - $db_type");

  $o2 = MySQLiteOtherObject2->new(id => 12)->load(speculative => 1);
  ok($o2 && $o2->pid == $o->id, "set 2 one to many on save 20 - $db_type");

  $o->save;

  @o2s = $o->other2_objs_on_save;

  push(@o2s, MySQLiteOtherObject2->new(name => 'added'));
  $o->other2_objs_on_save(\@o2s);

  $o->save;

  my $to = MySQLiteObject->new(id => $o->id)->load;
  @o2s = $o->other2_objs_on_save;

  is_deeply([ 'seven', 'one', 'added' ], [ map { $_->name } @o2s ], "add one to many on save 1 - $db_type");

  #
  # "one to many" add_now
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MySQLiteObject->new(id   => 333,
                       name => 'Zoom',
                       flag => 1);

  $o->save;

  @o2s = 
  (
    MySQLiteOtherObject2->new(id => 5, name => 'five'),
    MySQLiteOtherObject2->new(id => 6, name => 'six'),
    MySQLiteOtherObject2->new(id => 7, name => 'seven'),
  );

  $o->other2_objs_now(@o2s);

  # RESET
  $o = MySQLiteObject->new(id   => 333,
                       name => 'Zoom',
                       flag => 1);

  # Add, no args
  @o2s = ();
  ok($o->add_other2_objs_now(@o2s) == 0, "add one to many now 1 - $db_type");

  # Add before load/save
  @o2s = 
  (
    MySQLiteOtherObject2->new(id => 8, name => 'eight'),
  );

  eval { $o->add_other2_objs_now(@o2s) };

  ok($@, "add one to many now 2 - $db_type");

  # Add
  $o->load;

  my $num = $o->add_other2_objs_now(@o2s);
  is($num, scalar @o2s, "add one to many now count - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 4, "add one to many now 3 - $db_type");

  ok($o2s[0]->id == 6 && $o2s[0]->pid == 333, "add one to many now 4 - $db_type");
  ok($o2s[1]->id == 7 && $o2s[1]->pid == 333, "add one to many now 5 - $db_type");
  ok($o2s[2]->id == 5 && $o2s[2]->pid == 333, "add one to many now 6 - $db_type");
  ok($o2s[3]->id == 8 && $o2s[3]->pid == 333, "add one to many now 7 - $db_type");

  ok(MySQLiteOtherObject2->new(id => 6)->load(speculative => 1), "add one to many now 8 - $db_type");
  ok(MySQLiteOtherObject2->new(id => 7)->load(speculative => 1), "add one to many now 9 - $db_type");
  ok(MySQLiteOtherObject2->new(id => 5)->load(speculative => 1), "add one to many now 10 - $db_type");
  ok(MySQLiteOtherObject2->new(id => 8)->load(speculative => 1), "add one to many now 11 - $db_type");

  #
  # "one to many" add_on_save
  #

  # SETUP
  $o2->db->dbh->do('DELETE FROM rose_db_object_other2');

  $o = MySQLiteObject->new(id   => 444,
                       name => 'Blargh',
                       flag => 1);

  # Set on save, add on save, save
  @o2s = 
  (
    MySQLiteOtherObject2->new(id => 10, name => 'ten'),
  );

  # Set on save
  $o->other2_objs_on_save(@o2s);

  @o2s = $o->other2_objs;
  ok(@o2s == 1, "add one to many on save 1 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 2 - $db_type");
  ok(!MySQLiteOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 3 - $db_type");

  @o2s = 
  (
    MySQLiteOtherObject2->new(id => 9, name => 'nine'),
  );

  # Add on save
  $num = $o->add_other2_objs(@o2s);
  is($num, scalar @o2s, "add one to many on save 4 - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 5 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 6 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[0]->pid == 444, "add one to many on save 7 - $db_type");

  ok(!MySQLiteOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 8 - $db_type");
  ok(!MySQLiteOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 9 - $db_type");

  $o->save;

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 10 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 11 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 12 - $db_type");

  ok(MySQLiteOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 13 - $db_type");
  ok(MySQLiteOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 14 - $db_type");

  # RESET
  $o = MySQLiteObject->new(id   => 444,
                       name => 'Blargh',
                       flag => 1);

  $o->load;

  # Add on save, save
  @o2s = 
  (
    MySQLiteOtherObject2->new(id => 11, name => 'eleven'),
  );

  # Add on save
  ok($o->add_other2_objs(\@o2s), "add one to many on save 15 - $db_type");

  @o2s = $o->other2_objs;
  ok(@o2s == 2, "add one to many on save 16 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 17 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 18 - $db_type");

  ok(MySQLiteOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 19 - $db_type");
  ok(MySQLiteOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 20 - $db_type");
  ok(!MySQLiteOtherObject2->new(id => 11)->load(speculative => 1), "add one to many on save 21 - $db_type");

  # Save
  $o->save;

  @o2s = $o->other2_objs;
  ok(@o2s == 3, "add one to many on save 22 - $db_type");

  ok($o2s[0]->id == 10 && $o2s[0]->pid == 444, "add one to many on save 23 - $db_type");
  ok($o2s[1]->id == 9 && $o2s[1]->pid == 444, "add one to many on save 24 - $db_type");
  ok($o2s[2]->id == 11 && $o2s[2]->pid == 444, "add one to many on save 25 - $db_type");

  ok(MySQLiteOtherObject2->new(id => 10)->load(speculative => 1), "add one to many on save 26 - $db_type");
  ok(MySQLiteOtherObject2->new(id => 9)->load(speculative => 1), "add one to many on save 27 - $db_type");
  ok(MySQLiteOtherObject2->new(id => 11)->load(speculative => 1), "add one to many on save 28 - $db_type");

  # End "one to many" method tests

  # Start "load with ..." tests

  ok($o = MySQLiteObject->new(id => 444)->load(with => [ qw(other_obj other2_objs colors) ]),
     "load with 1 - $db_type");

  $o->{'other2_objs'} = [ sort { $a->{'name'} cmp $b->{'name'} } @{$o->{'other2_objs'}} ];

  ok($o->{'other2_objs'} && $o->{'other2_objs'}[1]->name eq 'nine',
     "load with 2 - $db_type");

  $o = MySQLiteObject->new(id => 999);

  ok(!$o->load(with => [ qw(other_obj other2_objs colors) ], speculative => 1),
     "load with 3 - $db_type");

  $o = MySQLiteObject->new(id => 222);

  ok($o->load(with => 'colors'), "load with 4 - $db_type");

  # End "load with ..." tests

  # Start "many to many" tests

  #
  # "many to many" get_set_now
  #

  # SETUP

  $o = MySQLiteObject->new(id   => 30,
                             name => 'Color',
                             flag => 1);

  # Set
  @colors =
  (
    1, # red
    MySQLiteColor->new(id => 3), # blue
    { id => 5, name => 'orange' },
  );

  #MySQLiteColor->new(id => 2), # green
  #MySQLiteColor->new(id => 4), # pink

  # Set before save, save, set
  eval { $o->colors_now(@colors) };
  ok($@, "set many to many now 1 - $db_type");

  $o->save;

  ok($o->colors_now(@colors), "set many to many now 2 - $db_type");

  @colors = $o->colors_now;
  ok(@colors == 3, "set many to many now 3 - $db_type");

  ok($colors[0]->id == 3, "set many to many now 4 - $db_type");
  ok($colors[1]->id == 5, "set many to many now 5 - $db_type");
  ok($colors[2]->id == 1, "set many to many now 6 - $db_type");

  $color = MySQLiteColor->new(id => 5);
  ok($color->load(speculative => 1), "set many to many now 7 - $db_type");

  ok(MySQLiteColorMap->new(obj_id => 30, color_id => 3)->load(speculative => 1),
     "set many to many now 8 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 30, color_id => 5)->load(speculative => 1),
     "set many to many now 9 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 30, color_id => 1)->load(speculative => 1),
     "set many to many now 10 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 30');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 3, "set many to many now 11 - $db_type");

  # Set to undef
  $o->colors_now(undef);

  @colors = $o->colors_now;
  ok(@colors == 3, "set 2 many to many now 1 - $db_type");

  ok($colors[0]->id == 3, "set 2 many to many now 2 - $db_type");
  ok($colors[1]->id == 5, "set 2 many to many now 3 - $db_type");
  ok($colors[2]->id == 1, "set 2 many to many now 4 - $db_type");

  $color = MySQLiteColor->new(id => 5);
  ok($color->load(speculative => 1), "set 2 many to many now 5 - $db_type");

  $color = MySQLiteColor->new(id => 3);
  ok($color->load(speculative => 1), "set 2 many to many now 6 - $db_type");

  $color = MySQLiteColor->new(id => 1);
  ok($color->load(speculative => 1), "set 2 many to many now 7 - $db_type");

  ok(MySQLiteColorMap->new(obj_id => 30, color_id => 3)->load(speculative => 1),
     "set 2 many to many now 8 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 30, color_id => 5)->load(speculative => 1),
     "set 2 many to many now 9 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 30, color_id => 1)->load(speculative => 1),
     "set 2 many to many now 10 - $db_type");

  $sth = $o2->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 30');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 3, "set 2 many to many now 11 - $db_type");

  #
  # "many to many" get_set_on_save
  #

  # SETUP
  $o = MySQLiteObject->new(id   => 40,
                             name => 'Cool',
                             flag => 1);

  # Set
  @colors =
  (
    MySQLiteColor->new(id => 1), # red
    3, # blue
    { id => 6, name => 'ochre' },
  );

  #MySQLiteColor->new(id => 2), # green
  #MySQLiteColor->new(id => 4), # pink

  $o->colors_on_save(@colors);

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set many to many on save 1 - $db_type");

  ok($colors[0]->id == 1, "set many to many on save 2 - $db_type");
  ok($colors[1]->id == 3, "set many to many on save 3 - $db_type");
  ok($colors[2]->id == 6, "set many to many on save 4 - $db_type");

  ok(MySQLiteColor->new(id => 1)->load(speculative => 1), "set many to many on save 5 - $db_type");
  ok(MySQLiteColor->new(id => 3)->load(speculative => 1), "set many to many on save 6 - $db_type");
  ok(!MySQLiteColor->new(id => 6)->load(speculative => 1), "set many to many on save 7 - $db_type");

  ok(!MySQLiteColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set many to many on save 8 - $db_type");
  ok(!MySQLiteColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set many to many on save 9 - $db_type");
  ok(!MySQLiteColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set many to many on save 10 - $db_type");

  $o->save;

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set many to many on save 11 - $db_type");

  ok($colors[0]->id == 3, "set many to many on save 12 - $db_type");
  ok($colors[1]->id == 6, "set many to many on save 13 - $db_type");
  ok($colors[2]->id == 1, "set many to many on save 14 - $db_type");

  ok(MySQLiteColor->new(id => 1)->load(speculative => 1), "set many to many on save 15 - $db_type");
  ok(MySQLiteColor->new(id => 3)->load(speculative => 1), "set many to many on save 16 - $db_type");
  ok(MySQLiteColor->new(id => 6)->load(speculative => 1), "set many to many on save 17 - $db_type");

  ok(MySQLiteColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 18 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 19 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set 2 many to many on save 20 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 40');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 3, "set many to many on save 21 - $db_type");

  # RESET
  $o = MySQLiteObject->new(id => 40)->load;

  # Set to undef
  $o->colors_on_save(undef);

  @colors = $o->colors_on_save;
  ok(@colors == 3, "set 2 many to many on save 1 - $db_type");

  ok($colors[0]->id == 3, "set 2 many to many on save 2 - $db_type");
  ok($colors[1]->id == 6, "set 2 many to many on save 3 - $db_type");
  ok($colors[2]->id == 1, "set 2 many to many on save 4 - $db_type");

  ok(MySQLiteColor->new(id => 1)->load(speculative => 1), "set 2 many to many on save 5 - $db_type");
  ok(MySQLiteColor->new(id => 3)->load(speculative => 1), "set 2 many to many on save 6 - $db_type");
  ok(MySQLiteColor->new(id => 6)->load(speculative => 1), "set 2 many to many on save 7 - $db_type");

  ok(MySQLiteColorMap->new(obj_id => 40, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 8 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 40, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 9 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 40, color_id => 6)->load(speculative => 1),
     "set 2 many to many on save 10 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 40');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 3, "set 2 many to many on save 11 - $db_type");

  $o->colors([]);
  $o->save(changes_only => 1);

  $o->colors_on_save({ id => 1, name => 'redx' }, { id => 3 });
  $o->save(changes_only => 1);

  $o->colors_on_save(undef);
  $colors = $o->colors_on_save;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'blue' && $colors->[1]->name eq 'redx',
     "colors merge 1 - $db_type");

  $o->colors_on_save({ id => 2 }, { id => 3, name => 'bluex' });
  $o->save(changes_only => 1);

  $o->colors_on_save(undef);
  $colors = $o->colors_on_save;

  ok(ref $colors eq 'ARRAY' && @$colors == 2 && 
     $colors->[0]->name eq 'bluex' && $colors->[1]->name eq 'green',
     "colors merge 2 - $db_type");

  #
  # "many to many" add_now
  #

  # SETUP
  $o = MySQLiteObject->new(id   => 50,
                             name => 'Blat',
                             flag => 1);

  $o->delete;

  @colors =
  (
    MySQLiteColor->new(id => 1), # red
    MySQLiteColor->new(id => 3), # blue  
  );

  #MySQLiteColor->new(id => 4), # pink

  $o->colors_on_save(\@colors);
  $o->save;

  $o = MySQLiteObject->new(id   => 50,
                             name => 'Blat',
                             flag => 1);
  # Add, no args
  @colors = ();
  ok($o->add_colors(@colors) == 0, "add many to many now 1 - $db_type");

  # Add before load/save
  @colors = 
  (
    MySQLiteColor->new(id => 7, name => 'puce'),
    MySQLiteColor->new(id => 2), # green
  );

  eval { $o->add_colors(@colors) };

  ok($@, "add many to many now 2 - $db_type");

  # Add
  $o->load;

  $o->add_colors(@colors);

  @colors = $o->colors;
  ok(@colors == 4, "add many to many now 3 - $db_type");

  ok($colors[0]->id == 3, "add many to many now 4 - $db_type");
  ok($colors[1]->id == 2, "add many to many now 5 - $db_type");
  ok($colors[2]->id == 7, "add many to many now 6 - $db_type");
  ok($colors[3]->id == 1, "add many to many now 7 - $db_type");

  ok(MySQLiteColor->new(id => 3)->load(speculative => 1), "add many to many now 8 - $db_type");
  ok(MySQLiteColor->new(id => 2)->load(speculative => 1), "add many to many now 9 - $db_type");
  ok(MySQLiteColor->new(id => 7)->load(speculative => 1), "add many to many now 10 - $db_type");
  ok(MySQLiteColor->new(id => 1)->load(speculative => 1), "add many to many now 11 - $db_type");

  ok(MySQLiteColorMap->new(obj_id => 50, color_id => 3)->load(speculative => 1),
     "set 2 many to many on save 12 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 50, color_id => 2)->load(speculative => 1),
     "set 2 many to many on save 13 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 50, color_id => 7)->load(speculative => 1),
     "set 2 many to many on save 14 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 50, color_id => 1)->load(speculative => 1),
     "set 2 many to many on save 15 - $db_type");

  #
  # "many to many" add_on_save
  #

  # SETUP
  $o = MySQLiteObject->new(id   => 60,
                             name => 'Cretch',
                             flag => 1);

  $o->delete;

  # Set on save, add on save, save
  @colors = 
  (
    MySQLiteColor->new(id => 1), # red
    MySQLiteColor->new(id => 2), # green
  );

  # Set on save
  $o->colors_on_save(@colors);

  @colors = 
  (
    MySQLiteColor->new(id => 7), # puce
    MySQLiteColor->new(id => 8, name => 'tan'),
  );

  # Add on save
  ok($o->add_colors_on_save(@colors), "add many to many on save 1 - $db_type");

  @colors = $o->colors;
  ok(@colors == 4, "add many to many on save 2 - $db_type");

  ok($colors[0]->id == 1, "add many to many on save 3 - $db_type");
  ok($colors[1]->id == 2, "add many to many on save 4 - $db_type");
  ok($colors[2]->id == 7, "add many to many on save 5 - $db_type");
  ok($colors[3]->id == 8, "add many to many on save 6 - $db_type");

  ok(MySQLiteColor->new(id => 1)->load(speculative => 1), "add many to many on save 7 - $db_type");
  ok(MySQLiteColor->new(id => 2)->load(speculative => 1), "add many to many on save 8 - $db_type");
  ok(MySQLiteColor->new(id => 7)->load(speculative => 1), "add many to many on save 9 - $db_type");
  ok(!MySQLiteColor->new(id => 8)->load(speculative => 1), "add many to many on save 10 - $db_type");

  ok(!MySQLiteColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "set many to many on save 11 - $db_type");
  ok(!MySQLiteColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "set many to many on save 12 - $db_type");
  ok(!MySQLiteColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "set many to many on save 13 - $db_type");
  ok(!MySQLiteColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "set many to many on save 14 - $db_type");

  $o->save;

  @colors = $o->colors;
  ok(@colors == 4, "add many to many on save 15 - $db_type");

  ok($colors[0]->id == 2, "add many to many on save 16 - $db_type");
  ok($colors[1]->id == 7, "add many to many on save 17 - $db_type");
  ok($colors[2]->id == 1, "add many to many on save 18 - $db_type");
  ok($colors[3]->id == 8, "add many to many on save 19 - $db_type");

  ok(MySQLiteColor->new(id => 2)->load(speculative => 1), "add many to many on save 20 - $db_type");
  ok(MySQLiteColor->new(id => 7)->load(speculative => 1), "add many to many on save 21 - $db_type");
  ok(MySQLiteColor->new(id => 1)->load(speculative => 1), "add many to many on save 22 - $db_type");
  ok(MySQLiteColor->new(id => 8)->load(speculative => 1), "add many to many on save 21 - $db_type");

  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add many to many on save 22 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add many to many on save 23 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add many to many on save 24 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add many to many on save 25 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 4, "add many to many on save 26 - $db_type");

  # RESET
  $o = MySQLiteObject->new(id   => 60,
                             name => 'Cretch',
                             flag => 1);

  $o->load(with => 'colors');

  # Add on save, save
  @colors = 
  (
    MySQLiteColor->new(id => 9, name => 'aqua'),
  );

  # Add on save
  ok($o->add_colors_on_save(@colors), "add 2 many to many on save 1 - $db_type");

  @colors = $o->colors;
  ok(@colors == 5, "add 2 many to many on save 16 - $db_type");

  @colors = sort { $a->{'name'} cmp $b->{'name'} } @colors;

  ok($colors[0]->id == 9, "add 2 many to many on save 2 - $db_type");
  ok($colors[1]->id == 2, "add 2 many to many on save 3 - $db_type");
  ok($colors[2]->id == 7, "add 2 many to many on save 4 - $db_type");
  ok($colors[3]->id == 1, "add 2 many to many on save 5 - $db_type");
  ok($colors[4]->id == 8, "add 2 many to many on save 6 - $db_type");

  ok(!MySQLiteColor->new(id => 9)->load(speculative => 1), "add many to many on save 7 - $db_type");
  ok(MySQLiteColor->new(id => 2)->load(speculative => 1), "add many to many on save 8 - $db_type");
  ok(MySQLiteColor->new(id => 7)->load(speculative => 1), "add many to many on save 9 - $db_type");
  ok(MySQLiteColor->new(id => 1)->load(speculative => 1), "add many to many on save 10 - $db_type");
  ok(MySQLiteColor->new(id => 8)->load(speculative => 1), "add many to many on save 11 - $db_type");

  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add 2 many to many on save 12 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add 2 many to many on save 13 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add 2 many to many on save 14 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add 2 many to many on save 15 - $db_type");
  ok(!MySQLiteColorMap->new(obj_id => 60, color_id => 9)->load(speculative => 1),
     "add 2 many to many on save 16 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 4, "add 2 many to many on save 17 - $db_type");

  # Save
  $o->save;

  @colors = $o->colors;
  ok(@colors == 5, "add 2 many to many on save 18 - $db_type");

  ok($colors[0]->id == 9, "add 2 many to many on save 19 - $db_type");
  ok($colors[1]->id == 2, "add 2 many to many on save 20 - $db_type");
  ok($colors[2]->id == 7, "add 2 many to many on save 21 - $db_type");
  ok($colors[3]->id == 1, "add 2 many to many on save 22 - $db_type");
  ok($colors[4]->id == 8, "add 2 many to many on save 23 - $db_type");

  ok(MySQLiteColor->new(id => 9)->load(speculative => 1), "add many to many on save 24 - $db_type");
  ok(MySQLiteColor->new(id => 2)->load(speculative => 1), "add many to many on save 25 - $db_type");
  ok(MySQLiteColor->new(id => 7)->load(speculative => 1), "add many to many on save 26 - $db_type");
  ok(MySQLiteColor->new(id => 1)->load(speculative => 1), "add many to many on save 27 - $db_type");
  ok(MySQLiteColor->new(id => 8)->load(speculative => 1), "add many to many on save 28 - $db_type");

  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 9)->load(speculative => 1),
     "add 2 many to many on save 29 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 2)->load(speculative => 1),
     "add 2 many to many on save 20 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 7)->load(speculative => 1),
     "add 2 many to many on save 31 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 1)->load(speculative => 1),
     "add 2 many to many on save 32 - $db_type");
  ok(MySQLiteColorMap->new(obj_id => 60, color_id => 8)->load(speculative => 1),
     "add 2 many to many on save 33 - $db_type");

  $sth = $color->db->dbh->prepare('SELECT COUNT(*) FROM rose_db_object_colors_map WHERE obj_id = 60');
  $sth->execute;
  $count = $sth->fetchrow_array;
  $sth->finish;
  is($count, 5, "add 2 many to many on save 34 - $db_type");

  # End "many to many" tests

  # Begin with_map_records tests

  test_memory_cycle_ok($o, "with_map_records memory cycle 1 - $db_type");

  @colors = $o->colors2;  

  is($colors[0]->map_record->color_id, $colors[0]->id, "with_map_records rel 1 - $db_type");
  is($colors[0]->map_record->obj_id, $o->id, "with_map_records rel 2 - $db_type");

  @colors = $o->colors3;  

  is($colors[-1]->map_rec->color_id, $colors[-1]->id, "with_map_records rel 3 - $db_type");
  is($colors[-1]->map_rec->obj_id, $o->id, "with_map_records rel 4 - $db_type");
  is($colors[-1]->map_rec->color_id, 1, "with_map_records rel 5 - $db_type");

  $colors[-1]->map_rec->arb_attr('new');

  $o->colors3(@colors);
  $o->save;

  $o2 = ref($o)->new(id => $o->id)->load;
  is(join(',', sort map { $_->id } $o2->colors), join(',', sort map { $_->id } @colors), "with_map_records update 1 - $db_type");

  my $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query => [ id => $o->id ],
      require_objects => [ 'colors3' ],
      with_map_records => { colors3 => 'mrec' });

  $objs->[0]->{'colors3'} = [ sort { $b->mrec->color_id <=> $a->mrec->color_id } @{$objs->[0]->{'colors3'}} ];

  is($objs->[0]->colors3->[0]->mrec->color_id, $objs->[0]->colors3->[0]->id, "with_map_records mrec 1 - $db_type");
  is($objs->[0]->colors3->[0]->mrec->obj_id, $o->id, "with_map_records mrec 2 - $db_type");
  is($objs->[0]->colors3->[0]->mrec->color_id, 9, "with_map_records mrec 3 - $db_type");
  is($objs->[0]->colors3->[-1]->mrec->color_id, 1, "with_map_records mrec 4 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query => [ id => [ $o->id, 333 ] ],
      with_objects => [ 'colors3' ],
      with_map_records => 1,
      sort_by => 'name DESC');

  is($objs->[1]->colors3->[0]->map_rec->color_id, $objs->[1]->colors3->[0]->id, "with_map_records map_rec 1 - $db_type");
  is($objs->[1]->colors3->[0]->map_rec->obj_id, $o->id, "with_map_records map_rec 2 - $db_type");
  is($objs->[1]->colors3->[0]->map_rec->color_id, 9, "with_map_records map_rec 3 - $db_type");
  is($objs->[1]->colors3->[-1]->map_rec->color_id, 1, "with_map_records map_rec 4 - $db_type");
  is($objs->[0]->name, 'Zoom', "with_map_records map_rec 5 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query => [ id => $o->id ],
      require_objects => [ 'colors2' ],
      with_map_records => 1);

  is($objs->[0]->colors2->[0]->map_record->color_id, $objs->[0]->colors2->[0]->id, "with_map_records map_record 1 - $db_type");
  is($objs->[0]->colors2->[0]->map_record->obj_id, $o->id, "with_map_records map_record 2 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query => [ id => $o->id ],
      require_objects => [ 'colors2' ],
      with_map_records => 1);

  is($objs->[0]->colors2->[0]->map_record->color_id, $objs->[0]->colors2->[0]->id, "with_map_records map_record 1 - $db_type");
  is($objs->[0]->colors2->[0]->map_record->obj_id, $o->id, "with_map_records map_record 2 - $db_type");

  my $iter = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MySQLiteObject',
      query => [ id => $o->id ],
      require_objects => [ 'colors3' ],
      with_map_records => { colors3 => 'mrec' });

  $obj = $iter->next;

  $obj->{'colors3'} = [ sort { $b->mrec->color_id <=> $a->mrec->color_id } @{$obj->{'colors3'}} ];

  is($obj->colors3->[0]->mrec->color_id, $obj->colors3->[0]->id, "with_map_records mrec 1 - $db_type");
  is($obj->colors3->[0]->mrec->obj_id, $o->id, "with_map_records mrec 2 - $db_type");
  is($obj->colors3->[0]->mrec->color_id, 9, "with_map_records mrec 3 - $db_type");
  is($obj->colors3->[-1]->mrec->color_id, 1, "with_map_records mrec 4 - $db_type");

  $iter = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MySQLiteObject',
      query => [ id => [ $o->id, 333 ] ],
      with_objects => [ 'colors3' ],
      with_map_records => 1,
      sort_by => 'name DESC');

  $obj = $iter->next;
  is($obj->name, 'Zoom', "with_map_records map_rec 5 - $db_type");

  $obj = $iter->next;
  is($obj->colors3->[0]->map_rec->color_id, $obj->colors3->[0]->id, "with_map_records map_rec 1 - $db_type");
  is($obj->colors3->[0]->map_rec->obj_id, $o->id, "with_map_records map_rec 2 - $db_type");
  is($obj->colors3->[0]->map_rec->color_id, 9, "with_map_records map_rec 3 - $db_type");
  is($obj->colors3->[-1]->map_rec->color_id, 1, "with_map_records map_rec 4 - $db_type");

  $iter = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MySQLiteObject',
      query => [ id => $o->id ],
      require_objects => [ 'colors2' ],
      with_map_records => 1);

  $obj = $iter->next;
  is($obj->colors2->[0]->map_record->color_id, $obj->colors2->[0]->id, "with_map_records map_record 1 - $db_type");
  is($obj->colors2->[0]->map_record->obj_id, $o->id, "with_map_records map_record 2 - $db_type");

  $iter = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MySQLiteObject',
      query => [ id => $o->id ],
      require_objects => [ 'colors2' ],
      with_map_records => 1);

  $obj = $iter->next;
  is($obj->colors2->[0]->map_record->color_id, $obj->colors2->[0]->id, "with_map_records map_record 1 - $db_type");
  is($obj->colors2->[0]->map_record->obj_id, $o->id, "with_map_records map_record 2 - $db_type");

  # End with_map_records tests

  # Start create with map records tests

  $o = MySQLiteObject->new(name => 'WMR');

  $o->colors3({ name => 'Gray', map_rec => { id => 999, arb_attr => 'Whee' } });

  $o->save;

  is($o->colors3->[0]->map_rec->arb_attr, 'Whee', "save with map_rec 1 - $db_type");

  $o = MySQLiteColorMap->new(id => 999)->load;

  is($o->arb_attr, 'Whee', "save with map_rec 2 - $db_type");

  # End create with map records tests

  # Start multiple add_on_save tests

  $o = MySQLiteObject->new(name => 'John', id => 10);

  $o->add_other2_objs2({ name => 'xa' }, { name => 'xb' });
  $o->add_other2_objs2({ name => 'xc' });
  $o->save;

  is(join(',', sort map { $_->name } $o->other2_objs2), 'xa,xb,xc', "Multiple add_on_save one-to-many 1 - $db_type");

  $o = MySQLiteObject->new(id => 10)->load;

  $o->add_colors({ name => 'za' }, { name => 'zb' });
  $o->add_colors({ name => 'zc' });
  $o->save;

  is(join(',', sort map { $_->name } $o->colors), 'za,zb,zc', "Multiple add_on_save many-to-many 1 - $db_type");

  $o = MySQLiteObject->new(name => 'John', id => 11);

  $o->other2_objs2;
  $o->add_other2_objs2({ name => 'xa2' }, { name => 'xb2' });
  $o->add_other2_objs2({ name => 'xc2' });

  is(join(',', sort map { $_->name } $o->other2_objs2), 'xa2,xb2,xc2', "Multiple add_on_save one-to-many 2 - $db_type");

  $o->save;

  is(join(',', sort map { $_->name } $o->other2_objs2), 'xa2,xb2,xc2', "Multiple add_on_save one-to-many 3 - $db_type");

  $o = MySQLiteObject->new(id => 11)->load;

  $o->colors;
  $o->add_colors({ name => 'za2' }, { name => 'zb2' });
  $o->add_colors({ name => 'zc2' });

  is(join(',', sort map { $_->name } $o->colors), 'za2,zb2,zc2', "Multiple add_on_save many-to-many 2 - $db_type");

  $o->save;

  is(join(',', sort map { $_->name } $o->colors), 'za2,zb2,zc2', "Multiple add_on_save many-to-many 3 - $db_type");

  # End multiple add_on_save tests

  # Start fk hook-up tests

  $o2 = MySQLiteOtherObject2->new(name => 'B', pid => 11);
  $o2->save;

  $o = MySQLiteObject->new(name => 'John', id => 12);

  $o->add_other2_objs2($o2);
  $o2->name('John2');
  $o->save;

  $o2 = MySQLiteOtherObject2->new(id => $o2->id)->load;

  is($o2->pid, $o->id, "fk hook-up 1 - $db_type");
  is($o2->name, 'John2', "fk hook-up 2 - $db_type");

  # End fk hook-up tests

  test_meta(MySQLiteOtherObject2->meta, 'MySQLite', $db_type);
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
      $dbh->do('DROP TABLE rose_db_object_colors_map CASCADE');
      $dbh->do('DROP TABLE rose_db_object_colors');
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
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other2
(
  id    SERIAL PRIMARY KEY,
  name  VARCHAR(255),
  pid   INT NOT NULL REFERENCES rose_db_object_test (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors
(
  id    SERIAL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors_map
(
  id        SERIAL PRIMARY KEY,
  obj_id    INT NOT NULL REFERENCES rose_db_object_test (id),
  color_id  INT NOT NULL REFERENCES rose_db_object_colors (id),

  arb_attr  VARCHAR(64),

  UNIQUE(obj_id, color_id)
)
EOF

    $dbh->disconnect;

    # Create test subclasses

    package MyPgOtherObject;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('pg') }

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

    package MyPgObject;

    use Rose::DB::Object::Helpers qw(has_loaded_related forget_related);
    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('pg') }

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
      fk1      => { type => 'int' },
      fk2      => { type => 'int' },
      fk3      => { type => 'int' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    MyPgObject->meta->foreign_keys
    (
      other_obj =>
      {
        class => 'MyPgOtherObject',
        rel_type => 'one to one',
        key_columns =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        methods => 
        {
          get_set_now     => undef,
          get_set_on_save => 'other_obj_on_save',
          delete_now      => undef,
          delete_on_save  => 'del_other_obj_on_save',
        },
      },
    );

    MyPgObject->meta->relationships
    (
      other_objx =>
      {
        type  => 'one to one',
        class => 'MyPgOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        required => 1,
      },

      other2_objs =>
      {
        type  => 'one to many',
        class => 'MyPgOtherObject2',
        column_map => { id => 'pid' },
        manager_args => { sort_by => 'name DESC' },
        methods =>
        {
          get_set         => undef,
          get_set_now     => 'other2_objs_now',
          get_set_on_save => 'other2_objs_on_save',
          add_now         => 'add_other2_objs_now',
          add_on_save     => undef,
        },
      },

      other2_a_objs =>
      {
        type  => 'one to many',
        class => 'MyPgOtherObject2',
        column_map => { id => 'pid' },
        query_args => [ name => { like => 'a%' } ],
        manager_args => { sort_by => 'name' },
      },

      other_obj_osoft =>
      {
        type => 'one to one',
        class => 'MyPgOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        referential_integrity => 0,
      },

      other_obj_msoft =>
      {
        type => 'many to one',
        class => 'MyPgOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        soft => 1,
      },
    );

    MyPgObject->meta->alias_column(fk1 => 'fkone');

    MyPgObject->meta->add_relationship
    (
      colors =>
      {
        type      => 'many to many',
        map_class => 'MyPgColorMap',
        #map_from  => 'object',
        #map_to    => 'color',
        manager_args => { sort_by => 'rose_db_object_colors.name' },
        methods =>
        {
          get_set         => undef,
          get_set_now     => 'colors_now',
          get_set_on_save => 'colors_on_save',
          add_now         => undef,
          add_on_save     => 'add_colors_on_save',
          find            => undef,
          count           => undef,
        },
      },
    );

    eval { MyPgObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method - pg');

    MyPgObject->meta->alias_column(save => 'save_col');
    MyPgObject->meta->initialize(preserve_existing => 1);

    my $meta = MyPgObject->meta;

    Test::More::is($meta->relationship('other_obj')->foreign_key,
                   $meta->foreign_key('other_obj'),
                   'foreign key sync 1 - pg');

    package MyPgOtherObject2;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('pg') }

    MyPgOtherObject2->meta->table('rose_db_object_other2');

    MyPgOtherObject2->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar'},
      pid  => { type => 'int' },
    );

    MyPgOtherObject2->meta->relationships
    (
      other_obj =>
      {
        type  => 'one to one',
        class => 'MyPgObject',
        column_map => { pid => 'id' },
        required => 1,
      },
    );

    MyPgOtherObject2->meta->foreign_keys
    (
      other_obj =>
      {
        class => 'MyPgObject',
        relationship_type => 'one to one',
        key_columns => { pid => 'id' },
      },
    );

    MyPgOtherObject2->meta->initialize;

    package MyPgColor;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('pg') }

    MyPgColor->meta->table('rose_db_object_colors');

    MyPgColor->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', not_null => 1 },
    );

    MyPgColor->meta->unique_key('name');

    MyPgColor->meta->initialize;

    package MyPgColorMap;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('pg') }

    MyPgColorMap->meta->table('rose_db_object_colors_map');

    MyPgColorMap->meta->columns
    (
      id       => { type => 'serial', primary_key => 1 },
      obj_id   => { type => 'int', not_null => 1 },
      color_id => { type => 'int', not_null => 1 },
    );

    MyPgColorMap->meta->unique_keys([ 'obj_id', 'color_id' ]);

    MyPgColorMap->meta->foreign_keys
    (
      object =>
      {
        class => 'MyPgObject',
        key_columns => { obj_id => 'id' },
      },

      color =>
      {
        class => 'MyPgColor',
        key_columns => { color_id => 'id' },
      },
    );

    MyPgColorMap->meta->initialize;
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
      $dbh->do('DROP TABLE rose_db_object_colors_map CASCADE');
      $dbh->do('DROP TABLE rose_db_object_colors');
      $dbh->do('DROP TABLE rose_db_object_other');
      $dbh->do('DROP TABLE rose_db_object_other2');
      $dbh->do('DROP TABLE rose_db_object_chkpass_test');
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
  last_modified  TIMESTAMP,
  date_created   DATETIME
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other2
(
  id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(255),
  pid   INT UNSIGNED NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors
(
  id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(255) NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors_map
(
  id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  obj_id    INT NOT NULL REFERENCES rose_db_object_test (id),
  color_id  INT NOT NULL REFERENCES rose_db_object_colors (id),

  arb_attr  VARCHAR(64),

  UNIQUE(obj_id, color_id)
)
EOF

    $dbh->disconnect;

    # Create test subclasses

    package MyMySQLOtherObject;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('mysql') }

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

    package MyMySQLObject;

    use Rose::DB::Object::Helpers qw(has_loaded_related);
    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('mysql') }

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
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'datetime' },
    );

    MyMySQLObject->meta->relationships
    (
      other_obj =>
      {
        type  => 'many to one',
        class => 'MyMySQLOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        required => 1,
      }
    );

    MyMySQLObject->meta->add_relationships
    (
      other_obj_otoo =>
      {
        type => 'one to one',
        class => 'MyMySQLOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
      },

      other_obj_osoft =>
      {
        type => 'one to one',
        class => 'MyMySQLOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        referential_integrity => 0,
      },

      other_obj_msoft =>
      {
        type => 'many to one',
        class => 'MyMySQLOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        soft => 1,
        with_column_triggers => 1,
      },

      other2_objs =>
      {
        type  => 'one to many',
        class => 'MyMySQLOtherObject2',
        column_map => { id => 'pid' },
        manager_args => { sort_by => 'rose_db_object_other2.name DESC' },
        methods =>
        {
          get_set         => undef,
          get_set_now     => 'other2_objs_now',
          get_set_on_save => 'other2_objs_on_save',
          add_now         => 'add_other2_objs_now',
          add_on_save     => undef,
        },
      },

      other2_a_objs =>
      {
        type  => 'one to many',
        class => 'MyMySQLOtherObject2',
        column_map => { id => 'pid' },
        query_args => [ name => { like => 'a%' } ],
        manager_args => { sort_by => 'name' },
      },

      other2_objs2 =>
      {
        type  => 'one to many',
        class => 'MyMySQLOtherObject2',
        column_map => { id => 'pid' },
      },
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
        },
        methods => 
        {
          get_set_now     => undef,
          get_set_on_save => 'other_obj_on_save',
          delete_now      => undef,
          delete_on_save  => 'del_other_obj_on_save',
        },
      },
    );

    MyMySQLObject->meta->add_relationship
    (
      colors =>
      {
        type      => 'many to many',
        map_class => 'MyMySQLColorMap',
        map_from  => 'object',
        map_to    => 'color',
        manager_args => { sort_by => 'rose_db_object_colors.name' },
        methods =>
        {
          get_set         => undef,
          get_set_now     => 'colors_now',
          get_set_on_save => 'colors_on_save',
          add_now         => undef,
          add_on_save     => 'add_colors_on_save',
          find            => undef,
          count           => undef,
        },
      },
    );

    eval { MyMySQLObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method - mysql');

    MyMySQLObject->meta->alias_column(save => 'save_col');
    MyMySQLObject->meta->initialize(preserve_existing => 1);

    my $meta = MyMySQLObject->meta;

    Test::More::is($meta->relationship('other_obj')->foreign_key,
                   $meta->foreign_key('other_obj'),
                   'foreign key sync 1 - mysql');

    package MyMySQLOtherObject2;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('mysql') }

    MyMySQLOtherObject2->meta->table('rose_db_object_other2');

    MyMySQLOtherObject2->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar'},
      pid  => { type => 'int' },
    );

    MyMySQLOtherObject2->meta->relationships
    (
      other_obj =>
      {
        type  => 'many to one',
        class => 'MyMySQLObject',
        column_map => { pid => 'id' },
        required => 1,
        with_column_triggers => 1,
      },
    );

    MyMySQLOtherObject2->meta->foreign_keys
    (
      other_obj =>
      {
        class => 'MyMySQLObject',
        key_columns => { pid => 'id' },
      },
    );

    MyMySQLOtherObject2->meta->initialize;

    package MyMySQLColor;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('mysql') }

    MyMySQLColor->meta->table('rose_db_object_colors');

    MyMySQLColor->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', not_null => 1 },
    );

    MyMySQLColor->meta->initialize;

    package MyMySQLColorMap;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('mysql') }

    MyMySQLColorMap->meta->table('rose_db_object_colors_map');

    MyMySQLColorMap->meta->columns
    (
      id       => { type => 'serial', primary_key => 1 },
      obj_id   => { type => 'int', not_null => 1 },
      color_id => { type => 'int', not_null => 1 },
    );

    MyMySQLColorMap->meta->unique_keys([ 'obj_id', 'color_id' ]);

    MyMySQLColorMap->meta->foreign_keys
    (
      object =>
      {
        class => 'MyMySQLObject',
        key_columns => { obj_id => 'id' },
      },

      color =>
      {
        class => 'MyMySQLColor',
        key_columns => { color_id => 'id' },
      },
    );

    MyMySQLColorMap->meta->initialize;
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
      $dbh->do('DROP TABLE rose_db_object_colors_map CASCADE');
      $dbh->do('DROP TABLE rose_db_object_colors');
      $dbh->do('DROP TABLE rose_db_object_other');
      $dbh->do('DROP TABLE rose_db_object_other2');
      $dbh->do('DROP TABLE rose_db_object_chkpass_test');
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
  last_modified  DATETIME YEAR TO FRACTION(5),
  date_created   DATETIME YEAR TO FRACTION(5),

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other2
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(255),
  pid   INT NOT NULL REFERENCES rose_db_object_test (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors
(
  id    SERIAL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors_map
(
  id        SERIAL PRIMARY KEY,
  obj_id    INT NOT NULL REFERENCES rose_db_object_test (id),
  color_id  INT NOT NULL REFERENCES rose_db_object_colors (id),

  arb_attr  VARCHAR(64),

  UNIQUE(obj_id, color_id)
)
EOF

    $dbh->disconnect;

    # Create test subclasses

    package MyInformixOtherObject;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('informix') }

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

    package MyInformixObject;

    use Rose::DB::Object::Helpers qw(has_loaded_related);
    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('informix') }

    MyInformixObject->meta->table('rose_db_object_test');

    MyInformixObject->meta->dbi_prepare_cached(0);

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
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    MyInformixObject->meta->add_foreign_keys
    (
      other_obj =>
      {
        class => 'MyInformixOtherObject',
        rel_type => 'one to one',
        key_columns =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        methods => 
        {
          get_set_now     => undef,
          get_set_on_save => 'other_obj_on_save',
          delete_now      => undef,
          delete_on_save  => 'del_other_obj_on_save',
        },
      },
    );

    MyInformixObject->meta->add_relationships
    (
      other_obj_osoft =>
      {
        type => 'one to one',
        class => 'MyInformixOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        referential_integrity => 0,
      },

      other_obj_msoft =>
      {
        type => 'many to one',
        class => 'MyInformixOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        soft => 1,
        with_column_triggers => 1,
      },

      other2_objs =>
      {
        type  => 'one to many',
        class => 'MyInformixOtherObject2',
        column_map => { id => 'pid' },
        manager_args => { sort_by => 'rose_db_object_other2.name DESC' },
        methods =>
        {
          get_set         => undef,
          get_set_now     => 'other2_objs_now',
          get_set_on_save => 'other2_objs_on_save',
          add_now         => 'add_other2_objs_now',
          add_on_save     => undef,
        },
      },

      other2_a_objs =>
      {
        type  => 'one to many',
        class => 'MyInformixOtherObject2',
        column_map => { id => 'pid' },
        query_args => [ name => { like => 'a%' } ],
        manager_args => { sort_by => 'name' },
      },
    );

    MyInformixObject->meta->alias_column(fk1 => 'fkone');

    MyInformixObject->meta->add_relationship
    (
      colors =>
      {
        type      => 'many to many',
        map_class => 'MyInformixColorMap',
        #map_from  => 'object',
        #map_to    => 'color',
        manager_args => { sort_by => 'rose_db_object_colors.name' },
        methods =>
        {
          get_set         => undef,
          get_set_now     => 'colors_now',
          get_set_on_save => 'colors_on_save',
          add_now         => undef,
          add_on_save     => 'add_colors_on_save',
          find            => undef,
          count           => undef,
        },
      },
    );

    eval { MyInformixObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method - informix');

    MyInformixObject->meta->alias_column(save => 'save_col');
    MyInformixObject->meta->initialize(preserve_existing => 1);

    my $meta = MyInformixObject->meta;

    Test::More::is($meta->relationship('other_obj')->foreign_key,
                   $meta->foreign_key('other_obj'),
                   'foreign key sync 1 - Informix');

    package MyInformixOtherObject2;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('informix') }

    MyInformixOtherObject2->meta->table('rose_db_object_other2');

    MyInformixOtherObject2->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar'},
      pid  => { type => 'int' },
    );

    MyInformixOtherObject2->meta->relationships
    (
      other_obj =>
      {
        type  => 'many to one',
        class => 'MyInformixObject',
        column_map => { pid => 'id' },
        required => 1,
        with_column_triggers => 1,
      },
    );

    MyInformixOtherObject2->meta->foreign_keys
    (
      other_obj =>
      {
        class => 'MyInformixObject',
        key_columns => { pid => 'id' },
      },
    );

    MyInformixOtherObject2->meta->initialize;

    package MyInformixColor;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('informix') }

    MyInformixColor->meta->table('rose_db_object_colors');

    MyInformixColor->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', not_null => 1 },
    );

    MyInformixColor->meta->initialize;

    package MyInformixColorMap;

    our @ISA = qw(Rose::DB::Object);

    our $DB;

    sub init_db { $DB ||= Rose::DB->new('informix') }

    MyInformixColorMap->meta->table('rose_db_object_colors_map');

    MyInformixColorMap->meta->columns
    (
      id       => { type => 'serial', primary_key => 1 },
      obj_id   => { type => 'int', not_null => 1 },
      color_id => { type => 'int', not_null => 1 },
    );

    MyInformixColorMap->meta->unique_keys([ 'obj_id', 'color_id' ]);

    MyInformixColorMap->meta->foreign_keys
    (
      object =>
      {
        class => 'MyInformixObject',
        key_columns => { obj_id => 'id' },
      },

      color =>
      {
        class => 'MyInformixColor',
        key_columns => { color_id => 'id' },
      },
    );

    MyInformixColorMap->meta->initialize;
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
      $dbh->do('DROP TABLE rose_db_object_colors_map');
      $dbh->do('DROP TABLE rose_db_object_colors');
      $dbh->do('DROP TABLE rose_db_object_other');
      $dbh->do('DROP TABLE rose_db_object_other2');
      $dbh->do('DROP TABLE rose_db_object_chkpass_test');
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
  last_modified  DATETIME,
  date_created   DATETIME,

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other2
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(255),
  pid   INT NOT NULL REFERENCES rose_db_object_test (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(255) NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors_map
(
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  obj_id    INT NOT NULL REFERENCES rose_db_object_test (id),
  color_id  INT NOT NULL REFERENCES rose_db_object_colors (id),

  arb_attr  VARCHAR(64),

  UNIQUE(obj_id, color_id)
)
EOF

    $dbh->disconnect;

    # Create test subclasses

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

    package MySQLiteObject;

    use Rose::DB::Object::Helpers qw(has_loaded_related);
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
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    MySQLiteObject->meta->add_foreign_keys
    (
      other_obj =>
      {
        class => 'MySQLiteOtherObject',
        rel_type => 'one to one',
        key_columns =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        methods => 
        {
          get_set_now     => undef,
          get_set_on_save => 'other_obj_on_save',
          delete_now      => undef,
          delete_on_save  => 'del_other_obj_on_save',
        },
      },
    );

    MySQLiteObject->meta->add_relationships
    (
      other_obj_osoft =>
      {
        type => 'one to one',
        class => 'MySQLiteOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        soft => 1,
      },

      other_obj_msoft =>
      {
        type => 'many to one',
        class => 'MySQLiteOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        referential_integrity => 0,
        with_column_triggers => 1,
      },

      other2_objs =>
      {
        type  => 'one to many',
        class => 'MySQLiteOtherObject2',
        column_map => { id => 'pid' },
        manager_args => { sort_by => 'rose_db_object_other2.name DESC' },
        methods =>
        {
          find            => undef,
          iterator        => undef,
          get_set         => undef,
          get_set_now     => 'other2_objs_now',
          get_set_on_save => 'other2_objs_on_save',
          add_now         => 'add_other2_objs_now',
          add_on_save     => undef,
        },
      },

      other2_a_objs =>
      {
        type  => 'one to many',
        class => 'MySQLiteOtherObject2',
        column_map => { id => 'pid' },
        query_args => [ name => { like => 'a%' } ],
        manager_args => { sort_by => 'name' },
      },

      other2_one_obj =>
      {
        type  => 'one to one',
        class => 'MySQLiteOtherObject2',
        column_map => { id => 'pid' },
        query_args => [ name => 'one' ],
        with_column_triggers => 1,
      },

      other2_objs2 =>
      {
        type  => 'one to many',
        class => 'MySQLiteOtherObject2',
        column_map => { id => 'pid' },
      },

      # Hrm.  Experimental...
      not_other2_objs =>
      {
        type  => 'one to many',
        class => 'MySQLiteOtherObject2',
        #column_map => { id => 'pid' },
        query_args => [ id => { ne_sql => 'pid' } ],
      },
    );    

    MySQLiteObject->meta->alias_column(fk1 => 'fkone');

    MySQLiteObject->meta->add_relationship
    (
      colors =>
      {
        type      => 'many to many',
        map_class => 'MySQLiteColorMap',
        #map_from  => 'object',
        #map_to    => 'color',
        manager_args => { sort_by => 'name' },
        methods =>
        {
          get_set         => undef,
          get_set_now     => 'colors_now',
          get_set_on_save => 'colors_on_save',
          add_now         => undef,
          add_on_save     => 'add_colors_on_save',
          find            => undef,
          count           => undef,
          iterator        => undef,
        },
      },

      colors2 =>
      {
        type      => 'many to many',
        map_class => 'MySQLiteColorMap',
        manager_args => { sort_by => 'name', with_map_records => 1 },
      },

      colors3 =>
      {
        type      => 'many to many',
        map_class => 'MySQLiteColorMap',
        manager_args => { sort_by => 'rose_db_object_colors_map.color_id DESC', with_map_records => 'map_rec' },
      },
    );

    # Test to confirm a 0.780 fix for a bug in delete_relationships()
    MySQLiteObject->meta->delete_relationships;

    MySQLiteObject->meta->add_relationships
    (
      other_obj_osoft =>
      {
        type => 'one to one',
        class => 'MySQLiteOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        soft => 1,
      },

      other_obj_msoft =>
      {
        type => 'many to one',
        class => 'MySQLiteOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        referential_integrity => 0,
        with_column_triggers => 1,
      },

      other2_objs =>
      {
        type  => 'one to many',
        class => 'MySQLiteOtherObject2',
        column_map => { id => 'pid' },
        manager_args => { sort_by => 'rose_db_object_other2.name DESC' },
        methods =>
        {
          find            => undef,
          iterator        => undef,
          get_set         => undef,
          get_set_now     => 'other2_objs_now',
          get_set_on_save => 'other2_objs_on_save',
          add_now         => 'add_other2_objs_now',
          add_on_save     => undef,
        },
      },

      other2_a_objs =>
      {
        type  => 'one to many',
        class => 'MySQLiteOtherObject2',
        column_map => { id => 'pid' },
        query_args => [ name => { like => 'a%' } ],
        manager_args => { sort_by => 'name' },
      },

      other2_one_obj =>
      {
        type  => 'one to one',
        class => 'MySQLiteOtherObject2',
        column_map => { id => 'pid' },
        query_args => [ name => 'one' ],
        with_column_triggers => 1,
      },

      other2_objs2 =>
      {
        type  => 'one to many',
        class => 'MySQLiteOtherObject2',
        column_map => { id => 'pid' },
      },

      # Hrm.  Experimental...
      not_other2_objs =>
      {
        type  => 'one to many',
        class => 'MySQLiteOtherObject2',
        #column_map => { id => 'pid' },
        query_args => [ id => { ne_sql => 'pid' } ],
      },

      # manager_*_methods
      custom_manager_method_other2_objs =>
      {
        type  => 'one to many',
        class => 'MySQLiteOtherObject2',
        manager_class => 'MySQLiteOtherObject2::Manager',
        manager_method => 'other2_objs',
        manager_count_method => 'other2_objs_count',
        manager_iterator_method => 'other2_objs_iterator',
        manager_find_method => 'other2_objs_find',
        column_map => { id => 'pid' },
        methods =>
        {
          count           => undef,
          find            => undef,
          iterator        => undef,
          get_set         => undef,
          get_set_now     => undef,
          get_set_on_save => undef,
        },
      },

      custom_manager_method_other_obj_msoft =>
      {
        type => 'many to one',
        class => 'MySQLiteOtherObject',
        column_map =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        },
        referential_integrity => 0,
        with_column_triggers => 1,
        manager_class => 'MySQLiteOtherObject::Manager',
        manager_delete_method => 'other_obj_delete',    # TODO this not yet exercised
      },

    );    

    MySQLiteObject->meta->alias_column(fk1 => 'fkone');

    MySQLiteObject->meta->add_relationship
    (
      colors =>
      {
        type      => 'many to many',
        map_class => 'MySQLiteColorMap',
        #map_from  => 'object',
        #map_to    => 'color',
        manager_args => { sort_by => 'name' },
        methods =>
        {
          get_set         => undef,
          get_set_now     => 'colors_now',
          get_set_on_save => 'colors_on_save',
          add_now         => undef,
          add_on_save     => 'add_colors_on_save',
          find            => undef,
          count           => undef,
          iterator        => undef,
        },
      },

      colors2 =>
      {
        type      => 'many to many',
        map_class => 'MySQLiteColorMap',
        manager_args => { sort_by => 'name', with_map_records => 1 },
      },

      colors3 =>
      {
        type      => 'many to many',
        map_class => 'MySQLiteColorMap',
        manager_args => { sort_by => 'rose_db_object_colors_map.color_id DESC', with_map_records => 'map_rec' },
      },
    );

    eval { MySQLiteObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method - sqlite');

    MySQLiteObject->meta->alias_column(save => 'save_col');
    MySQLiteObject->meta->initialize(preserve_existing => 1);

    my $meta = MySQLiteObject->meta;

    Test::More::is($meta->relationship('other_obj')->foreign_key,
                   $meta->foreign_key('other_obj'),
                   'foreign key sync 1 - SQLite');

    package MySQLiteOtherObject2;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteOtherObject2->meta->table('rose_db_object_other2');

    MySQLiteOtherObject2->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar'},
      pid  => { type => 'int' },
    );

    MySQLiteOtherObject2->meta->relationships
    (
      other_obj =>
      {
        type  => 'many to one',
        class => 'MySQLiteObject',
        column_map => { pid => 'id' },
        required => 1,
        with_column_triggers => 1,
      },
    );

    MySQLiteOtherObject2->meta->foreign_keys
    (
      other_obj =>
      {
        class => 'MySQLiteObject',
        key_columns => { pid => 'id' },
      },
    );

    MySQLiteOtherObject2->meta->initialize;

    # Manager used only for custom manager_*_methods
    package MySQLiteOtherObject2::Manager;

    sub other2_objs          { 'ima-get-objects' }
    sub other2_objs_count    { 'ima-count' }
    sub other2_objs_iterator { 'ima-iterator' }
    sub other2_objs_find     { 'ima-find' }

    package MySQLiteOtherObject::Manager;

    sub other_obj_delete { 'ima-delete' } # TODO this not yet exercised

    package MySQLiteColor;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteColor->meta->table('rose_db_object_colors');

    MySQLiteColor->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', not_null => 1 },
    );

    MySQLiteColor->meta->initialize;

    package MySQLiteColorMap;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteColorMap->meta->table('rose_db_object_colors_map');

    MySQLiteColorMap->meta->columns
    (
      id       => { type => 'serial', primary_key => 1 },
      obj_id   => { type => 'int', not_null => 1 },
      color_id => { type => 'int', not_null => 1 },
      arb_attr => { type => 'varchar', length => 64 },
    );

    MySQLiteColorMap->meta->unique_keys([ 'obj_id', 'color_id' ]);

    MySQLiteColorMap->meta->foreign_keys
    (
      object =>
      {
        class => 'MySQLiteObject',
        key_columns => { obj_id => 'id' },
      },

      color =>
      {
        class => 'MySQLiteColor',
        key_columns => { color_id => 'id' },
      },
    );

    MySQLiteColorMap->meta->initialize;
  }
}

sub test_meta
{
  my($meta, $prefix, $db_type) = @_;

  $meta->delete_relationships;  

  $meta->delete_foreign_keys;

  $meta->foreign_keys
  (
    other_obj =>
    {
      class => "${prefix}Object",
      key_columns => { pid => 'id' },
    },
  );

  $meta->relationships
  (
    other_objx =>
    {
      type  => 'many to one',
      class => "${prefix}Object",
      column_map => { pid => 'id' },
      required => 1,
      with_column_triggers => 1,
    },
  );

  is(scalar @{$meta->foreign_keys}, 1, "proxy relationships 1 - $db_type");
  is(scalar @{$meta->relationships}, 2, "proxy relationships 2 - $db_type");

  $meta->delete_foreign_keys;

  is(scalar @{$meta->foreign_keys}, 0, "proxy relationships 3 - $db_type");
  is(scalar @{$meta->relationships}, 1, "proxy relationships 4 - $db_type");

  $meta->relationships
  (
    other_objx =>
    {
      type  => 'many to one',
      class => "${prefix}Object",
      column_map => { pid => 'id' },
      required => 1,
      with_column_triggers => 1,
    },
  );

  $meta->foreign_keys
  (
    other_obj =>
    {
      class => "${prefix}Object",
      key_columns => { pid => 'id' },
    },
  );

  is(scalar @{$meta->foreign_keys}, 1, "proxy relationships 5 - $db_type");
  is(scalar @{$meta->relationships}, 2, "proxy relationships 6 - $db_type");
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
    $dbh->do('DROP TABLE rose_db_object_colors_map CASCADE');
    $dbh->do('DROP TABLE rose_db_object_colors');
    $dbh->do('DROP TABLE rose_db_object_other');
    $dbh->do('DROP TABLE rose_db_object_other2');

    $dbh->disconnect;
  }

  if($HAVE_MYSQL)
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_colors_map CASCADE');
    $dbh->do('DROP TABLE rose_db_object_colors');
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

    $dbh->do('DROP TABLE rose_db_object_colors_map CASCADE');
    $dbh->do('DROP TABLE rose_db_object_colors');
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

    $dbh->do('DROP TABLE rose_db_object_colors_map');
    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->do('DROP TABLE rose_db_object_colors');
    $dbh->do('DROP TABLE rose_db_object_other');
    $dbh->do('DROP TABLE rose_db_object_other2');

    $dbh->disconnect;
  }
}
