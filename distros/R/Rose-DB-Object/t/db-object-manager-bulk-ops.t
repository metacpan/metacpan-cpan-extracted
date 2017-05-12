#!/usr/bin/perl -w

use strict;

use Test::More tests => 218;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('DateTime');
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Manager');
}

our($HAVE_PG, $HAVE_MYSQL, $HAVE_INFORMIX, $HAVE_SQLITE);

#
# PostgreSQL
#

SKIP: foreach my $db_type (qw(pg pg_with_schema))
{
  skip("PostgreSQL tests", 92)  unless($HAVE_PG);

  Rose::DB->default_type($db_type);

  # Test the subselect limit code
  #Rose::DB::Object::Manager->default_limit_with_subselect(1);

  TEST_HACK:
  {
    no warnings;
    *MyPgObject::init_db = sub { Rose::DB->new($db_type) };
  }

  my $o = MyPgObject->new(name    => 'John', 
                          code    => 1,
                          started => '1/1/2000',
                          num     => 10);

  ok($o->save, "save() 1 - $db_type");

  $o = MyPgObject->new(name    => 'Fred', 
                       code    => 2,
                       started => '1/2/1999',
                       num     => 20);

  ok($o->save, "save() 2 - $db_type");

  $o = MyPgObject->new(name    => 'Steve', 
                       code    => 3,
                       started => '1/3/1998',
                       num     => 30);

  ok($o->save, "save() 3 - $db_type");

  $o = MyPgObject->new(name    => 'Bud', 
                       code    => 4,
                       started => '1/4/1997',
                       num     => 40);

  ok($o->save, "save() 4 - $db_type");

  $o = MyPgObject->new(name    => 'Betty', 
                       code    => 5,
                       started => '1/5/1996',
                       num     => 50);

  ok($o->save, "save() 5 - $db_type");

  my $now        = DateTime->now;
  my $yesterday = $now->clone->subtract(days => 1);

  # Start update tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  my $num = 
    MyPgObject::Manager->update_objs(
      set   => 
      {
        num  => { sql => 'num + 1' },
        code => 'foo',
        data => "\000\001\002",
      },
      where => 
      [
        name    => { like => 'NoneSuch%' },
        started => { gt => [ $now, $yesterday, '1/1/2005' ] },
        data => { ne => "\000\001\002" },
      ]);

  ok(defined $num, "update 1 - $db_type");
  ok($num == 0, "update 2 - $db_type");
  is($num, '0', "update 3 - $db_type");

  eval
  {
    $num = 
      MyPgObject::Manager->update_objs(
        where => 
        [
          name    => { like => 'NoneSuch%' },
          started => { gt => [ $now, $yesterday, '1/1/2005' ] }
        ]);
  };

  ok($@, "update missing set 1 - $db_type");

  $num = 
    MyPgObject::Manager->update_objs(
      set => 
      {
        num => { sql => 'num + 1' },
      },
      where => 
      [
        name => { like => '%oh%' },
        or =>
        [
          started => { lt => $now },
          started => { lt => $yesterday },
          started => { lt => '1/1/2005' },
        ],
      ]);

  ok($num, "update 4 - $db_type");
  ok($num == 1, "update 5 - $db_type");
  is($num, 1, "update 6 - $db_type");

  $o = MyPgObject->new(name => 'John');
  $o->load;
  is($o->num, 11, "update verify 1 - $db_type");

  $o = MyPgObject->new(name => 'Fred');
  $o->load;
  is($o->num, 20, "update verify 2 - $db_type");

  $o = MyPgObject->new(name => 'Steve');
  $o->load;
  is($o->num, 30, "update verify 3 - $db_type");

  $o = MyPgObject->new(name => 'Bud');
  $o->load;
  is($o->num, 40, "update verify 4 - $db_type");

  $o = MyPgObject->new(name => 'Betty');
  $o->load;
  is($o->num, 50, "update verify 5 - $db_type");

  eval
  {
    $num = 
      MyPgObject::Manager->update_objs(
        set => 
        {
          ended => DateTime->new(year => 1999, month => 2, day => 3),
        });
  };

  ok($@, "update refused - $db_type");

  $num = 
    MyPgObject::Manager->update_objs(
      all => 1,
      set => 
      {
        data  => "\000\001\003",
        ended => DateTime->new(year => 1999, month => 2, day => 3),
      });

  ok($num, "update 7 - $db_type");
  ok($num == 5, "update 8 - $db_type");
  is($num, 5, "update 9 - $db_type");

  my $objs = MyPgObject::Manager->get_objs;

  my $test_num = 6;

  foreach my $obj (@$objs)
  {
    ok($obj->ended->ymd eq '1999-02-03', "update verify date $test_num - $db_type");
    ok($obj->data eq "\000\001\003", "update verify data $test_num - $db_type");
  }

  # End update tests

  # Start delete tests

  $num = 
    MyPgObject::Manager->delete_objs(
      where => 
      [
        name    => { like => 'NoneSuch%' },
        data    => "\000\001\003",
        started => { gt => [ $now, $yesterday, '1/1/2005' ] }
      ]);

  ok(defined $num, "delete 1 - $db_type");
  ok($num == 0, "delete 2 - $db_type");
  is($num, '0', "delete 3 - $db_type");

  $num = 
    MyPgObject::Manager->delete_objs(
      where => 
      [
        name    => { like => 'B%' },
        started => { lt => 'now' },
      ]);

  ok($num, "delete 4 - $db_type");
  ok($num == 2, "delete 5 - $db_type");
  is($num, 2, "delete 6 - $db_type");

  $num = 
    MyPgObject::Manager->delete_objs(
      where => 
      [
        name => { like => '%oh%' },
        num  => [ (1 .. 11) ],
        data => "\000\001\003",
      ]);

  ok($num, "delete 7 - $db_type");
  ok($num == 1, "delete 8 - $db_type");
  is($num, 1, "delete 9 - $db_type");

  $num = MyPgObject::Manager->get_objs_count;
  is($num, 2, "count remaining 1 - $db_type");

  eval { $num = MyPgObject::Manager->delete_objs };
  ok($@, "delete refuse - $db_type");

  $num = MyPgObject::Manager->delete_objs(all => 1);

  ok($num, "delete 10 - $db_type");
  ok($num == 2, "delete 11 - $db_type");
  is($num, 2, "delete 12 - $db_type");

  $num = MyPgObject::Manager->get_objs_count;
  is($num, 0, "count remaining 2 - $db_type");

  # End delete tests

  # End test of the subselect limit code
  #Rose::DB::Object::Manager->default_limit_with_subselect(0);
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 41)  unless($HAVE_MYSQL);

  Rose::DB->default_type($db_type);

  my $o = MyMySQLObject->new(name    => 'John', 
                             code    => 1,
                             started => '1/1/2000',
                             num     => 10);

  ok($o->save, "save() 1 - $db_type");

  $o = MyMySQLObject->new(name    => 'Fred', 
                          code    => 2,
                          started => '1/2/1999',
                          num     => 20);

  ok($o->save, "save() 2 - $db_type");

  $o = MyMySQLObject->new(name    => 'Steve', 
                          code    => 3,
                          started => '1/3/1998',
                          num     => 30);

  ok($o->save, "save() 3 - $db_type");

  $o = MyMySQLObject->new(name    => 'Bud', 
                          code    => 4,
                          started => '1/4/1997',
                          num     => 40);

  ok($o->save, "save() 4 - $db_type");

  $o = MyMySQLObject->new(name    => 'Betty', 
                          code    => 5,
                          started => '1/5/1996',
                          num     => 50);

  ok($o->save, "save() 5 - $db_type");

  my $now        = DateTime->now;
  my $yesterday = $now->clone->subtract(days => 1);

  # Start update tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  my $num = 
    MyMySQLObject::Manager->update_objs(
      set   => 
      {
        num  => { sql => 'num + 1' },
        code => 'foo',
      },
      where => 
      [
        name    => { like => 'NoneSuch%' },
        started => { gt => [ $now, $yesterday, '1/1/2005' ] }
      ]);

  ok(defined $num, "update 1 - $db_type");
  ok($num == 0, "update 2 - $db_type");
  is($num, '0', "update 3 - $db_type");

  eval
  {
    $num = 
      MyMySQLObject::Manager->update_objs(
        where => 
        [
          name    => { like => 'NoneSuch%' },
          started => { gt => [ $now, $yesterday, '1/1/2005' ] }
        ]);
  };

  ok($@, "update missing set 1 - $db_type");

  $num = 
    MyMySQLObject::Manager->update_objs(
      set => 
      {
        num => { sql => 'num + 1' },
      },
      where => 
      [
        name => { like => '%oh%' },
        or =>
        [
          started => { lt => $now },
          started => { lt => $yesterday },
          started => { lt => '1/1/2005' },
        ],
      ]);

  ok($num, "update 4 - $db_type");
  ok($num == 1, "update 5 - $db_type");
  is($num, 1, "update 6 - $db_type");

  $o = MyMySQLObject->new(name => 'John');
  $o->load;
  is($o->num, 11, "update verify 1 - $db_type");

  $o = MyMySQLObject->new(name => 'Fred');
  $o->load;
  is($o->num, 20, "update verify 2 - $db_type");

  $o = MyMySQLObject->new(name => 'Steve');
  $o->load;
  is($o->num, 30, "update verify 3 - $db_type");

  $o = MyMySQLObject->new(name => 'Bud');
  $o->load;
  is($o->num, 40, "update verify 4 - $db_type");

  $o = MyMySQLObject->new(name => 'Betty');
  $o->load;
  is($o->num, 50, "update verify 5 - $db_type");

  eval
  {
    $num = 
      MyMySQLObject::Manager->update_objs(
        set => 
        {
          ended => DateTime->new(year => 1999, month => 2, day => 3),
        });
  };

  ok($@, "update refused - $db_type");

  $num = 
    MyMySQLObject::Manager->update_objs(
      all => 1,
      set => 
      {
        ended => DateTime->new(year => 1999, month => 2, day => 3),
      });

  ok($num, "update 7 - $db_type");
  ok($num == 5, "update 8 - $db_type");
  is($num, 5, "update 9 - $db_type");

  my $objs = MyMySQLObject::Manager->get_objs;

  my $test_num = 6;

  foreach my $obj (@$objs)
  {
    ok($obj->ended->ymd eq '1999-02-03', "update verify $test_num - $db_type");
  }

  # End update tests

  # Start delete tests

  $num = 
    MyMySQLObject::Manager->delete_objs(
      where => 
      [
        name    => { like => 'NoneSuch%' },
        started => { gt => [ $now, $yesterday, '1/1/2005' ] }
      ]);

  ok(defined $num, "delete 1 - $db_type");
  ok($num == 0, "delete 2 - $db_type");
  is($num, '0', "delete 3 - $db_type");

  $num = 
    MyMySQLObject::Manager->delete_objs(
      where => 
      [
        name    => { like => 'B%' },
        started => { lt => 'now' },
      ]);

  ok($num, "delete 4 - $db_type");
  ok($num == 2, "delete 5 - $db_type");
  is($num, 2, "delete 6 - $db_type");

  $num = 
    MyMySQLObject::Manager->delete_objs(
      where => 
      [
        name => { like => '%oh%' },
        num  => [ (1 .. 11) ],
      ]);

  ok($num, "delete 7 - $db_type");
  ok($num == 1, "delete 8 - $db_type");
  is($num, 1, "delete 9 - $db_type");

  $num = MyMySQLObject::Manager->get_objs_count;
  is($num, 2, "count remaining 1 - $db_type");

  eval { $num = MyMySQLObject::Manager->delete_objs };
  ok($@, "delete refuse - $db_type");

  $num = MyMySQLObject::Manager->delete_objs(all => 1);

  ok($num, "delete 10 - $db_type");
  ok($num == 2, "delete 11 - $db_type");
  is($num, 2, "delete 12 - $db_type");

  $num = MyMySQLObject::Manager->get_objs_count;
  is($num, 0, "count remaining 2 - $db_type");

  # End delete tests
}

#
# Informix
#

SKIP: foreach my $db_type ('informix')
{
  skip("Informix tests", 41)  unless($HAVE_INFORMIX);

  Rose::DB->default_type($db_type);

  my $o = MyInformixObject->new(name    => 'John', 
                                code    => 1,
                                started => '1/1/2000',
                                num     => 10);

  ok($o->save, "save() 1 - $db_type");

  $o = MyInformixObject->new(name    => 'Fred', 
                             code    => 2,
                             started => '1/2/1999',
                             num     => 20);

  ok($o->save, "save() 2 - $db_type");

  $o = MyInformixObject->new(name    => 'Steve', 
                            code    => 3,
                            started => '1/3/1998',
                            num     => 30);

  ok($o->save, "save() 3 - $db_type");

  $o = MyInformixObject->new(name    => 'Bud', 
                             code    => 4,
                             started => '1/4/1997',
                             num     => 40);

  ok($o->save, "save() 4 - $db_type");

  $o = MyInformixObject->new(name    => 'Betty', 
                             code    => 5,
                             started => '1/5/1996',
                             num     => 50);

  ok($o->save, "save() 5 - $db_type");

  my $now        = DateTime->now;
  my $yesterday = $now->clone->subtract(days => 1);

  # Start update tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  my $num = 
    MyInformixObject::Manager->update_objs(
      set   => 
      {
        num  => { sql => 'num + 1' },
        code => 'foo',
      },
      where => 
      [
        name    => { like => 'NoneSuch%' },
        started => { gt => [ $now, $yesterday, '1/1/2005' ] }
      ]);

  ok(defined $num, "update 1 - $db_type");
  ok($num == 0, "update 2 - $db_type");
  is($num, '0', "update 3 - $db_type");

  eval
  {
    $num = 
      MyInformixObject::Manager->update_objs(
        where => 
        [
          name    => { like => 'NoneSuch%' },
          started => { gt => [ $now, $yesterday, '1/1/2005' ] }
        ]);
  };

  ok($@, "update missing set 1 - $db_type");

  $num = 
    MyInformixObject::Manager->update_objs(
      set => 
      {
        num => { sql => 'num + 1' },
      },
      where => 
      [
        name => { like => '%oh%' },
        or =>
        [
          started => { lt => $now },
          started => { lt => $yesterday },
          started => { lt => '1/1/2005' },
        ],
      ]);

  ok($num, "update 4 - $db_type");
  ok($num == 1, "update 5 - $db_type");
  is($num, 1, "update 6 - $db_type");

  $o = MyInformixObject->new(name => 'John');
  $o->load;
  is($o->num, 11, "update verify 1 - $db_type");

  $o = MyInformixObject->new(name => 'Fred');
  $o->load;
  is($o->num, 20, "update verify 2 - $db_type");

  $o = MyInformixObject->new(name => 'Steve');
  $o->load;
  is($o->num, 30, "update verify 3 - $db_type");

  $o = MyInformixObject->new(name => 'Bud');
  $o->load;
  is($o->num, 40, "update verify 4 - $db_type");

  $o = MyInformixObject->new(name => 'Betty');
  $o->load;
  is($o->num, 50, "update verify 5 - $db_type");

  eval
  {
    $num = 
      MyInformixObject::Manager->update_objs(
        set => 
        {
          ended => DateTime->new(year => 1999, month => 2, day => 3),
        });
  };

  ok($@, "update refused - $db_type");

  $num = 
    MyInformixObject::Manager->update_objs(
      all => 1,
      set => 
      {
        ended => DateTime->new(year => 1999, month => 2, day => 3),
      });

  ok($num, "update 7 - $db_type");
  ok($num == 5, "update 8 - $db_type");
  is($num, 5, "update 9 - $db_type");

  my $objs = MyInformixObject::Manager->get_objs;

  my $test_num = 6;

  foreach my $obj (@$objs)
  {
    ok($obj->ended->ymd eq '1999-02-03', "update verify $test_num - $db_type");
  }

  # End update tests

  # Start delete tests

  $num = 
    MyInformixObject::Manager->delete_objs(
      where => 
      [
        name    => { like => 'NoneSuch%' },
        started => { gt => [ $now, $yesterday, '1/1/2005' ] }
      ]);

  ok(defined $num, "delete 1 - $db_type");
  ok($num == 0, "delete 2 - $db_type");
  is($num, '0', "delete 3 - $db_type");

  $num = 
    MyInformixObject::Manager->delete_objs(
      where => 
      [
        name    => { like => 'B%' },
        started => { lt => 'now' },
      ]);

  ok($num, "delete 4 - $db_type");
  ok($num == 2, "delete 5 - $db_type");
  is($num, 2, "delete 6 - $db_type");

  $num = 
    MyInformixObject::Manager->delete_objs(
      where => 
      [
        name => { like => '%oh%' },
        num  => [ (1 .. 11) ],
      ]);

  ok($num, "delete 7 - $db_type");
  ok($num == 1, "delete 8 - $db_type");
  is($num, 1, "delete 9 - $db_type");

  $num = MyInformixObject::Manager->get_objs_count;
  is($num, 2, "count remaining 1 - $db_type");

  eval { $num = MyInformixObject::Manager->delete_objs };
  ok($@, "delete refuse - $db_type");

  $num = MyInformixObject::Manager->delete_objs(all => 1);

  ok($num, "delete 10 - $db_type");
  ok($num == 2, "delete 11 - $db_type");
  is($num, 2, "delete 12 - $db_type");

  $num = MyInformixObject::Manager->get_objs_count;
  is($num, 0, "count remaining 2 - $db_type");

  # End delete tests
}


#
# SQLite
#

SKIP: foreach my $db_type ('sqlite')
{
  skip("Informix tests", 41)  unless($HAVE_SQLITE);

  Rose::DB->default_type($db_type);

  my $o = MySQLiteObject->new(name    => 'John', 
                                code    => 1,
                                started => '1/1/2000',
                                num     => 10);

  ok($o->save, "save() 1 - $db_type");

  $o = MySQLiteObject->new(name    => 'Fred', 
                             code    => 2,
                             started => '1/2/1999',
                             num     => 20);

  ok($o->save, "save() 2 - $db_type");

  $o = MySQLiteObject->new(name    => 'Steve', 
                            code    => 3,
                            started => '1/3/1998',
                            num     => 30);

  ok($o->save, "save() 3 - $db_type");

  $o = MySQLiteObject->new(name    => 'Bud', 
                             code    => 4,
                             started => '1/4/1997',
                             num     => 40);

  ok($o->save, "save() 4 - $db_type");

  $o = MySQLiteObject->new(name    => 'Betty', 
                             code    => 5,
                             started => '1/5/1996',
                             num     => 50);

  ok($o->save, "save() 5 - $db_type");

  my $now        = DateTime->now;
  my $yesterday = $now->clone->subtract(days => 1);

  # Start update tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  my $num = 
    MySQLiteObject::Manager->update_objs(
      set   => 
      {
        num  => { sql => 'num + 1' },
        code => 'foo',
      },
      where => 
      [
        name    => { like => 'NoneSuch%' },
        started => { gt => [ $now, $yesterday, '1/1/2005' ] },
        [ \q(rose_db_object_test.num % 2 == ?) => 0 ],
      ]);

  ok(defined $num, "update 1 - $db_type");
  ok($num == 0, "update 2 - $db_type");
  is($num, '0', "update 3 - $db_type");

  eval
  {
    $num = 
      MySQLiteObject::Manager->update_objs(
        where => 
        [
          name    => { like => 'NoneSuch%' },
          started => { gt => [ $now, $yesterday, '1/1/2005' ] }
        ]);
  };

  ok($@, "update missing set 1 - $db_type");

  $num = 
    MySQLiteObject::Manager->update_objs(
      set => 
      {
        num => { sql => 'num + 1' },
      },
      where => 
      [
        name => { like => '%oh%' },
        or =>
        [
          started => { lt => $now },
          started => { lt => $yesterday },
          started => { lt => '1/1/2005' },
        ],
        [ \q(rose_db_object_test.num % 2 != ?) => 0 ],
      ]);

  ok($num, "update 4 - $db_type");
  ok($num == 1, "update 5 - $db_type");
  is($num, 1, "update 6 - $db_type");

  $o = MySQLiteObject->new(name => 'John');
  $o->load;
  is($o->num, 11, "update verify 1 - $db_type");

  $o = MySQLiteObject->new(name => 'Fred');
  $o->load;
  is($o->num, 20, "update verify 2 - $db_type");

  $o = MySQLiteObject->new(name => 'Steve');
  $o->load;
  is($o->num, 30, "update verify 3 - $db_type");

  $o = MySQLiteObject->new(name => 'Bud');
  $o->load;
  is($o->num, 40, "update verify 4 - $db_type");

  $o = MySQLiteObject->new(name => 'Betty');
  $o->load;
  is($o->num, 50, "update verify 5 - $db_type");

  eval
  {
    $num = 
      MySQLiteObject::Manager->update_objs(
        set => 
        {
          ended => DateTime->new(year => 1999, month => 2, day => 3),
        });
  };

  ok($@, "update refused - $db_type");

  $num = 
    MySQLiteObject::Manager->update_objs(
      all => 1,
      set => 
      {
        ended => DateTime->new(year => 1999, month => 2, day => 3),
      });

  ok($num, "update 7 - $db_type");
  ok($num == 5, "update 8 - $db_type");
  is($num, 5, "update 9 - $db_type");

  my $objs = MySQLiteObject::Manager->get_objs;

  my $test_num = 6;

  foreach my $obj (@$objs)
  {
    ok($obj->ended->ymd eq '1999-02-03', "update verify $test_num - $db_type");
  }

  # End update tests

  # Start delete tests

  $num = 
    MySQLiteObject::Manager->delete_objs(
      where => 
      [
        name    => { like => 'NoneSuch%' },
        started => { gt => [ $now, $yesterday, '1/1/2005' ] }
      ]);

  ok(defined $num, "delete 1 - $db_type");
  ok($num == 0, "delete 2 - $db_type");
  is($num, '0', "delete 3 - $db_type");

  $num = 
    MySQLiteObject::Manager->delete_objs(
      where => 
      [
        name    => { like => 'B%' },
        started => { lt => 'now' },
      ]);

  ok($num, "delete 4 - $db_type");
  ok($num == 2, "delete 5 - $db_type");
  is($num, 2, "delete 6 - $db_type");

  $num = 
    MySQLiteObject::Manager->delete_objs(
      where => 
      [
        name => { like => '%oh%' },
        num  => [ (1 .. 11) ],
      ]);

  ok($num, "delete 7 - $db_type");
  ok($num == 1, "delete 8 - $db_type");
  is($num, 1, "delete 9 - $db_type");

  $num = MySQLiteObject::Manager->get_objs_count;
  is($num, 2, "count remaining 1 - $db_type");

  eval { $num = MySQLiteObject::Manager->delete_objs };
  ok($@, "delete refuse - $db_type");

  $num = MySQLiteObject::Manager->delete_objs(all => 1);

  # $sth->rows is broken in DBD::SQLite
  # http://rt.cpan.org/NoAuth/Bug.html?id=16187

  ok(2, "delete 10 - $db_type");
  ok(2 == 2, "delete 11 - $db_type");
  is(2, 2, "delete 12 - $db_type");

  #ok($num, "delete 10 - $db_type");
  #ok($num == 2, "delete 11 - $db_type");
  #is($num, 2, "delete 12 - $db_type");

  $num = MySQLiteObject::Manager->get_objs_count;
  is($num, 0, "count remaining 2 - $db_type");

  # End delete tests
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
      $dbh->do('DROP TABLE rose_db_object_private.rose_db_object_test CASCADE');
      $dbh->do('CREATE SCHEMA rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id       SERIAL NOT NULL PRIMARY KEY,
  name     VARCHAR(32) NOT NULL,
  code     CHAR(6),
  started  DATE,
  ended    DATE,
  num      INT,
  data     BYTEA,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_private.rose_db_object_test
(
  id       SERIAL NOT NULL PRIMARY KEY,
  name     VARCHAR(32) NOT NULL,
  code     CHAR(6),
  started  DATE,
  ended    DATE,
  num      INT,
  data     BYTEA,

  UNIQUE(name)
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
      id       => { type => 'serial', primary_key => 1 },
      name     => { type => 'varchar', length => 32 },
      code     => { type => 'char', length => 6 },
      started  => { type => 'date', default => '12/24/1980' },
      ended    => { type => 'date', default => '1/1/2000' },
      num      => { type => 'int' },
      data     => { type => 'bytea' },
    );

    MyPgObject->meta->add_unique_key('name');
    MyPgObject->meta->initialize;

    package MyPgObject::Manager;
    our @ISA = qw(Rose::DB::Object::Manager);
    sub object_class { 'MyPgObject' }
    MyPgObject::Manager->make_manager_methods('objs');
  }

  #
  # MySQL
  #

  eval 
  {
    $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_MYSQL = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name     VARCHAR(32) NOT NULL,
  code     CHAR(6),
  started  DATE,
  ended    DATE,
  num      INT,

  UNIQUE(name)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyMySQLObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLObject->meta->table('rose_db_object_test');

    MyMySQLObject->meta->columns
    (
      id       => { type => 'serial', primary_key => 1 },
      name     => { type => 'varchar', length => 32 },
      code     => { type => 'char', length => 6 },
      started  => { type => 'date', default => '12/24/1980' },
      ended    => { type => 'date', default => '1/1/2000' },
      num      => { type => 'int' },
    );

    MyMySQLObject->meta->add_unique_key('name');
    MyMySQLObject->meta->initialize;

    package MyMySQLObject::Manager;
    our @ISA = qw(Rose::DB::Object::Manager);
    sub object_class { 'MyMySQLObject' }
    MyMySQLObject::Manager->make_manager_methods('objs');
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
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id       SERIAL NOT NULL PRIMARY KEY,
  name     VARCHAR(32) NOT NULL,
  code     CHAR(6),
  started  DATE,
  ended    DATE,
  num      INT,

  UNIQUE(name)
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
      id       => { type => 'serial', primary_key => 1 },
      name     => { type => 'varchar', length => 32 },
      code     => { type => 'char', length => 6 },
      started  => { type => 'date', default => '12/24/1980' },
      ended    => { type => 'date', default => '1/1/2000' },
      num      => { type => 'int' },
    );

    MyInformixObject->meta->add_unique_key('name');
    MyInformixObject->meta->initialize;

    package MyInformixObject::Manager;
    our @ISA = qw(Rose::DB::Object::Manager);
    sub object_class { 'MyInformixObject' }
    MyInformixObject::Manager->make_manager_methods('objs');  
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
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  name     VARCHAR(32) NOT NULL,
  code     CHAR(6),
  started  DATE,
  ended    DATE,
  num      INT,

  UNIQUE(name)
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
      id       => { type => 'serial', primary_key => 1 },
      name     => { type => 'varchar', length => 32 },
      code     => { type => 'char', length => 6 },
      started  => { type => 'date', default => '12/24/1980' },
      ended    => { type => 'date', default => '1/1/2000' },
      num      => { type => 'int' },
    );

    MySQLiteObject->meta->add_unique_key('name');
    MySQLiteObject->meta->initialize;

    package MySQLiteObject::Manager;
    our @ISA = qw(Rose::DB::Object::Manager);
    sub object_class { 'MySQLiteObject' }
    MySQLiteObject::Manager->make_manager_methods('objs');  
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
    $dbh->do('DROP TABLE rose_db_object_private.rose_db_object_test CASCADE');
    $dbh->do('DROP SCHEMA rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($HAVE_MYSQL)
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test CASCADE');

    $dbh->disconnect;
  }

  if($HAVE_INFORMIX)
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test CASCADE');

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
