#!/usr/bin/perl -w

use strict;

use Test::More tests => 262;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
}

our($PG_HAS_CHKPASS, $HAVE_PG, $HAVE_MYSQL_WITH_INNODB, $HAVE_INFORMIX, 
    $HAVE_SQLITE);

#
# PostgreSQL
#

SKIP: foreach my $db_type ('pg')
{
  skip("PostgreSQL tests", 74)  unless($HAVE_PG);

  Rose::DB->default_type($db_type);

  my $o = MyPgObject->new(name => 'John');

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
  ok($oo1->save, 'other object save() 1');

  my $oo2 = MyPgOtherObject->new(k1 => 11, k2 => 12, k3 => 13, name => 'two');
  ok($oo2->save, 'other object save() 2');

  my $other2 = MyPgOtherObject2->new(id2 => 12, name => 'twelve');
  ok($other2->save, 'other 2 object save() 1');

  my $other3 = MyPgOtherObject3->new(id3 => 13, name => 'thirteen');
  ok($other3->save, 'other 3 object save() 1');

  my $other4 = MyPgOtherObject4->new(id4 => 14, name => 'fourteen');
  ok($other4->save, 'other 4 object save() 1');

  is($o->fother, undef, 'fother() 1');
  is($o->fother2, undef, 'fother2() 1');
  is($o->fother3, undef, 'fother3() 1');
  is($o->my_pg_other_object, undef, 'my_pg_other_object() 1');

  $o->fother_id2(12);
  $o->fother_id3(13);
  $o->fother_id4(14);
  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);

  my $obj = $o->my_pg_other_object or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyPgOtherObject', 'my_pg_other_object() 2');
  is($obj->name, 'one', 'my_pg_other_object() 3');

  $obj = $o->fother or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyPgOtherObject2', 'fother() 2');
  is($obj->name, 'twelve', 'fother() 3');

  $obj = $o->fother2 or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyPgOtherObject3', 'fother2() 2');
  is($obj->name, 'thirteen', 'fother2() 3');

  $obj = $o->fother3 or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyPgOtherObject4', 'fother3() 2');
  is($obj->name, 'fourteen', 'fother3() 3');

  $o->my_pg_other_object(undef);
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);

  $obj = $o->my_pg_other_object or warn "# ", $o->error, "\n";

  is(ref $obj, 'MyPgOtherObject', 'my_pg_other_object() 4');
  is($obj->name, 'two', 'my_pg_other_object() 5');

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');

  #
  # Test code generation
  #

  is(MyPgObject->meta->perl_foreign_keys_definition,
     <<'EOF', "perl_foreign_keys_definition 1 - $db_type");
__PACKAGE__->meta->foreign_keys(
    fother => {
        class       => 'MyPgOtherObject2',
        key_columns => { fother_id2 => 'id2' },
    },

    fother2 => {
        class       => 'MyPgOtherObject3',
        key_columns => { fother_id3 => 'id3' },
    },

    fother3 => {
        class       => 'MyPgOtherObject4',
        key_columns => { fother_id4 => 'id4' },
    },

    my_pg_other_object => {
        class       => 'MyPgOtherObject',
        key_columns => {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
        },
    },
);
EOF

  is(MyPgObject->meta->perl_foreign_keys_definition(braces => 'bsd', indent => 2),
     <<'EOF', "perl_foreign_keys_definition 2 - $db_type");
__PACKAGE__->meta->foreign_keys
(
  fother => 
  {
    class       => 'MyPgOtherObject2',
    key_columns => { fother_id2 => 'id2' },
  },

  fother2 => 
  {
    class       => 'MyPgOtherObject3',
    key_columns => { fother_id3 => 'id3' },
  },

  fother3 => 
  {
    class       => 'MyPgOtherObject4',
    key_columns => { fother_id4 => 'id4' },
  },

  my_pg_other_object => 
  {
    class       => 'MyPgOtherObject',
    key_columns => 
    {
      fk1 => 'k1',
      fk2 => 'k2',
      fk3 => 'k3',
    },
  },
);
EOF

  my $chkpass = $PG_HAS_CHKPASS ? "    password      => { type => 'chkpass' },\n" : '';

  is(MyPgObject->meta->perl_class_definition(use_setup => 0),
     <<"EOF", "perl_class_definition (trad) 1 - $db_type");
package MyPgObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->table('Rose_db_object_test');

__PACKAGE__->meta->columns(
    id            => { type => 'serial', not_null => 1 },
$chkpass    name          => { type => 'varchar', length => 32, not_null => 1 },
    flag          => { type => 'boolean', default => 'true', not_null => 1 },
    flag2         => { type => 'boolean' },
    status        => { type => 'varchar', default => 'active', length => 32 },
    bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
    start         => { type => 'date', default => '1980-12-24' },
    save          => { type => 'integer', alias => 'save_col' },
    nums          => { type => 'array' },
    fk1           => { type => 'integer', alias => 'fkone' },
    fk2           => { type => 'integer' },
    fk3           => { type => 'integer' },
    fother_id2    => { type => 'integer' },
    fother_id3    => { type => 'integer' },
    fother_id4    => { type => 'integer' },
    last_modified => { type => 'timestamp' },
    date_created  => { type => 'timestamp' },
);

__PACKAGE__->meta->primary_key_columns([ 'id' ]);

__PACKAGE__->meta->foreign_keys(
    fother => {
        class       => 'MyPgOtherObject2',
        key_columns => { fother_id2 => 'id2' },
    },

    fother2 => {
        class       => 'MyPgOtherObject3',
        key_columns => { fother_id3 => 'id3' },
    },

    fother3 => {
        class       => 'MyPgOtherObject4',
        key_columns => { fother_id4 => 'id4' },
    },

    my_pg_other_object => {
        class       => 'MyPgOtherObject',
        key_columns => {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
        },
    },
);

__PACKAGE__->meta->initialize;

1;
EOF

  $chkpass = $PG_HAS_CHKPASS ? "        password      => { type => 'chkpass' },\n" : '';

  is(MyPgObject->meta->perl_class_definition,
     <<"EOF", "perl_class_definition 1 - $db_type");
package MyPgObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->setup(
    table   => 'Rose_db_object_test',

    columns => [
        id            => { type => 'serial', not_null => 1 },
$chkpass        name          => { type => 'varchar', length => 32, not_null => 1 },
        flag          => { type => 'boolean', default => 'true', not_null => 1 },
        flag2         => { type => 'boolean' },
        status        => { type => 'varchar', default => 'active', length => 32 },
        bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
        start         => { type => 'date', default => '1980-12-24' },
        save          => { type => 'integer', alias => 'save_col' },
        nums          => { type => 'array' },
        fk1           => { type => 'integer', alias => 'fkone' },
        fk2           => { type => 'integer' },
        fk3           => { type => 'integer' },
        fother_id2    => { type => 'integer' },
        fother_id3    => { type => 'integer' },
        fother_id4    => { type => 'integer' },
        last_modified => { type => 'timestamp' },
        date_created  => { type => 'timestamp' },
    ],

    primary_key_columns => [ 'id' ],

    foreign_keys => [
        fother => {
            class       => 'MyPgOtherObject2',
            key_columns => { fother_id2 => 'id2' },
        },

        fother2 => {
            class       => 'MyPgOtherObject3',
            key_columns => { fother_id3 => 'id3' },
        },

        fother3 => {
            class       => 'MyPgOtherObject4',
            key_columns => { fother_id4 => 'id4' },
        },

        my_pg_other_object => {
            class       => 'MyPgOtherObject',
            key_columns => {
                fk1 => 'k1',
                fk2 => 'k2',
                fk3 => 'k3',
            },
        },
    ],
);

1;
EOF

  $chkpass = $PG_HAS_CHKPASS ? "  password      => { type => 'chkpass' },\n" : '';

  MyPgObject->meta->auto_load_related_classes(1);

  is(MyPgObject->meta->perl_class_definition(braces => 'bsd', indent => 2, use_setup => 0),
     <<"EOF", "perl_class_definition (trad) 2 - $db_type");
package MyPgObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->table('Rose_db_object_test');

__PACKAGE__->meta->columns
(
  id            => { type => 'serial', not_null => 1 },
$chkpass  name          => { type => 'varchar', length => 32, not_null => 1 },
  flag          => { type => 'boolean', default => 'true', not_null => 1 },
  flag2         => { type => 'boolean' },
  status        => { type => 'varchar', default => 'active', length => 32 },
  bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
  start         => { type => 'date', default => '1980-12-24' },
  save          => { type => 'integer', alias => 'save_col' },
  nums          => { type => 'array' },
  fk1           => { type => 'integer', alias => 'fkone' },
  fk2           => { type => 'integer' },
  fk3           => { type => 'integer' },
  fother_id2    => { type => 'integer' },
  fother_id3    => { type => 'integer' },
  fother_id4    => { type => 'integer' },
  last_modified => { type => 'timestamp' },
  date_created  => { type => 'timestamp' },
);

__PACKAGE__->meta->primary_key_columns([ 'id' ]);

__PACKAGE__->meta->foreign_keys
(
  fother => 
  {
    class       => 'MyPgOtherObject2',
    key_columns => { fother_id2 => 'id2' },
  },

  fother2 => 
  {
    class       => 'MyPgOtherObject3',
    key_columns => { fother_id3 => 'id3' },
  },

  fother3 => 
  {
    class       => 'MyPgOtherObject4',
    key_columns => { fother_id4 => 'id4' },
  },

  my_pg_other_object => 
  {
    class       => 'MyPgOtherObject',
    key_columns => 
    {
      fk1 => 'k1',
      fk2 => 'k2',
      fk3 => 'k3',
    },
  },
);

__PACKAGE__->meta->initialize;

1;
EOF

  $chkpass = $PG_HAS_CHKPASS ? "        password      => { type => 'chkpass' },\n" : '';

  MyPgObject->meta->auto_load_related_classes(0);

  is(MyPgObject->meta->perl_class_definition,
     <<"EOF", "perl_class_definition 2 - $db_type");
package MyPgObject;

use strict;

use base qw(Rose::DB::Object);

use MyPgOtherObject;
use MyPgOtherObject2;
use MyPgOtherObject3;
use MyPgOtherObject4;

__PACKAGE__->meta->setup(
    table   => 'Rose_db_object_test',

    columns => [
        id            => { type => 'serial', not_null => 1 },
$chkpass        name          => { type => 'varchar', length => 32, not_null => 1 },
        flag          => { type => 'boolean', default => 'true', not_null => 1 },
        flag2         => { type => 'boolean' },
        status        => { type => 'varchar', default => 'active', length => 32 },
        bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
        start         => { type => 'date', default => '1980-12-24' },
        save          => { type => 'integer', alias => 'save_col' },
        nums          => { type => 'array' },
        fk1           => { type => 'integer', alias => 'fkone' },
        fk2           => { type => 'integer' },
        fk3           => { type => 'integer' },
        fother_id2    => { type => 'integer' },
        fother_id3    => { type => 'integer' },
        fother_id4    => { type => 'integer' },
        last_modified => { type => 'timestamp' },
        date_created  => { type => 'timestamp' },
    ],

    primary_key_columns => [ 'id' ],

    foreign_keys => [
        fother => {
            class       => 'MyPgOtherObject2',
            key_columns => { fother_id2 => 'id2' },
        },

        fother2 => {
            class       => 'MyPgOtherObject3',
            key_columns => { fother_id3 => 'id3' },
        },

        fother3 => {
            class       => 'MyPgOtherObject4',
            key_columns => { fother_id4 => 'id4' },
        },

        my_pg_other_object => {
            class       => 'MyPgOtherObject',
            key_columns => {
                fk1 => 'k1',
                fk2 => 'k2',
                fk3 => 'k3',
            },
        },
    ],
);

1;
EOF
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 55)  unless($HAVE_MYSQL_WITH_INNODB);

  Rose::DB->default_type($db_type);

  my $o = MyMySQLObject->new(name => 'John');

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
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyMySQLObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyMySQLObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  my $oo1 = MyMySQLOtherObject->new(k1 => 1, k2 => 2, k3 => 3, name => 'one');
  ok($oo1->save, 'other object save() 1');

  my $oo2 = MyMySQLOtherObject->new(k1 => 11, k2 => 12, k3 => 13, name => 'two');
  ok($oo2->save, 'other object save() 2');

  my $other2 = MyMySQLOtherObject2->new(id2 => 12, name => 'twelve');
  ok($other2->save, 'other 2 object save() 1');

  my $other3 = MyMySQLOtherObject3->new(id3 => 13, name => 'thirteen');
  ok($other3->save, 'other 3 object save() 1');

  my $other4 = MyMySQLOtherObject4->new(id4 => 14, name => 'fourteen');
  ok($other4->save, 'other 4 object save() 1');

  is($o->fother, undef, 'fother() 1');
  is($o->fother2, undef, 'fother2() 1');
  is($o->fother3, undef, 'fother3() 1');
  is($o->my_my_sqlother_object, undef, 'my_my_sqlother_object() 1');

  $o->fother_id2(12);
  $o->fother_id3(13);
  $o->fother_id4(14);
  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);

  my $obj = $o->my_my_sqlother_object or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyMySQLOtherObject', 'my_my_sqlother_object() 2');
  is($obj->name, 'one', 'my_my_sqlother_object() 3');

  $obj = $o->fother or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyMySQLOtherObject2', 'fother() 2');
  is($obj->name, 'twelve', 'fother() 3');

  $obj = $o->fother2 or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyMySQLOtherObject3', 'fother2() 2');
  is($obj->name, 'thirteen', 'fother2() 3');

  $obj = $o->fother3 or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyMySQLOtherObject4', 'fother3() 2');
  is($obj->name, 'fourteen', 'fother3() 3');

  $o->my_my_sqlother_object(undef);
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);

  $obj = $o->my_my_sqlother_object or warn "# ", $o->error, "\n";

  is(ref $obj, 'MyMySQLOtherObject', 'my_my_sqlother_object() 4');
  is($obj->name, 'two', 'my_my_sqlother_object() 5');


  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');

  #
  # Test code generation
  #

  is(MyMySQLObject->meta->perl_foreign_keys_definition,
     <<'EOF', "perl_foreign_keys_definition 1 - $db_type");
__PACKAGE__->meta->foreign_keys(
    fother => {
        class       => 'MyMySQLOtherObject2',
        key_columns => { fother_id2 => 'id2' },
    },

    fother2 => {
        class       => 'MyMySQLOtherObject3',
        key_columns => { fother_id3 => 'id3' },
    },

    fother3 => {
        class       => 'MyMySQLOtherObject4',
        key_columns => { fother_id4 => 'id4' },
    },

    my_my_sqlother_object => {
        class       => 'MyMySQLOtherObject',
        key_columns => {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
        },
    },
);
EOF

  is(MyMySQLObject->meta->perl_foreign_keys_definition(braces => 'bsd', indent => 2),
     <<'EOF', "perl_foreign_keys_definition 2 - $db_type");
__PACKAGE__->meta->foreign_keys
(
  fother => 
  {
    class       => 'MyMySQLOtherObject2',
    key_columns => { fother_id2 => 'id2' },
  },

  fother2 => 
  {
    class       => 'MyMySQLOtherObject3',
    key_columns => { fother_id3 => 'id3' },
  },

  fother3 => 
  {
    class       => 'MyMySQLOtherObject4',
    key_columns => { fother_id4 => 'id4' },
  },

  my_my_sqlother_object => 
  {
    class       => 'MyMySQLOtherObject',
    key_columns => 
    {
      fk1 => 'k1',
      fk2 => 'k2',
      fk3 => 'k3',
    },
  },
);
EOF

  my $mysql_41   = ($o->db->database_version >= 4_100_000) ? 1 : 0;
  my $mysql_5    = ($o->db->database_version >= 5_000_000) ? 1 : 0;
  my $mylsq_5_51 = ($o->db->database_version >= 5_000_051) ? 1 : 0; 

  # XXX: Lame
  my $no_empty_def = (MyMySQLObject->meta->perl_class_definition(use_setup => 0) !~ /default => '', / ? 1 : 0);

  my $set_col = $mysql_5 ? 
    q(items         => { type => 'set', default => 'a,c', not_null => 1, values => [ 'a', 'b', 'c' ] },) :
    q(items         => { type => 'varchar', default => 'a,c', length => 255, not_null => 1 },);

  no warnings 'once';
  local $Rose::DB::Object::Metadata::Auto::Sort_Columns_Alphabetically = 1;

  my $serial = $o->db->dbh->{'Driver'}{'Version'} >= 4.002 ? 'serial' : 'integer';

  is(MyMySQLObject->meta->perl_class_definition(use_setup => 0),
     <<"EOF", "perl_class_definition (trad) 1 - $db_type");
package MyMySQLObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->table('Rose_db_object_test');

__PACKAGE__->meta->columns(
    bits          => { type => 'bitfield', bits => 5, default => 101 },
    date_created  => { type => 'datetime' },
    fk1           => { type => 'integer', alias => 'fkone' },
    fk2           => { type => 'integer' },
    fk3           => { type => 'integer' },
    flag          => { type => 'boolean', default => 1 },
    flag2         => { type => 'boolean' },
    fother_id2    => { type => 'integer' },
    fother_id3    => { type => 'integer' },
    fother_id4    => { type => 'integer' },
    id            => { type => '$serial', not_null => 1 },
    $set_col
    last_modified => { type => 'datetime' },
    name          => { type => 'varchar', @{[ $no_empty_def ? '' : "default => '', " ]}length => 32, not_null => 1 },
    save          => { type => 'integer', alias => 'save_col' },
    start         => { type => 'date', default => '1980-12-24' },
    status        => { type => 'varchar', default => 'active', length => 32 },
);

__PACKAGE__->meta->primary_key_columns([ 'id' ]);

__PACKAGE__->meta->allow_inline_column_values(1);

__PACKAGE__->meta->foreign_keys(
    fother => {
        class       => 'MyMySQLOtherObject2',
        key_columns => { fother_id2 => 'id2' },
    },

    fother2 => {
        class       => 'MyMySQLOtherObject3',
        key_columns => { fother_id3 => 'id3' },
    },

    fother3 => {
        class       => 'MyMySQLOtherObject4',
        key_columns => { fother_id4 => 'id4' },
    },

    my_my_sqlother_object => {
        class       => 'MyMySQLOtherObject',
        key_columns => {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
        },
    },
);

__PACKAGE__->meta->initialize;

1;
EOF

  is(MyMySQLObject->meta->perl_class_definition,
     <<"EOF", "perl_class_definition (trad) 1 - $db_type");
package MyMySQLObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->setup(
    table   => 'Rose_db_object_test',

    columns => [
        bits          => { type => 'bitfield', bits => 5, default => 101 },
        date_created  => { type => 'datetime' },
        fk1           => { type => 'integer', alias => 'fkone' },
        fk2           => { type => 'integer' },
        fk3           => { type => 'integer' },
        flag          => { type => 'boolean', default => 1 },
        flag2         => { type => 'boolean' },
        fother_id2    => { type => 'integer' },
        fother_id3    => { type => 'integer' },
        fother_id4    => { type => 'integer' },
        id            => { type => '$serial', not_null => 1 },
        $set_col
        last_modified => { type => 'datetime' },
        name          => { type => 'varchar', @{[ $no_empty_def ? '' : "default => '', " ]}length => 32, not_null => 1 },
        save          => { type => 'integer', alias => 'save_col' },
        start         => { type => 'date', default => '1980-12-24' },
        status        => { type => 'varchar', default => 'active', length => 32 },
    ],

    primary_key_columns => [ 'id' ],

    allow_inline_column_values => 1,

    foreign_keys => [
        fother => {
            class       => 'MyMySQLOtherObject2',
            key_columns => { fother_id2 => 'id2' },
        },

        fother2 => {
            class       => 'MyMySQLOtherObject3',
            key_columns => { fother_id3 => 'id3' },
        },

        fother3 => {
            class       => 'MyMySQLOtherObject4',
            key_columns => { fother_id4 => 'id4' },
        },

        my_my_sqlother_object => {
            class       => 'MyMySQLOtherObject',
            key_columns => {
                fk1 => 'k1',
                fk2 => 'k2',
                fk3 => 'k3',
            },
        },
    ],
);

1;
EOF

  MyMySQLObject->meta->auto_load_related_classes(1);

  is(MyMySQLObject->meta->perl_class_definition(braces => 'bsd', indent => 2, use_setup => 0),
     <<"EOF", "perl_class_definition (trad) 2 - $db_type");
package MyMySQLObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->table('Rose_db_object_test');

__PACKAGE__->meta->columns
(
  bits          => { type => 'bitfield', bits => 5, default => 101 },
  date_created  => { type => 'datetime' },
  fk1           => { type => 'integer', alias => 'fkone' },
  fk2           => { type => 'integer' },
  fk3           => { type => 'integer' },
  flag          => { type => 'boolean', default => 1 },
  flag2         => { type => 'boolean' },
  fother_id2    => { type => 'integer' },
  fother_id3    => { type => 'integer' },
  fother_id4    => { type => 'integer' },
  id            => { type => '$serial', not_null => 1 },
  $set_col
  last_modified => { type => 'datetime' },
  name          => { type => 'varchar', @{[ $no_empty_def ? '' : "default => '', " ]}length => 32, not_null => 1 },
  save          => { type => 'integer', alias => 'save_col' },
  start         => { type => 'date', default => '1980-12-24' },
  status        => { type => 'varchar', default => 'active', length => 32 },
);

__PACKAGE__->meta->primary_key_columns([ 'id' ]);

__PACKAGE__->meta->allow_inline_column_values(1);

__PACKAGE__->meta->foreign_keys
(
  fother => 
  {
    class       => 'MyMySQLOtherObject2',
    key_columns => { fother_id2 => 'id2' },
  },

  fother2 => 
  {
    class       => 'MyMySQLOtherObject3',
    key_columns => { fother_id3 => 'id3' },
  },

  fother3 => 
  {
    class       => 'MyMySQLOtherObject4',
    key_columns => { fother_id4 => 'id4' },
  },

  my_my_sqlother_object => 
  {
    class       => 'MyMySQLOtherObject',
    key_columns => 
    {
      fk1 => 'k1',
      fk2 => 'k2',
      fk3 => 'k3',
    },
  },
);

__PACKAGE__->meta->initialize;

1;
EOF
}

#
# Informix
#

SKIP: foreach my $db_type ('informix')
{
  skip("Informix tests", 65)  unless($HAVE_INFORMIX);

  Rose::DB->default_type($db_type);

  my $o = MyInformixObject->new(name => 'John', id => 1);

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
  ok($oo1->save, 'other object save() 1');

  my $oo2 = MyInformixOtherObject->new(k1 => 11, k2 => 12, k3 => 13, name => 'two');
  ok($oo2->save, 'other object save() 2');

  my $other2 = MyInformixOtherObject2->new(id2 => 12, name => 'twelve');
  ok($other2->save, 'other 2 object save() 1');

  my $other3 = MyInformixOtherObject3->new(id3 => 13, name => 'thirteen');
  ok($other3->save, 'other 3 object save() 1');

  my $other4 = MyInformixOtherObject4->new(id4 => 14, name => 'fourteen');
  ok($other4->save, 'other 4 object save() 1');

  is($o->fother, undef, 'fother() 1');
  is($o->fother2, undef, 'fother2() 1');
  is($o->fother3, undef, 'fother3() 1');
  is($o->my_informix_other_object, undef, 'my_informix_other_object() 1');

  $o->fother_id2(12);
  $o->fother_id3(13);
  $o->fother_id4(14);
  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);

  my $obj = $o->my_informix_other_object or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyInformixOtherObject', 'my_informix_other_object() 2');
  is($obj->name, 'one', 'my_informix_other_object() 3');

  $obj = $o->fother or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyInformixOtherObject2', 'fother() 2');
  is($obj->name, 'twelve', 'fother() 3');

  $obj = $o->fother2 or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyInformixOtherObject3', 'fother2() 2');
  is($obj->name, 'thirteen', 'fother2() 3');

  $obj = $o->fother3 or warn "# ", $o->error, "\n";
  is(ref $obj, 'MyInformixOtherObject4', 'fother3() 2');
  is($obj->name, 'fourteen', 'fother3() 3');

  $o->my_informix_other_object(undef);
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);

  $obj = $o->my_informix_other_object or warn "# ", $o->error, "\n";

  is(ref $obj, 'MyInformixOtherObject', 'my_informix_other_object() 4');
  is($obj->name, 'two', 'my_informix_other_object() 5');

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');

  #
  # Test code generation
  #

  is(MyInformixObject->meta->perl_foreign_keys_definition,
     <<'EOF', "perl_foreign_keys_definition 1 - $db_type");
__PACKAGE__->meta->foreign_keys(
    fother => {
        class       => 'MyInformixOtherObject2',
        key_columns => { fother_id2 => 'id2' },
    },

    fother2 => {
        class       => 'MyInformixOtherObject3',
        key_columns => { fother_id3 => 'id3' },
    },

    fother3 => {
        class       => 'MyInformixOtherObject4',
        key_columns => { fother_id4 => 'id4' },
    },

    my_informix_other_object => {
        class       => 'MyInformixOtherObject',
        key_columns => {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
        },
    },
);
EOF

  is(MyInformixObject->meta->perl_foreign_keys_definition(braces => 'bsd', indent => 2),
     <<'EOF', "perl_foreign_keys_definition 2 - $db_type");
__PACKAGE__->meta->foreign_keys
(
  fother => 
  {
    class       => 'MyInformixOtherObject2',
    key_columns => { fother_id2 => 'id2' },
  },

  fother2 => 
  {
    class       => 'MyInformixOtherObject3',
    key_columns => { fother_id3 => 'id3' },
  },

  fother3 => 
  {
    class       => 'MyInformixOtherObject4',
    key_columns => { fother_id4 => 'id4' },
  },

  my_informix_other_object => 
  {
    class       => 'MyInformixOtherObject',
    key_columns => 
    {
      fk1 => 'k1',
      fk2 => 'k2',
      fk3 => 'k3',
    },
  },
);
EOF

  is(MyInformixObject->meta->perl_class_definition(use_setup => 0),
     <<'EOF', "perl_class_definition (trad) 1 - $db_type");
package MyInformixObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->table('Rose_db_object_test');

__PACKAGE__->meta->columns(
    bits          => { type => 'bitfield', bits => 5, default => 101 },
    date_created  => { type => 'datetime year to fraction(5)' },
    fk1           => { type => 'integer', alias => 'fkone' },
    fk2           => { type => 'integer' },
    fk3           => { type => 'integer' },
    flag          => { type => 'boolean', default => 't', not_null => 1 },
    flag2         => { type => 'boolean' },
    fother_id2    => { type => 'integer' },
    fother_id3    => { type => 'integer' },
    fother_id4    => { type => 'integer' },
    id            => { type => 'integer', not_null => 1 },
    last_modified => { type => 'datetime year to fraction(5)' },
    name          => { type => 'varchar', length => 32, not_null => 1 },
    nums          => { type => 'array' },
    save          => { type => 'integer', alias => 'save_col' },
    start         => { type => 'date', default => '12/24/1980' },
    status        => { type => 'varchar', default => 'active', length => 32 },
);

__PACKAGE__->meta->primary_key_columns([ 'id' ]);

__PACKAGE__->meta->foreign_keys(
    fother => {
        class       => 'MyInformixOtherObject2',
        key_columns => { fother_id2 => 'id2' },
    },

    fother2 => {
        class       => 'MyInformixOtherObject3',
        key_columns => { fother_id3 => 'id3' },
    },

    fother3 => {
        class       => 'MyInformixOtherObject4',
        key_columns => { fother_id4 => 'id4' },
    },

    my_informix_other_object => {
        class       => 'MyInformixOtherObject',
        key_columns => {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
        },
    },
);

__PACKAGE__->meta->initialize;

1;
EOF

  MyInformixObject->meta->auto_load_related_classes(1);

  is(MyInformixObject->meta->perl_class_definition(braces => 'bsd', indent => 2, use_setup => 0),
     <<'EOF', "perl_class_definition (trad) 2 - $db_type");
package MyInformixObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->table('Rose_db_object_test');

__PACKAGE__->meta->columns
(
  bits          => { type => 'bitfield', bits => 5, default => 101 },
  date_created  => { type => 'datetime year to fraction(5)' },
  fk1           => { type => 'integer', alias => 'fkone' },
  fk2           => { type => 'integer' },
  fk3           => { type => 'integer' },
  flag          => { type => 'boolean', default => 't', not_null => 1 },
  flag2         => { type => 'boolean' },
  fother_id2    => { type => 'integer' },
  fother_id3    => { type => 'integer' },
  fother_id4    => { type => 'integer' },
  id            => { type => 'integer', not_null => 1 },
  last_modified => { type => 'datetime year to fraction(5)' },
  name          => { type => 'varchar', length => 32, not_null => 1 },
  nums          => { type => 'array' },
  save          => { type => 'integer', alias => 'save_col' },
  start         => { type => 'date', default => '12/24/1980' },
  status        => { type => 'varchar', default => 'active', length => 32 },
);

__PACKAGE__->meta->primary_key_columns([ 'id' ]);

__PACKAGE__->meta->foreign_keys
(
  fother => 
  {
    class       => 'MyInformixOtherObject2',
    key_columns => { fother_id2 => 'id2' },
  },

  fother2 => 
  {
    class       => 'MyInformixOtherObject3',
    key_columns => { fother_id3 => 'id3' },
  },

  fother3 => 
  {
    class       => 'MyInformixOtherObject4',
    key_columns => { fother_id4 => 'id4' },
  },

  my_informix_other_object => 
  {
    class       => 'MyInformixOtherObject',
    key_columns => 
    {
      fk1 => 'k1',
      fk2 => 'k2',
      fk3 => 'k3',
    },
  },
);

__PACKAGE__->meta->initialize;

1;
EOF
}

#
# SQLite
#

SKIP: foreach my $db_type ('sqlite')
{
  skip("SQLite tests", 67)  unless($HAVE_SQLITE);

  Rose::DB->default_type($db_type);

  my $i = 1;

  foreach my $name (qw(id name flag flag2 status bits start save 
                       fk1 fk2 fk3 fother_id2 fother_id3 fother_id4
                       last_modified date_created nums))
  {
    MySQLiteObject->meta->column($name)->ordinal_position($i++);
  }

  my $o = MySQLiteObject->new(name => 'John', eyedee => 1);

  ok(ref $o && $o->isa('MySQLiteObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  my $o2 = MySQLiteObject->new(eyedee => $o->eyedee);

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

  my $o4 = MySQLiteObject->new(eyedee => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  ok($o->load, "load() 4 - $db_type");

  my $o5 = MySQLiteObject->new(eyedee => $o->eyedee);

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

  my $other2 = MySQLiteOtherObject2->new(id2 => 12, name => 'twelve');
  ok($other2->save, 'other 2 object save() 1');

  my $other3 = MySQLiteOtherObject3->new(id3 => 13, name => 'thirteen');
  ok($other3->save, 'other 3 object save() 1');

  my $other4 = MySQLiteOtherObject4->new(id4 => 14, name => 'fourteen');
  ok($other4->save, 'other 4 object save() 1');

  is($o->fother, undef, 'fother() 1');
  is($o->fother2, undef, 'fother2() 1');
  is($o->fother3, undef, 'fother3() 1');
  is($o->my_sqlite_other_object, undef, 'my_sqlite_other_object() 1');

  $o->fother_id2(12);
  $o->fother_id3(13);
  $o->fother_id4(14);
  $o->fkone(1);
  $o->fk2(2);
  $o->fk3(3);

  my $obj = $o->my_sqlite_other_object or warn "# ", $o->error, "\n";
  is(ref $obj, 'MySQLiteOtherObject', 'my_sqlite_other_object() 2');
  is($obj->name, 'one', 'my_sqlite_other_object() 3');

  $obj = $o->fother or warn "# ", $o->error, "\n";
  is(ref $obj, 'MySQLiteOtherObject2', 'fother() 2');
  is($obj->name, 'twelve', 'fother() 3');

  $obj = $o->fother2 or warn "# ", $o->error, "\n";
  is(ref $obj, 'MySQLiteOtherObject3', 'fother2() 2');
  is($obj->name, 'thirteen', 'fother2() 3');

  $obj = $o->fother3 or warn "# ", $o->error, "\n";
  is(ref $obj, 'MySQLiteOtherObject4', 'fother3() 2');
  is($obj->name, 'fourteen', 'fother3() 3');

  $o->my_sqlite_other_object(undef);
  $o->fkone(11);
  $o->fk2(12);
  $o->fk3(13);

  $obj = $o->my_sqlite_other_object or warn "# ", $o->error, "\n";

  is(ref $obj, 'MySQLiteOtherObject', 'my_sqlite_other_object() 4');
  is($obj->name, 'two', 'my_sqlite_other_object() 5');

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');

  #
  # Test code generation
  #

  is(MySQLiteObject->meta->perl_foreign_keys_definition,
     <<'EOF', "perl_foreign_keys_definition 1 - $db_type");
__PACKAGE__->meta->foreign_keys(
    fother => {
        class       => 'MySQLiteOtherObject2',
        key_columns => { fother_id2 => 'id2' },
    },

    fother2 => {
        class       => 'MySQLiteOtherObject3',
        key_columns => { fother_id3 => 'id3' },
    },

    fother3 => {
        class       => 'MySQLiteOtherObject4',
        key_columns => { fother_id4 => 'id4' },
    },

    my_sqlite_other_object => {
        class       => 'MySQLiteOtherObject',
        key_columns => {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
        },
    },
);
EOF

  is(MySQLiteObject->meta->perl_foreign_keys_definition(braces => 'bsd', indent => 2),
     <<'EOF', "perl_foreign_keys_definition 2 - $db_type");
__PACKAGE__->meta->foreign_keys
(
  fother => 
  {
    class       => 'MySQLiteOtherObject2',
    key_columns => { fother_id2 => 'id2' },
  },

  fother2 => 
  {
    class       => 'MySQLiteOtherObject3',
    key_columns => { fother_id3 => 'id3' },
  },

  fother3 => 
  {
    class       => 'MySQLiteOtherObject4',
    key_columns => { fother_id4 => 'id4' },
  },

  my_sqlite_other_object => 
  {
    class       => 'MySQLiteOtherObject',
    key_columns => 
    {
      fk1 => 'k1',
      fk2 => 'k2',
      fk3 => 'k3',
    },
  },
);
EOF

  is(MySQLiteObject->meta->perl_class_definition(use_setup => 0),
     <<'EOF', "perl_class_definition (trad) 1 - $db_type");
package MySQLiteObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->table('Rose_db_object_test');

__PACKAGE__->meta->columns(
    id            => { type => 'integer', alias => 'eyedee', not_null => 1 },
    name          => { type => 'varchar', length => 32, not_null => 1 },
    flag          => { type => 'boolean', default => 't', not_null => 1 },
    flag2         => { type => 'boolean' },
    status        => { type => 'varchar', default => 'active', length => 32 },
    bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
    start         => { type => 'date', default => '1980-12-24' },
    save          => { type => 'integer', alias => 'save_col' },
    fk1           => { type => 'integer', alias => 'fkone' },
    fk2           => { type => 'integer' },
    fk3           => { type => 'integer' },
    fother_id2    => { type => 'integer' },
    fother_id3    => { type => 'integer' },
    fother_id4    => { type => 'integer' },
    last_modified => { type => 'datetime' },
    date_created  => { type => 'datetime' },
    nums          => { type => 'array' },
);

__PACKAGE__->meta->primary_key_columns([ 'id' ]);

__PACKAGE__->meta->foreign_keys(
    fother => {
        class       => 'MySQLiteOtherObject2',
        key_columns => { fother_id2 => 'id2' },
    },

    fother2 => {
        class       => 'MySQLiteOtherObject3',
        key_columns => { fother_id3 => 'id3' },
    },

    fother3 => {
        class       => 'MySQLiteOtherObject4',
        key_columns => { fother_id4 => 'id4' },
    },

    my_sqlite_other_object => {
        class       => 'MySQLiteOtherObject',
        key_columns => {
            fk1 => 'k1',
            fk2 => 'k2',
            fk3 => 'k3',
        },
    },
);

__PACKAGE__->meta->initialize;

1;
EOF

  is(MySQLiteObject->meta->perl_class_definition,
     <<'EOF', "perl_class_definition 1 - $db_type");
package MySQLiteObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->setup(
    table   => 'Rose_db_object_test',

    columns => [
        id            => { type => 'integer', alias => 'eyedee', not_null => 1 },
        name          => { type => 'varchar', length => 32, not_null => 1 },
        flag          => { type => 'boolean', default => 't', not_null => 1 },
        flag2         => { type => 'boolean' },
        status        => { type => 'varchar', default => 'active', length => 32 },
        bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
        start         => { type => 'date', default => '1980-12-24' },
        save          => { type => 'integer', alias => 'save_col' },
        fk1           => { type => 'integer', alias => 'fkone' },
        fk2           => { type => 'integer' },
        fk3           => { type => 'integer' },
        fother_id2    => { type => 'integer' },
        fother_id3    => { type => 'integer' },
        fother_id4    => { type => 'integer' },
        last_modified => { type => 'datetime' },
        date_created  => { type => 'datetime' },
        nums          => { type => 'array' },
    ],

    primary_key_columns => [ 'id' ],

    foreign_keys => [
        fother => {
            class       => 'MySQLiteOtherObject2',
            key_columns => { fother_id2 => 'id2' },
        },

        fother2 => {
            class       => 'MySQLiteOtherObject3',
            key_columns => { fother_id3 => 'id3' },
        },

        fother3 => {
            class       => 'MySQLiteOtherObject4',
            key_columns => { fother_id4 => 'id4' },
        },

        my_sqlite_other_object => {
            class       => 'MySQLiteOtherObject',
            key_columns => {
                fk1 => 'k1',
                fk2 => 'k2',
                fk3 => 'k3',
            },
        },
    ],
);

1;
EOF

  MySQLiteObject->meta->auto_load_related_classes(0);

  is(MySQLiteObject->meta->perl_class_definition(braces => 'bsd', indent => 2, use_setup => 0),
     <<'EOF', "perl_class_definition (trad) 2 - $db_type");
package MySQLiteObject;

use strict;

use base qw(Rose::DB::Object);

use MySQLiteOtherObject;
use MySQLiteOtherObject2;
use MySQLiteOtherObject3;
use MySQLiteOtherObject4;

__PACKAGE__->meta->table('Rose_db_object_test');

__PACKAGE__->meta->columns
(
  id            => { type => 'integer', alias => 'eyedee', not_null => 1 },
  name          => { type => 'varchar', length => 32, not_null => 1 },
  flag          => { type => 'boolean', default => 't', not_null => 1 },
  flag2         => { type => 'boolean' },
  status        => { type => 'varchar', default => 'active', length => 32 },
  bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
  start         => { type => 'date', default => '1980-12-24' },
  save          => { type => 'integer', alias => 'save_col' },
  fk1           => { type => 'integer', alias => 'fkone' },
  fk2           => { type => 'integer' },
  fk3           => { type => 'integer' },
  fother_id2    => { type => 'integer' },
  fother_id3    => { type => 'integer' },
  fother_id4    => { type => 'integer' },
  last_modified => { type => 'datetime' },
  date_created  => { type => 'datetime' },
  nums          => { type => 'array' },
);

__PACKAGE__->meta->primary_key_columns([ 'id' ]);

__PACKAGE__->meta->foreign_keys
(
  fother => 
  {
    class       => 'MySQLiteOtherObject2',
    key_columns => { fother_id2 => 'id2' },
  },

  fother2 => 
  {
    class       => 'MySQLiteOtherObject3',
    key_columns => { fother_id3 => 'id3' },
  },

  fother3 => 
  {
    class       => 'MySQLiteOtherObject4',
    key_columns => { fother_id4 => 'id4' },
  },

  my_sqlite_other_object => 
  {
    class       => 'MySQLiteOtherObject',
    key_columns => 
    {
      fk1 => 'k1',
      fk2 => 'k2',
      fk3 => 'k3',
    },
  },
);

__PACKAGE__->meta->initialize;

1;
EOF

  MySQLiteObject->meta->auto_load_related_classes(1);

  is(MySQLiteObject->meta->perl_class_definition,
     <<'EOF', "perl_class_definition 2 - $db_type");
package MySQLiteObject;

use strict;

use base qw(Rose::DB::Object);

__PACKAGE__->meta->setup(
    table   => 'Rose_db_object_test',

    columns => [
        id            => { type => 'integer', alias => 'eyedee', not_null => 1 },
        name          => { type => 'varchar', length => 32, not_null => 1 },
        flag          => { type => 'boolean', default => 't', not_null => 1 },
        flag2         => { type => 'boolean' },
        status        => { type => 'varchar', default => 'active', length => 32 },
        bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
        start         => { type => 'date', default => '1980-12-24' },
        save          => { type => 'integer', alias => 'save_col' },
        fk1           => { type => 'integer', alias => 'fkone' },
        fk2           => { type => 'integer' },
        fk3           => { type => 'integer' },
        fother_id2    => { type => 'integer' },
        fother_id3    => { type => 'integer' },
        fother_id4    => { type => 'integer' },
        last_modified => { type => 'datetime' },
        date_created  => { type => 'datetime' },
        nums          => { type => 'array' },
    ],

    primary_key_columns => [ 'id' ],

    foreign_keys => [
        fother => {
            class       => 'MySQLiteOtherObject2',
            key_columns => { fother_id2 => 'id2' },
        },

        fother2 => {
            class       => 'MySQLiteOtherObject3',
            key_columns => { fother_id3 => 'id3' },
        },

        fother3 => {
            class       => 'MySQLiteOtherObject4',
            key_columns => { fother_id4 => 'id4' },
        },

        my_sqlite_other_object => {
            class       => 'MySQLiteOtherObject',
            key_columns => {
                fk1 => 'k1',
                fk2 => 'k2',
                fk3 => 'k3',
            },
        },
    ],
);

1;
EOF
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

    Rose::DB::Object::Metadata->unregister_all_classes;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_other');
      $dbh->do('DROP TABLE Rose_db_object_other2');
      $dbh->do('DROP TABLE Rose_db_object_other3');
      $dbh->do('DROP TABLE Rose_db_object_other4');
      $dbh->do('DROP TABLE Rose_db_object_chkpass_test');
    }

    our $PG_HAS_CHKPASS = pg_has_chkpass();

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other
(
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32),

  PRIMARY KEY(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other2
(
  id2   SERIAL PRIMARY KEY,
  name  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other3
(
  id3   SERIAL PRIMARY KEY,
  name  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other4
(
  id4   SERIAL PRIMARY KEY,
  name  VARCHAR(32)
)
EOF
    # Create test foreign subclass 1

    package MyPgOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('pg') }

    MyPgOtherObject->meta->table('Rose_db_object_other');

    MyPgOtherObject->meta->auto_initialize;

    # Create test foreign subclasses 2-4

    package MyPgOtherObject2;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg') }
    MyPgOtherObject2->meta->table('Rose_db_object_other2');
    MyPgOtherObject2->meta->auto_initialize;

    package MyPgOtherObject3;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg') }
    MyPgOtherObject3->meta->table('Rose_db_object_other3');
    MyPgOtherObject3->meta->auto_initialize;

    package MyPgOtherObject4;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg') }
    MyPgOtherObject4->meta->table('Rose_db_object_other4');
    MyPgOtherObject4->meta->auto_initialize;    

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             SERIAL PRIMARY KEY,
  @{[ $PG_HAS_CHKPASS ? 'password CHKPASS,' : '' ]}
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN NOT NULL DEFAULT 't',
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           BIT(5) NOT NULL DEFAULT B'00101',
  start          DATE DEFAULT '1980-12-24',
  save           INT,
  nums           INT[],
  fk1            INT,
  fk2            INT,
  fk3            INT,
  fother_id2     INT REFERENCES Rose_db_object_other2 (id2),
  fother_id3     INT REFERENCES Rose_db_object_other3 (id3),
  fother_id4     INT REFERENCES Rose_db_object_other4 (id4),
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES Rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyPgObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('pg') }

    MyPgObject->meta->table('Rose_db_object_test');
    MyPgObject->meta->convention_manager(undef);

    MyPgObject->meta->column_name_to_method_name_mapper(sub
    {
      return ($_ eq 'fk1') ? 'fkone' : $_
    });

    MyPgObject->meta->auto_initialize;

    Test::More::ok(MyPgObject->can('fother'),  'fother() check - pg');
    Test::More::ok(MyPgObject->can('fother2'), 'fother2() check - pg');
    Test::More::ok(MyPgObject->can('fother3'), 'fother3() check - pg');

    package MyPgObjectEvalTest;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg') }

    eval 'package MyPgObjectEvalTest; ' . MyPgObject->meta->perl_foreign_keys_definition;
    Test::More::ok(!$@, 'perl_foreign_keys_definition eval - pg');
  }

  #
  # MySQL
  #

  my $db_version;

  eval
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;
    $db_version = $db->database_version;

    die "MySQL version too old"  unless($db_version >= 4_000_000);

    CLEAR:
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_other');
    }

    # Foreign key stuff requires InnoDB support
    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other
(
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32),

  PRIMARY KEY(k1, k2, k3)
)
ENGINE=InnoDB
EOF

    # MySQL will silently ignore the "ENGINE=InnoDB" part and create
    # a MyISAM table instead.  MySQL is evil!  Now we have to manually
    # check to make sure an InnoDB table was really created.
    my $db_name = $db->database;
    my $sth = $dbh->prepare("SHOW TABLE STATUS FROM `$db_name` LIKE ?");
    $sth->execute('Rose_db_object_other');
    my $info = $sth->fetchrow_hashref;

    no warnings 'uninitialized';
    unless(lc $info->{'Type'} eq 'innodb' || lc $info->{'Engine'} eq 'innodb')
    {
      die "Missing InnoDB support";
    }
  };

  if(!$@ && $dbh)
  {
    our $HAVE_MYSQL_WITH_INNODB = 1;

    Rose::DB::Object::Metadata->unregister_all_classes;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_other');
      $dbh->do('DROP TABLE Rose_db_object_other2');
      $dbh->do('DROP TABLE Rose_db_object_other3');
      $dbh->do('DROP TABLE Rose_db_object_other4');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other
(
  k1    INT UNSIGNED NOT NULL,
  k2    INT UNSIGNED NOT NULL,
  k3    INT UNSIGNED NOT NULL,
  name  VARCHAR(32),

  PRIMARY KEY(k1, k2, k3)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other2
(
  id2   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(32)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other3
(
  id3   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(32)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other4
(
  id4   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(32)
)
ENGINE=InnoDB
EOF

    # Create test foreign subclass 1

    package MyMySQLOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLOtherObject->meta->table('Rose_db_object_other');

    MyMySQLOtherObject->meta->auto_initialize;

    # Create test foreign subclasses 2-4

    package MyMySQLOtherObject2;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('mysql') }
    MyMySQLOtherObject2->meta->table('Rose_db_object_other2');
    MyMySQLOtherObject2->meta->auto_initialize;

    package MyMySQLOtherObject3;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('mysql') }
    MyMySQLOtherObject3->meta->table('Rose_db_object_other3');
    MyMySQLOtherObject3->meta->auto_initialize;

    package MyMySQLOtherObject4;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('mysql') }
    MyMySQLOtherObject4->meta->table('Rose_db_object_other4');
    MyMySQLOtherObject4->meta->auto_initialize;    

    # MySQL 5.0.3 or later has a completely stupid "native" BIT type
    # which we want to avoid because DBI's column_info() method prints
    # a warning when it encounters such a column.
    my $bit_col = 
      ($db_version >= 5_000_003) ?
        q(bits  TINYINT(1) NOT NULL DEFAULT '00101') :
        q(bits  BIT(5) NOT NULL DEFAULT '00101');

    my $set_col = 
      ($db_version >= 5_000_000) ?
        q(items  SET('a','b','c') NOT NULL DEFAULT 'a,c') :
        q(items  VARCHAR(255) NOT NULL DEFAULT 'a,c');

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             INT AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  flag           TINYINT(1) NOT NULL,
  flag2          TINYINT(1),
  status         VARCHAR(32) DEFAULT 'active',
  $bit_col,
  $set_col,
  start          DATE DEFAULT '1980-12-24',
  save           INT,
  fk1            INT UNSIGNED,
  fk2            INT UNSIGNED,
  fk3            INT UNSIGNED,
  fother_id2     INT UNSIGNED,
  fother_id3     INT UNSIGNED,
  fother_id4     INT UNSIGNED,
  last_modified  DATETIME,
  date_created   DATETIME,

  INDEX(fother_id2),
  INDEX(fother_id3),
  INDEX(fother_id4),
  INDEX(fk1, fk2, fk3),

  FOREIGN KEY (fother_id2) REFERENCES Rose_db_object_other2 (id2) ON DELETE NO ACTION ON UPDATE SET NULL,
  FOREIGN KEY (fother_id3) REFERENCES Rose_db_object_other3 (id3) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY (fother_id4) REFERENCES Rose_db_object_other4 (id4) ON DELETE CASCADE ON UPDATE SET NULL,

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES Rose_db_object_other (k1, k2, k3)
)
ENGINE=InnoDB COMMENT='This is a very long comment.  This is a very long comment.'
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyMySQLObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLObject->meta->allow_inline_column_values(1);

    MyMySQLObject->meta->table('Rose_db_object_test');
    MyMySQLObject->meta->convention_manager(undef);

    MyMySQLObject->meta->column_name_to_method_name_mapper(sub
    {
      return ($_ eq 'fk1') ? 'fkone' : $_
    });

    MyMySQLObject->meta->auto_init_columns;

    # Account for bugs in DBD::mysql's column_info implementation

    # BIT(5) column shows up as TINYINT(1)
    MyMySQLObject->meta->column(bits => { type => 'bitfield', bits => 5, default => 101 });

    # BOOLEAN column shows up as TINYINT(1) even if you use the 
    # BOOLEAN keyword (which is not supported prior to MySQL 4.1,
    # so we're actually using TINYINT(1) in the definition above)
    MyMySQLObject->meta->column(flag  => { type => 'boolean', default => 1 });
    MyMySQLObject->meta->column(flag2 => { type => 'boolean' });

    MyMySQLObject->meta->auto_initialize;

    Test::More::ok(MyMySQLObject->can('fother'),  'fother() check - mysql');
    Test::More::ok(MyMySQLObject->can('fother2'), 'fother2() check - mysql');
    Test::More::ok(MyMySQLObject->can('fother3'), 'fother3() check - mysql');

    package MyMySQLObjectEvalTest;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('mysql') }

    eval 'package MyMySQLObjectEvalTest; ' . MyMySQLObject->meta->perl_foreign_keys_definition;
    Test::More::ok(!$@, 'perl_foreign_keys_definition eval - mysql');
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

    Rose::DB::Object::Metadata->unregister_all_classes;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test');
      $dbh->do('DROP TABLE Rose_db_object_other');
      $dbh->do('DROP TABLE Rose_db_object_other2');
      $dbh->do('DROP TABLE Rose_db_object_other3');
      $dbh->do('DROP TABLE Rose_db_object_other4');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other
(
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32),

  PRIMARY KEY(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other2
(
  id2   SERIAL PRIMARY KEY,
  name  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other3
(
  id3   SERIAL PRIMARY KEY,
  name  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other4
(
  id4   SERIAL PRIMARY KEY,
  name  VARCHAR(32)
)
EOF

    # Create test foreign subclass 1

    package MyInformixOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('informix') }

    MyInformixOtherObject->meta->table('Rose_db_object_other');

    MyInformixOtherObject->meta->auto_initialize;

    # Create test foreign subclasses 2-4

    package MyInformixOtherObject2;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('informix') }
    MyInformixOtherObject2->meta->table('Rose_db_object_other2');
    MyInformixOtherObject2->meta->auto_initialize;

    package MyInformixOtherObject3;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('informix') }
    MyInformixOtherObject3->meta->table('Rose_db_object_other3');
    MyInformixOtherObject3->meta->auto_initialize;

    package MyInformixOtherObject4;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('informix') }
    MyInformixOtherObject4->meta->table('Rose_db_object_other4');
    MyInformixOtherObject4->meta->auto_initialize;   

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             INT NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN DEFAULT 't' NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           VARCHAR(5) DEFAULT '00101' NOT NULL,
  start          DATE DEFAULT '12/24/1980',
  save           INT,
  nums           VARCHAR(255),
  fk1            INT,
  fk2            INT,
  fk3            INT,
  fother_id2     INT REFERENCES Rose_db_object_other2 (id2),
  fother_id3     INT REFERENCES Rose_db_object_other3 (id3),
  fother_id4     INT REFERENCES Rose_db_object_other4 (id4),
  last_modified  DATETIME YEAR TO FRACTION(5),
  date_created   DATETIME YEAR TO FRACTION(5),

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES Rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyInformixObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('informix') }

    MyInformixObject->meta->table('Rose_db_object_test');
    MyInformixObject->meta->convention_manager(undef);

    MyInformixObject->meta->column_name_to_method_name_mapper(sub
    {
      return ($_ eq 'fk1') ? 'fkone' : $_
    });

    # No native support for bit types in Informix
    MyInformixObject->meta->column(bits => { type => 'bitfield', bits => 5, default => 101 });

    # No native support for array types in Informix
    MyInformixObject->meta->column(nums => { type => 'array' });

    MyInformixObject->meta->auto_initialize;

    Test::More::ok(MyInformixObject->can('fother'),  'fother() check - informix');
    Test::More::ok(MyInformixObject->can('fother2'), 'fother2() check - informix');
    Test::More::ok(MyInformixObject->can('fother3'), 'fother3() check - informix');

    package MyInformixObjectEvalTest;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('informix') }

    eval 'package MyInformixObjectEvalTest; ' . MyInformixObject->meta->perl_foreign_keys_definition;
    Test::More::ok(!$@, 'perl_foreign_keys_definition eval - informix');
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

    Rose::DB::Object::Metadata->unregister_all_classes;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test');
      $dbh->do('DROP TABLE Rose_db_object_other');
      $dbh->do('DROP TABLE Rose_db_object_other2');
      $dbh->do('DROP TABLE Rose_db_object_other3');
      $dbh->do('DROP TABLE Rose_db_object_other4');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other
(
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32),

  PRIMARY KEY(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other2
(
  id2   INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other3
(
  id3   INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_other4
(
  id4   INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(32)
)
EOF

    # Create test foreign subclass 1

    package MySQLiteOtherObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteOtherObject->meta->table('Rose_db_object_other');

    MySQLiteOtherObject->meta->auto_initialize;

    # Create test foreign subclasses 2-4

    package MySQLiteOtherObject2;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('sqlite') }
    MySQLiteOtherObject2->meta->table('Rose_db_object_other2');
    MySQLiteOtherObject2->meta->auto_initialize;

    package MySQLiteOtherObject3;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('sqlite') }
    MySQLiteOtherObject3->meta->table('Rose_db_object_other3');
    MySQLiteOtherObject3->meta->auto_initialize;

    package MySQLiteOtherObject4;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('sqlite') }
    MySQLiteOtherObject4->meta->table('Rose_db_object_other4');
    MySQLiteOtherObject4->meta->auto_initialize;   

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             INT NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN DEFAULT 't' NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           BIT(5) DEFAULT '00101' NOT NULL,
  start          DATE DEFAULT '1980-12-24',
  save           INT,
  nums           VARCHAR(255),
  fk1            INT,
  fk2            INT,
  fk3            INT,
  fother_id2     INT REFERENCES Rose_db_object_other2 (id2),
  fother_id3     INT REFERENCES Rose_db_object_other3 (id3),
  fother_id4     INT REFERENCES Rose_db_object_other4 (id4),
  last_modified  DATETIME,
  date_created   DATETIME,

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES Rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyAutoSQLite;

    use base 'Rose::DB::Object::Metadata::Auto::SQLite';

    sub auto_alias_columns
    {
      my($self) = shift;

      foreach my $column (@_)
      {
        if($column->name eq 'fk1')     { $column->alias('fkone') }
        elsif($column->name eq 'save') { $column->alias('save_col') }
        elsif($column->name eq 'id')   { $column->alias('eyedee') }
      }
    }

    Rose::DB::Object::Metadata->auto_helper_class(sqlite => 'MyAutoSQLite');

    package MySQLiteObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('sqlite') }

    MySQLiteObject->meta->table('Rose_db_object_test');
    MySQLiteObject->meta->convention_manager(undef);

    #MySQLiteObject->meta->column_name_to_method_name_mapper(sub
    #{
    #  return ($_ eq 'fk1') ? 'fkone' : $_
    #});

    MySQLiteObject->meta->auto_initialize;

    # No native support for array types in SQLite
    MySQLiteObject->meta->delete_column('nums');
    MySQLiteObject->meta->add_column(nums => { type => 'array' });
    MySQLiteObject->meta->make_column_methods(replace_existing => 1);

    Test::More::ok(MySQLiteObject->can('fother'),  'fother() check - sqlite');
    Test::More::ok(MySQLiteObject->can('fother2'), 'fother2() check - sqlite');
    Test::More::ok(MySQLiteObject->can('fother3'), 'fother3() check - sqlite');

    package MySQLiteObjectEvalTest;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('sqlite') }

    eval 'package MySQLiteObjectEvalTest; ' . MySQLiteObject->meta->perl_foreign_keys_definition;
    Test::More::ok(!$@, 'perl_foreign_keys_definition eval - sqlite');
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

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_other');
    $dbh->do('DROP TABLE Rose_db_object_other2');
    $dbh->do('DROP TABLE Rose_db_object_other3');
    $dbh->do('DROP TABLE Rose_db_object_other4');

    $dbh->disconnect;
  }

  if($HAVE_MYSQL_WITH_INNODB)
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_other');
    $dbh->do('DROP TABLE Rose_db_object_other2');
    $dbh->do('DROP TABLE Rose_db_object_other3');
    $dbh->do('DROP TABLE Rose_db_object_other4');

    $dbh->disconnect;
  }

  if($HAVE_INFORMIX)
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_other');
    $dbh->do('DROP TABLE Rose_db_object_other2');

    $dbh->disconnect;
  }

  if($HAVE_SQLITE)
  {
    # SQLite
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test');
    $dbh->do('DROP TABLE Rose_db_object_other');
    $dbh->do('DROP TABLE Rose_db_object_other2');

    $dbh->disconnect;
  }
}
