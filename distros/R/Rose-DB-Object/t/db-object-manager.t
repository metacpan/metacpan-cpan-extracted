#!/usr/bin/perl -w

use strict;

use Test::More tests => 3917;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('DateTime');
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Manager');
}

use Rose::DateTime::Util qw(parse_date);

CONVENTION_AND_DEFAULTS_TESTS:
{
  package My::RDBO::CM;
  our @ISA = qw(Rose::DB::Object::ConventionManager);

  sub auto_manager_method_name
  {
    my($self, $type, $base_name, $object_class) = @_;

    if($type eq 'iterator')
    {
      return "get_${base_name}z_iter";
    }
    elsif($type eq 'delete')
    {
      return "del_${base_name}zz";
    }

    return undef; # rely on hard-coded defaults in Manager
  }

  sub auto_manager_class_name
  {
    my($self, $object_class) = @_;

    $object_class ||= $self->meta->class;

    return "${object_class}::Mgr";
  }

  package My::RDBO::Meta;
  our @ISA = qw(Rose::DB::Object::Metadata);

  sub init_convention_manager { My::RDBO::CM->new }

  package My::RDBO::Manager;
  our @ISA = qw(Rose::DB::Object::Manager);

  __PACKAGE__->default_manager_method_types(qw(iterator count delete));

  package My::RDBO::Test1;
  our @ISA = qw(Rose::DB::Object);
  __PACKAGE__->meta->table('test1s');
  sub meta_class { 'My::RDBO::Meta' }

  __PACKAGE__->meta->default_manager_base_class('My::RDBO::Managerxx');

  eval { local $SIG{'__DIE__'}; 

  __PACKAGE__->meta->make_manager_class };

  main::ok($@, 'make_manager_class exception 1');

  __PACKAGE__->meta->default_manager_base_class('My::RDBO::Manager');

  #local $Rose::DB::Object::Manager::Debug = 1;
  __PACKAGE__->meta->make_manager_class;

  package main;
  ok(My::RDBO::Test1::Mgr->can('get_test1sz_iter'), 'make_manager_class conventions 1');
  ok(My::RDBO::Test1::Mgr->can('get_test1s_count'), 'make_manager_class conventions 2');
  ok(My::RDBO::Test1::Mgr->can('del_test1szz'), 'make_manager_class conventions 3');
}

our($HAVE_PG, $HAVE_MYSQL, $HAVE_INFORMIX, $HAVE_SQLITE, $HAVE_ORACLE);

# XXX: TODO - outer join where fo is null

if(defined $ENV{'RDBO_NESTED_JOINS'} && Rose::DB::Object::Manager->can('default_nested_joins'))
{
  Rose::DB::Object::Manager->default_nested_joins($ENV{'RDBO_NESTED_JOINS'});
}

#
# PostgreSQL
#

SKIP: foreach my $db_type (qw(pg)) #pg_with_schema
{
  skip("PostgreSQL tests", 787)  unless($HAVE_PG);

  Rose::DB->default_type($db_type);

  # Test the subselect limit code
  #Rose::DB::Object::Manager->default_limit_with_subselect(1);

  my $db = MyPgObject->init_db;

  my $o = MyPgObject->new(db         => $db,
                          id         => 1,
                          name       => 'John',  
                          flag       => 't',
                          flag2      => 'f',
                          fkone      => 2,
                          status     => 'active',
                          bits       => '00001',
                          start      => '2001-01-02',
                          save_col   => 5,     
                          nums       => [ 1, 2, 3 ],
                          data       => "\000\001\002",
                          last_modified => 'now',
                          date_created  => '2004-03-30 12:34:56');

  ok($o->save, "object save() 1 - $db_type");

  my $objs = 
    MyPgObject->get_objectz(
      db           => $db,
      share_db     => 1,
      query_is_sql => 1,
      #debug => 1,
      where        =>
      [
        id         => { ge => 1 },
        id         => [ \'1', \'id' ], #'
        id         => { gt_lt => [ -1, 991 ] },
        id         => { gt_le => [ -1, 992 ] },
        id         => { ge_lt => [ -1, 993 ] },
        id         => { ge_le => [ -1, 994 ] },
        id         => { gt_lt_sql => [ -1, 991 ] },
        id         => { gt_le_sql => [ -1, 992 ] },
        id         => { ge_lt_sql => [ -1, 993 ] },
        id         => { ge_le_sql => [ -1, 994 ] },
        id         => { gt_lt => [ -1, \991 ] },
        id         => { gt_le => [ \-1, 992 ] },
        id         => { ge_lt => [ -1, \993 ] },
        id         => { ge_le => [ \-1, 994 ] },
        id         => { between => [ 0, 99 ] },
        id         => { between => [ 0, \q(101) ] },
        id         => { between => [ \1, 99 ] },
        id         => { ne => undef },
        name       => 'John',  
        flag       => 't',
        flag2      => 'f',
        flag2      => { is => \q(false) },
        flag2      => { is_not => \q(true) },
        flag2      => { is_not => undef },
        '!flag2'   => { is => undef },
        status     => 'active',
        bits       => '00001',
        fixed      => { like => 'nee%' },
        or         => [ and => [ '!bits' => '00001', bits => { ne => '11111' } ],
                        and => [ bits => { lt => '10101' }, '!bits' => '10000' ] ],
        start      => '2001-01-02',
        start      => { lt => \q('now'::date + interval '30 days') },
        start      => { between => [ '1/1/1999', 'now' ] },
        start      => { between_sql => [ "'1999-02-02'", "'now'" ] },
        save       => [ 1, 5 ],
        nums       => '{1,2,3}',
        fk1        => 2,
        last_modified => { le => 'now' },
        date_created  => '2004-03-30 12:34:56'
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 2 - $db_type");

  my $o2 = $o->clone;
  $o2->db($db);
  $o2->id(2);
  $o2->name('Fred');

  ok($o2->save, "object save() 2 - $db_type");

  my $o3 = $o2->clone;
  $o3->db($db);
  $o3->id(3);
  $o3->name('Sue');

  ok($o3->save, "object save() 3 - $db_type");

  my $o4 = $o3->clone;
  $o4->db($db);
  $o4->id(4);
  $o4->name('Bob');

  ok($o4->save, "object save() 4 - $db_type");

  eval
  {
    $objs = 
      MyPgObjectManager->get_objectz(
        where  =>
        [
          date_created => '205-1-2', # invalid date
        ]);
  };

  ok($@, "Invalid date - $db_type");

  eval
  {
    $objs = 
      MyPgObjectManager->get_objectz(
        query => [ flag => [] ]);
  };

  ok($@, "Empty list 1 - $db_type");

  $objs = 
    MyPgObjectManager->get_objectz(
      allow_empty_lists => 1,
      query  => [ flag => [] ]);

  is(scalar @$objs, 4, "Empty list 2 - $db_type");

  eval
  {
    $objs = 
      MyPgObjectManager->get_objectz(
        query => [ or => [ flag => 1, nums => { all_in_array => [] } ] ]);
  };

  ok($@, "Empty list 3 - $db_type");

  $objs = 
    MyPgObjectManager->get_objectz(
      allow_empty_lists => 1,
      query => [ or => [ flag => 1, nums => { all_in_array => [] } ] ]);

  is(scalar @$objs, 4, "Empty list 4 - $db_type");

  $objs = 
    MyPgObjectManager->get_objectz(
      db           => $db,
      share_db     => 1,
      query_is_sql => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start      => '2001-01-02',
        save       => [ 1, 5 ],
        nums       => '{1,2,3}',
        nums       => { all_in_array => [ 1, 3 ] },
        '!nums'    => { all_in_array => [ 1, 5, 9 ] }, 
        #'!nums'    => { all_in_set => [ 1, 5, 9 ] }, 
        nums       => { in_array => [ 2, 17 ] }, 
        '!nums'    => { in_array => 99 }, 
        last_modified => { le => 'now' },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is(ref $objs, 'ARRAY', "get_objects() 3 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 2, "get_objects() 4 - $db_type");
  is($objs->[0]->id, 3, "get_objects() 5 - $db_type");
  is($objs->[1]->id, 2, "get_objects() 6 - $db_type");

  my $count =
    MyPgObjectManager->object_count(
      share_db     => 1,
      query_is_sql => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start      => '2001-01-02',
        save       => [ 1, 5 ],
        nums       => '{1,2,3}',
        last_modified => { le => 'now' },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is($count, 2, "get_objects_count() 1 - $db_type");

  # Set up sub-object for this one test
  my $b1 = MyPgBB->new(id   => 1, name => 'one', db => $db);
  $b1->save;

  $objs->[0]->b1(1);
  $objs->[0]->save;

  $count =
    MyPgObjectManager->object_count(
      share_db     => 1,
      query_is_sql => 1,
      require_objects => [ 'bb1' ],
      query        =>
      [
        't2.name'  => { like => 'o%' },
        't2_name'  => { like => 'on%' },
        'bb1.name' => { like => '%n%' },
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start      => '2001-01-02',
        save       => [ 1, 5 ],
        nums       => '{1,2,3}',
        last_modified => { le => 'now' },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is($count, 1, "get_objects_count() require 1 - $db_type");

  $count = MyPgObjectManager->object_count(
    select   => 'name',
    distinct => 1,
    all      => 1,
  );

  is($count, 4, "get_objects_count() distinct column 1 - $db_type");

  $count = MyPgObjectManager->object_count(
    select   => [ 'status' ],
    distinct => 1,
    all      => 1,
  );

  is($count, 1, "get_objects_count() distinct column 2 - $db_type");

  # Clear sub-object
  $objs->[0]->b1(undef);
  $objs->[0]->save;
  $b1->delete;

  my $iterator = 
    MyPgObjectManager->get_objectz_iterator(
      db           => $db,
      share_db     => 1,
      query_is_sql => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start      => '2001-01-02',
        save       => [ 1, 5 ],
        nums       => '{1,2,3}',
        last_modified => { le => 'now' },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name');

  is(ref $iterator, 'Rose::DB::Object::Iterator', "get_objects_iterator() 1 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator next() 1 - $db_type");
  is($o->id, 2, "iterator next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator next() 3 - $db_type");
  is($o->id, 3, "iterator next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator next() 5 - $db_type");
  is($iterator->total, 2, "iterator total() - $db_type");

  my $fo = MyPgOtherObject->new(name => 'Foo 1',
                                k1   => 1,
                                k2   => 2,
                                k3   => 3,
                                db   => $db);

  ok($fo->save, "object save() 5 - $db_type");

  $fo = MyPgOtherObject->new(name => 'Foo 2',
                             k1   => 2,
                             k2   => 3,
                             k3   => 4,
                             db   => $db);

  ok($fo->save, "object save() 6 - $db_type");

  $fo = MyPgBB->new(id   => 1,
                    name => 'one',
                    db   => $db);
  ok($fo->save, "bb object save() 1 - $db_type");

  $fo = MyPgBB->new(id   => 2,
                    name => 'two',
                    db   => $db);
  ok($fo->save, "bb object save() 2 - $db_type");

  $fo = MyPgBB->new(id   => 3,
                    name => 'three',
                    db   => $db);
  ok($fo->save, "bb object save() 3 - $db_type");

  $fo = MyPgBB->new(id   => 4,
                    name => 'four',
                    db   => $db);
  ok($fo->save, "bb object save() 4 - $db_type");

  my $o5 = MyPgObject->new(db         => $db,
                           id         => 5,
                           name       => 'Betty',  
                           flag       => 'f',
                           flag2      => 't',
                           status     => 'with',
                           bits       => '10101',
                           start      => '2002-05-20',
                           save_col   => 123,
                           nums       => [ 4, 5, 6 ],
                           data       => "\000\001\002",
                           fkone      => 1,
                           fk2        => 2,
                           fk3        => 3,
                           b1         => 2,
                           b2         => 4,
                           last_modified => '2001-01-10 20:34:56',
                           date_created  => '2002-05-10 10:34:56');

  ok($o5->save, "object save() 7 - $db_type");

  my $fo1 = $o5->other_obj;

  ok($fo1 && ref $fo1 && $fo1->k1 == 1 && $fo1->k2 == 2 && $fo1->k3 == 3,
     "foreign object 1 - $db_type");

  $fo1 = $o5->bb1;
  ok($fo1 && ref $fo1 && $fo1->id == 2, "bb foreign object 1 - $db_type");

  $fo1 = $o5->bb2;
  ok($fo1 && ref $fo1 && $fo1->id == 4, "bb foreign object 2 - $db_type");

  $objs = 
    MyPgObjectManager->get_objectz(
      db           => $db,
      share_db     => 1,
      query_is_sql => 1,
      query        =>
      [
        't1.id'    => { ge => 2 },
        't1.name'  => { like => '%tt%' },
      ],
      require_objects => [ 'other_obj', 'bb1', 'bb2' ]);

  ok(ref $objs->[0]->{'other_obj'} eq 'MyPgOtherObject', "foreign object 2 - $db_type");
  is($objs->[0]->other_obj->k2, 2, "foreign object 3 - $db_type");

  is($objs->[0]->bb1->name, 'two', "bb foreign object 3 - $db_type");
  is($objs->[0]->bb2->name, 'four', "bb foreign object 4 - $db_type");

  $iterator =
    MyPgObjectManager->get_objectz_iterator(
      db           => $db,
      share_db     => 1,
      query_is_sql => 1,
      query        =>
      [
        't1.id'    => { ge => 2 },
        't1.name'  => { like => '%tt%' },
      ],
      require_objects => [ 'other_obj', 'bb1', 'bb2' ]);

  $o = $iterator->next;

  ok(ref $o->{'other_obj'} eq 'MyPgOtherObject', "foreign object 4 - $db_type");
  is($o->other_obj->k2, 2, "foreign object 5 - $db_type");

  is($o->bb1->name, 'two', "bb foreign object 5 - $db_type");
  is($o->bb2->name, 'four', "bb foreign object 6 - $db_type");

  # Start "one to many" tests

  ok($fo = MyPgNick->new(id   => 1,
                         o_id => 5,
                         nick => 'none',
                         type => { name => 'nt one', t2 => { name => 'nt2 one' } },
                         alts => [ { alt => 'alt one 1' },
                                   { alt => 'alt one 2' },
                                   { alt => 'alt one 3' }, ],
                         opts => [ { opt => 'opt one 1' },
                                   { opt => 'opt one 2' } ])->save,
     "nick object save() 1 - $db_type");

  $fo = MyPgNick->new(id   => 2,
                      db   => $db,
                      o_id => 2,
                      nick => 'ntwo',
                      type => { name => 'nt two', t2 => { name => 'nt2 two' } },
                      alts => [ { alt => 'alt two 1' } ]);
  ok($fo->save, "nick object save() 2 - $db_type");

  $fo = MyPgNick->new(id   => 3,
                      db   => $db,
                      o_id => 5,
                      nick => 'nthree',
                      type => { name => 'nt three', t2 => { name => 'nt2 three' } },
                      opts => [ { opt => 'opt three 1' },  { opt => 'opt three 2' } ]);
  ok($fo->save, "nick object save() 3 - $db_type");

  $fo = MyPgNick->new(id   => 4,
                      db   => $db,
                      o_id => 2,
                      nick => 'nfour',
                      type => { name => 'nt four', t2 => { name => 'nt2 four' } });
  ok($fo->save, "nick object save() 4 - $db_type");

  $fo = MyPgNick->new(id   => 5,
                      db   => $db,
                      o_id => 5,
                      nick => 'nfive',
                      type => { name => 'nt five', t2 => { name => 'nt2 five' } });
  ok($fo->save, "nick object save() 5 - $db_type");

  $fo = MyPgNick->new(id   => 6,
                      db   => $db,
                      o_id => 5,
                      nick => 'nsix',
                      type => { name => 'nt six', t2 => { name => 'nt2 six' } });
  ok($fo->save, "nick object save() 6 - $db_type");
  # 
#   ok($fo = MyPgNick->new(id   => 1,
#                          o_id => 5,
#                          db   => $db,
#                          nick => 'none')->save,
#       "nick object save() 1 - $db_type");
# 
#   $fo = MyPgNick->new(id   => 2,
#                       o_id => 2,
#                       db   => $db,
#                       nick => 'ntwo');
#   ok($fo->save, "nick object save() 2 - $db_type");
# 
#   $fo = MyPgNick->new(id   => 3,
#                       o_id => 5,
#                       db   => $db,
#                       nick => 'nthree');
#   ok($fo->save, "nick object save() 3 - $db_type");
# 
#   $fo = MyPgNick->new(id   => 4,
#                       o_id => 2,
#                       db   => $db,
#                       nick => 'nfour');
#   ok($fo->save, "nick object save() 4 - $db_type");
# 
#   $fo = MyPgNick->new(id   => 5,
#                       o_id => 5,
#                       db   => $db,
#                       nick => 'nfive');
#   ok($fo->save, "nick object save() 5 - $db_type");
# 
#   $fo = MyPgNick->new(id   => 6,
#                       o_id => 5,
#                       db   => $db,
#                       nick => 'nsix');
#   ok($fo->save, "nick object save() 6 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $db->begin_work;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      with_objects => [ 'nicks.type' ],
      for_update   => 1,
      lock         =>
      {
        on     => [ qw(nicks rose_db_object_test) ],        
        nowait => 1,
      },
      query        =>
      [
        't1.id'    => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't2.nick'  => { like => 'n%' },
        data       => "\000\001\002",
        start      => '5/20/2002',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        or         => [],
        and        => [],
        save_col   => [ 1, 5, 123 ],
        nums       => [ 4, 5, 6 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  $db->commit;
  $db->begin_work;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      with_objects => [ 'nicks.type' ],
      lock         =>
      {
        type   => 'shared',
        tables => [ \q(t2), 'rose_db_object_test' ],
        nowait => 1,
      },
      query        =>
      [
        't1.id'    => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't2.nick'  => { like => 'n%' },
        data       => "\000\001\002",
        start      => '5/20/2002',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        or         => [],
        and        => [],
        save_col   => [ 1, 5, 123 ],
        nums       => [ 4, 5, 6 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  $db->commit;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      with_objects => [ 'nicks.type' ],
      query        =>
      [
        't1.id'    => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't2.nick'  => { like => 'n%' },
        data       => "\000\001\002",
        start      => '5/20/2002',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        or         => [],
        and        => [],
        save_col   => [ 1, 5, 123 ],
        nums       => [ 4, 5, 6 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() with many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 2 - $db_type");

  ok(!defined $objs->[0]->{'status'}, "lazy main 1 - $db_type");
  is($objs->[0]->status, 'with', "lazy main 2 - $db_type");

  my $object = MyPgObject->new(db => $db, id => $objs->[0]->id);
  $object->load(with => [ 'nicks.type' ]);
  is($object->{'status'}, undef, "lazy load(with) 1 - $db_type");

  my $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 5 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 7 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks', 'bb1' ],
      query        =>
      [
        't1.id'    => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't3.nick'  => { like => 'n%' },
        data       => "\000\001\002",
        start      => '5/20/2002',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        save_col   => [ 1, 5, 123 ],
        nums       => [ 4, 5, 6 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() with many 8 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 9 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 10 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 11 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 12 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 13 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 14 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many bb1 1 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many bb2 2 - $db_type");

  $iterator = 
    MyPgObjectManager->get_objectz_iterator(
      db           => $db,
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => [ 'nicks' ],
      sort_by => 't1.name');

  is(ref $iterator, 'Rose::DB::Object::Iterator', "get_objects_iterator() 1 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator many next() 1 - $db_type");
  is($o->id, 5, "iterator many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator many next() 3 - $db_type");
  is($o->id, 4, "iterator many next() 4 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator many next() 5 - $db_type");
  is($o->id, 2, "iterator many next() 6 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "iterator many sub-object 1 - $db_type");
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "iterator many sub-object 2 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "iterator many sub-object 3 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator many next() 7 - $db_type");
  is($o->id, 3, "iterator many next() 8 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator many next() 9 - $db_type");
  is($iterator->total, 4, "iterator many total() - $db_type");

  $iterator = 
    MyPgObjectManager->get_objectz_iterator(
      db           => $db,
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      sort_by => 't1.name',
      limit   => 2);

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator limit 2 many next() 1 - $db_type");
  is($o->id, 5, "iterator limit 2 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 2 many next() 3 - $db_type");
  is($o->id, 4, "iterator limit 2 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 2 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 2 many total() - $db_type");

  $iterator = 
    MyPgObjectManager->get_objectz_iterator(
      db           => $db,
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3);

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator limit 3 many next() 1 - $db_type");
  is($o->id, 5, "iterator limit 3 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 3 many next() 3 - $db_type");
  is($o->id, 4, "iterator limit 3 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 3 many next() 5 - $db_type");
  is($o->id, 2, "iterator limit 3 many next() 6 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "iterator limit 3 many sub-object 1 - $db_type");
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "iterator limit 3 many sub-object 2 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "iterator limit 3 many sub-object 3 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 3 many next() 7 - $db_type");
  is($iterator->total, 3, "iterator limit 3 many total() - $db_type");

  $objs = 
    MyPgObjectManager->get_objectz(
      db           => $db,
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      sort_by => 't1.name',
      limit   => 2);

  ok(ref $objs && @$objs == 2, "get_objects() limit 2 many 1 - $db_type");
  is($objs->[0]->name, 'Betty', "get_objects() limit 2 many 2 - $db_type");
  is($objs->[0]->id, 5, "get_objects() limit 2 many 3 - $db_type");

  is($objs->[1]->name, 'Bob', "get_objects() limit 2 many 4 - $db_type");
  is($objs->[1]->id, 4, "get_objects() limit 2 many 5 - $db_type");

  $objs = 
    MyPgObjectManager->get_objectz(
      db           => $db,
      share_db     => 1,
      with_objects => [ 'nicks', 'bb2' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3);

  ok(ref $objs && @$objs == 3, "get_objects() limit 3 many 1 - $db_type");
  is($objs->[0]->name, 'Betty', "get_objects() limit 3 many 2 - $db_type");
  is($objs->[0]->id, 5, "get_objects() limit 3 many 3 - $db_type");

  is($objs->[1]->name, 'Bob', "get_objects() limit 3 many 4 - $db_type");
  is($objs->[1]->id, 4, "get_objects() limit 3 many 5 - $db_type");

  is($objs->[2]->name, 'Fred', "get_objects() limit 3 many 6 - $db_type");
  is($objs->[2]->id, 2, "get_objects() limit 3 many 7 - $db_type");
  is(scalar @{$objs->[2]->{'nicks'}}, 2, 'get_objects() limit 3 many sub-object 1');
  is($objs->[2]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 3 many sub-object 2');
  is($objs->[2]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 3 many sub-object 3');

  $iterator = 
    MyPgObjectManager->get_objectz_iterator(
      db           => $db,
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 2,
      offset  => 1);

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 2 offset 1 many next() 1 - $db_type");
  is($o->id, 4, "iterator limit 2 offset 1 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 2 offset 1 many next() 3 - $db_type");
  is($o->id, 2, "iterator limit 2 offset 1 many next() 4 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, 'iterator limit 2 offset 1 many sub-object 1');
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', 'iterator limit 2 offset 1 many sub-object 2');
  is($o->{'nicks'}[1]{'nick'}, 'nfour', 'iterator limit 2 offset 1 many sub-object 3');

  $o = $iterator->next;
  is($o, 0, "iterator limit 2 offset 1 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 2 offset 1 many total() - $db_type");

  $iterator = 
    MyPgObjectManager->get_objectz_iterator(
      db           => $db,
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3,
      offset  => 2);

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 3 offset 2 many next() 1 - $db_type");
  is($o->id, 2, "iterator limit 3 offset 2 many next() 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, 'iterator limit 3 offset 2 many sub-object 1');
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', 'iterator limit 3 offset 2 many sub-object 2');
  is($o->{'nicks'}[1]{'nick'}, 'nfour', 'iterator limit 3 offset 2 many sub-object 3');

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator limit 3 offset 2 many next() 3 - $db_type");
  is($o->id, 3, "iterator limit 3 offset 2 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 3 offset 2 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 3 offset 2 many total() - $db_type");

  $objs = 
    MyPgObjectManager->get_objectz(
      db           => $db,
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 2,
      offset  => 1);

  ok(ref $objs && @$objs == 2, "get_objects() limit 2 offset 1 many 1 - $db_type");
  is($objs->[0]->name, 'Bob', "get_objects() limit 2 offset 1 many 2 - $db_type");
  is($objs->[0]->id, 4, "get_objects() limit 2 offset 1 many 3 - $db_type");

  is($objs->[1]->name, 'Fred', "get_objects() limit 2 offset 1 many 4 - $db_type");
  is($objs->[1]->id, 2, "get_objects() limit 2 offset 1 many 5 - $db_type");
  is(scalar @{$objs->[1]->{'nicks'}}, 2, 'get_objects() limit 2 offset 1 many sub-object 1');
  is($objs->[1]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 2 offset 1 many sub-object 2');
  is($objs->[1]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 2 offset 1 many sub-object 3');

  $objs = 
    MyPgObjectManager->get_objectz(
      db           => $db,
      share_db     => 1,
      with_objects => [ 'nicks', 'bb2' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3,
      offset  => 2);

  ok(ref $objs && @$objs == 2, "get_objects() limit 3 offset 2 many 1 - $db_type");

  is($objs->[0]->name, 'Fred', "get_objects() limit 3 offset 2 many 2 - $db_type");
  is($objs->[0]->id, 2, "get_objects() limit 3 offset 2 many 3 - $db_type");
  is(scalar @{$objs->[0]->{'nicks'}}, 2, 'get_objects() limit 3 offset 2 many sub-object 1');
  is($objs->[0]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 3 offset 2 many sub-object 2');
  is($objs->[0]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 3 offset 2 many sub-object 3');

  is($objs->[1]->name, 'Sue', "get_objects() limit 3 offset 2 many 4 - $db_type");
  is($objs->[1]->id, 3, "get_objects() limit 3 offset 2 many 5 - $db_type");

  my $o6 = $o2->clone;
  $o6->db($db);
  $o6->id(60);
  $o6->fkone(undef);
  $o6->fk2(undef);
  $o6->fk3(undef);
  $o6->b1(undef);
  $o6->b2(2);
  $o6->name('Ted');

  ok($o6->save, "object save() 8 - $db_type");

  my $o7 = $o2->clone;
  $o7->db($db);
  $o7->id(70);
  $o7->b1(3);
  $o7->b2(undef);
  $o7->name('Joe');

  ok($o7->save, "object save() 9 - $db_type");

  my $o8 = $o2->clone;
  $o8->db($db);
  $o8->id(80);
  $o8->b1(undef);
  $o8->b2(undef);
  $o8->name('Pete');

  ok($o8->save, "object save() 10 - $db_type");

  $fo = MyPgNick->new(id   => 7,
                      o_id => 60,
                      db   => $db,
                      nick => 'nseven');

  ok($fo->save, "nick object save() 7 - $db_type");

  $fo = MyPgNick->new(id   => 8,
                      o_id => 60,
                      db   => $db,
                      nick => 'neight');

  ok($fo->save, "nick object save() 8 - $db_type");

  $fo = MyPgNick->new(id   => 9,
                      o_id => 60,
                      db   => $db,
                      nick => 'neight');

  ok($fo->save, "nick object save() 8 - $db_type");

  $fo = MyPgNick2->new(id    => 1,
                       o_id  => 5,
                       db    => $db,
                       nick2 => 'n2one');

  ok($fo->save, "nick2 object save() 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      query        => [ '!t1.id' => 5 ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 15 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 0, "get_objects() with many 16 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is($count, 1, "get_objects_count() require 1 - $db_type"); 

  #local $Rose::DB::Object::Manager::Debug = 1;  
  #$DB::single = 1;

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      require_objects => [ 'bb2' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is($count, 2, "get_objects_count() require 2 - $db_type"); 

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 17 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 18 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many 19 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 20 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 21 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 22 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 23 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 24 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      require_objects => [ 'bb1', 'bb2' ],
      with_objects    => [ 'nicks2', 'nicks' ],
      multi_many_ok   => 1,
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with multi many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with multi many 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with multi many 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with multi many 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with multi many 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with multi many 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with multi many 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with multi many 8 - $db_type");

  is($objs->[0]->{'nicks2'}[0]{'nick2'}, 'n2one', "get_objects() with multi many 9 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      require_objects => [ 'bb1', 'bb2' ],
      with_objects    => [ 'nicks2', 'nicks' ],
      multi_many_ok   => 1,
      query        => [ ],
      sort_by => 't1.id');

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator with and require 1 - $db_type");
  is($o->id, 5, "iterator with and require 2 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "iterator with and require 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "iterator with and require 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "iterator with and require 5 - $db_type");
  is($nicks->[2]->nick, 'none', "iterator with and require 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "iterator with and require 7 - $db_type");

  is($o->{'nicks2'}[0]{'nick2'}, 'n2one', "iterator with and require 8 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator with and require 9 - $db_type");
  is($iterator->total, 1, "iterator with and require 10 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks', 'bb1' ],
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 25 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 8, "get_objects() with many 26 - $db_type");

  my $ids = join(',', map { $_->id } @$objs);

  is($ids, '1,2,3,4,5,60,70,80', "get_objects() with many 27 - $db_type");

  $nicks = $objs->[4]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 28 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 29 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 30 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 31 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 32 - $db_type");

  is($objs->[6]->{'bb1'}->{'name'}, 'three', "get_objects() with many 33 - $db_type");
  ok(!defined $objs->[6]->{'bb2'}, "get_objects() with many 34 - $db_type");
  ok(!defined $objs->[6]->{'nicks'}, "get_objects() with many 35 - $db_type");

  ok(!defined $objs->[7]->{'bb1'}, "get_objects() with many 36 - $db_type");
  ok(!defined $objs->[7]->{'bb1'}, "get_objects() with many 37 - $db_type");
  ok(!defined $objs->[7]->{'nicks'}, "get_objects() with many 38 - $db_type");

  $fo = MyPgNick->new(id => 7);
  ok($fo->delete, "with many clean-up 1 - $db_type");

  $fo = MyPgNick->new(id => 8);
  ok($fo->delete, "with many clean-up 2 - $db_type");

  $fo = MyPgNick->new(id => 9);
  ok($fo->delete, "with many clean-up 3 - $db_type");

  ok($o6->delete, "with many clean-up 4 - $db_type");
  ok($o7->delete, "with many clean-up 5 - $db_type");
  ok($o8->delete, "with many clean-up 6 - $db_type");

  $fo = MyPgNick2->new(id => 1);
  ok($fo->delete, "with many clean-up 7 - $db_type");

  # End "one to many" tests

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      share_db     => 1,
      #debug => 1,
      query        =>
      [
        id         => { ge => 1 },
        name       => 'John',  
        flag       => 1,
        flag2      => 0,
        \q((1 = 1 and 5 > 2)),
        [ \q(fk1 > ?), 1 ],
        or =>
        [
          bits => '00001',
          \q((2 = 2 and 6 > 3)),
          fk1 => { gt => 1 },
          and =>
          [
            status => 'active',
            [ \q(7 > ?), 3 ],
          ],
        ],
        status     => 'active',
        bits       => '1',
        start      => '1/2/2001',
        data       => "\000\001\002",
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 1,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 2,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 3,
                              day   => 3)
        },

        save_col   => [ 1, 5 ],
        nums       => [ 1, 2, 3 ],
        fk1        => 2,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '3/30/2004 12:34:56 pm'
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() 7 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 8 - $db_type");

  $objs = 
    MyPgObjectManager->get_objectz(
      db           => $db,
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        k1         => { lt => 900 },
        or         => [ k1 => { ne => 99 }, k1 => 100 ],
        or         => [ and => [ id => { ne => 123 }, id => { lt => 100  } ],
                        and => [ id => { ne => 456 }, id => { lt => 300  } ] ],
        '!k2'      => { gt => 999 },
        '!t2.name' => 'z',
        start      => { lt => DateTime->new(year => '2005', month => 1, day => 1) },
        '!start'   => { gt => DateTime->new(year => '2005', month => 1, day => 1) },
        'rose_db_object_test.name'   => { like => '%tt%' },
        '!rose_db_object_other.name' => 'q',
        '!rose_db_object_other.name' => [ 'x', 'y' ],
      ],
      require_objects => [ 'other_obj' ]);

  ok(ref $objs->[0]->{'other_obj'} eq 'MyPgOtherObject', "foreign object 6 - $db_type");
  is($objs->[0]->other_obj->k2, 2, "foreign object 7 - $db_type");

  # Test limit with offset

  foreach my $id (6 .. 20)
  {
    my $o = $o5->clone;
    $o->db($db);
    $o->id($id);
    $o->name("Clone $id");

    ok($o->save, "object save() clone $id - $db_type");
  }

  $objs = 
    MyPgObjectManager->get_objectz(
      db           => $db,
      object_class => 'MyPgObject',
      sort_by      => 'id DESC',
      limit        => 2,
      offset       => 8);

  ok(ref $objs eq 'ARRAY' && @$objs == 2 && 
     $objs->[0]->id == 12 && $objs->[1]->id == 11,
     "get_objects() with offset - $db_type");

  $objs = 
    MyPgObjectManager->get_objectz(
      db           => $db,
      object_class => 'MyPgObject',
      sort_by      => 'id DESC',
      require_objects => [ 'other_obj' ],
      limit        => 2,
      offset       => 8);

  ok(ref $objs eq 'ARRAY' && @$objs == 2 && 
     $objs->[0]->id == 12 && $objs->[1]->id == 11,
     "get_objects() with objects and offset - $db_type");

  $iterator = 
    MyPgObjectManager->get_objectz_iterator(
      db           => $db,
      object_class => 'MyPgObject',
      sort_by      => 'id DESC',
      limit        => 2,
      offset       => 8);

  $o = $iterator->next;
  is($o->id, 12, "get_objects_iterator() with offset 1 - $db_type");

  $o = $iterator->next;
  is($o->id, 11, "get_objects_iterator() with offset 2 - $db_type");

  is($iterator->next, 0, "get_objects_iterator() with offset 3 - $db_type");

  eval
  {
    $objs = 
      MyPgObjectManager->get_objectz(

        object_class => 'MyPgObject',
        sort_by      => 'id DESC',
        offset       => 8)
  };

  ok($@ =~ /invalid without a limit/, "get_objects() missing offset - $db_type");

  eval
  {
    $iterator = 
      MyPgObjectManager->get_objectz_iterator(
        db           => $db,
        object_class => 'MyPgObject',
        sort_by      => 'id DESC',
        offset       => 8);
  };

  ok($@ =~ /invalid without a limit/, "get_objects_iterator() missing offset - $db_type");

  # Start *_sql comparison tests

  $o6->fk2(99);
  $o6->fk3(99);
  $o6->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ 'fk2' => { eq_sql => 'fk3' } ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq_sql 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq_sql 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq_sql 3 - $db_type");

  # End *_sql comparison tests

  # Start IN NULL tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyPgObject',
      query        => [ id => [ undef, 60 ], '!id' => \'id + 1' ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() in null 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() in null 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() in null 3 - $db_type");

  # End IN NULL tests

  # Start scalar ref tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyPgObject',
      query        => [ 'fk2' => \'fk3' ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq ref 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq ref 3 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyPgObject',
      query        => [ 'fk2' => [ \'fk3' ] ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 4 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq ref 5 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq ref 6 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyPgObject',
      query        => [ 'fk2' => { ne => \'fk3' } ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 7 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 16, "get_objects() eq ref 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyPgObject',
      query        => [ 'fk2' => { ne => [ \'fk3' ] } ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 9 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 16, "get_objects() eq ref 10 - $db_type");

  # End scalar ref tests

  # Start "many to many" tests

  $fo = MyPgColor->new(id => 1, name => 'Red', db => $db);
  $fo->save;

  $fo = MyPgColor->new(id => 2, name => 'Green', db => $db);
  $fo->save;

  $fo = MyPgColor->new(id => 3, name => 'Blue', db => $db);
  $fo->save;

  $fo = MyPgColorMap->new(id => 1, object_id => $o2->id, color_id => 1, db => $db);
  $fo->save;

  $fo = MyPgColorMap->new(id => 2, object_id => $o2->id, color_id => 3, db => $db);
  $fo->save;

  $o2->b1(4);
  $o2->b1(2);
  $o2->fkone(2);
  $o2->fk2(3);
  $o2->fk3(4);
  $o2->save;

  my @colors = $o2->colors;
  ok(@colors == 2 && $colors[0]->name eq 'Red' &&
     $colors[1]->name eq 'Blue', "Fetch many to many 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db            => $db,
      object_class  => 'MyPgObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_record',
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many 4 - $db_type");
  is($objs->[2]->id, 1, "get_objects() with many to many 5 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many 12 - $db_type");

  my $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many 15 - $db_type");

  is($colors->[0]->map_record->color_id, $colors->[0]->id, "map_record 1 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 2 - $db_type");
  is($colors->[1]->map_record->color_id, $colors->[1]->id, "map_record 3 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 4 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db            => $db,
      object_class  => 'MyPgObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_record',
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $objs = [];

  while(my $obj = $iterator->next)
  {
    push(@$objs, $obj);
  }

  is(ref $objs, 'ARRAY', "get_objects_iterator() with many to many map record 1 - $db_type");
  is(scalar @$objs, 3, "get_objects_iterator() with many to many map record  2 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  is($colors->[0]->map_record->color_id, $colors->[0]->id, "map_record 5 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 6 - $db_type");
  is($colors->[1]->map_record->color_id, $colors->[1]->id, "map_record 7 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db            => $db,
      object_class  => 'MyPgObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_rec',
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many 2 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  is($colors->[0]->map_rec->color_id, $colors->[0]->id, "map_rec 1 - $db_type");
  is($colors->[0]->map_rec->object_id, $objs->[1]->id, "map_rec 2 - $db_type");
  is($colors->[1]->map_rec->color_id, $colors->[1]->id, "map_rec 3 - $db_type");
  is($colors->[0]->map_rec->object_id, $objs->[1]->id, "map_rec 4 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db            => $db,
      object_class  => 'MyPgObject',
      share_db      => 1,
      with_objects  => [ 'bb1', 'nicks', 'other_obj', 'colors', 'bb2' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many (reorder) 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many (reorder) 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many (reorder) 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many (reorder) 4 - $db_type");
  is($objs->[2]->id, 1, "get_objects() with many to many (reorder) 5 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many (reorder) 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many (reorder) 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many (reorder) 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many (reorder) 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many (reorder) 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many (reorder) 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many (reorder) 12 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many (reorder) 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many (reorder) 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many (reorder) 15 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db              => $db,
      object_class    => 'MyPgObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many require with 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 2, "get_objects() with many to many require with 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many require with 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many require with 4 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many require with 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many require with 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many require with 12 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many require with 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many require with 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many require with 15 - $db_type");

  $fo1 = $objs->[1]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'two', "get_objects() with many to many require with 16 - $db_type");

  $fo1 = $objs->[0]->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 1', "get_objects() with many to many require with 17 - $db_type");

  $fo1 = $objs->[1]->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 2', "get_objects() with many to many require with 18 - $db_type");

  ok(!defined $objs->[0]->{'colors'}, "get_objects() with many to many require with 19 - $db_type");
  ok(!defined $objs->[1]->{'bb2'}, "get_objects() with many to many require with 20 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db            => $db,
      object_class  => 'MyPgObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many 1 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many 2 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many 5 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many 7 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many 8 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many 9 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many 10 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many 11 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many 12 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 13 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 14 - $db_type");

  $o = $iterator->next;
  is($o->name, 'John', "get_objects_iterator() with many to many 15 - $db_type");
  is($o->id, 1, "get_objects_iterator() with many to many 16 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many 17 - $db_type");
  is($iterator->total, 3, "get_objects_iterator() with many to many 18 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db            => $db,
      object_class  => 'MyPgObject',
      share_db      => 1,
      with_objects  => [ 'bb1', 'nicks', 'other_obj', 'colors', 'bb2' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ], data => { ne => "\001" }, 
                         data => { ne => \"'0'::bytea" } ], #"
      sort_by       => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many 19 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many 20 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many 21 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many 22 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many 23 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many 24 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many 25 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many 26 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many 27 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many 28 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many 29 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many 30 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 31 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 32 - $db_type");

  $o = $iterator->next;
  is($o->name, 'John', "get_objects_iterator() with many to many 33 - $db_type");
  is($o->id, 1, "get_objects_iterator() with many to many 34 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many 35 - $db_type");
  is($iterator->total, 3, "get_objects_iterator() with many to many 36 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db              => $db,
      object_class    => 'MyPgObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many require 1 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many require 2 - $db_type");

  $fo1 = $o->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 1', "get_objects_iterator() with many to many require 3 - $db_type");

  ok(!defined $o->{'colors'}, "get_objects_iterator() with many to many require 4 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many require 5 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many require 6 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many require 7 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many require 8 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many require 9 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many require 10 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many require 11 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many require 12 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many require 13 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many require 16 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'two', "get_objects_iterator() with many to many require 17 - $db_type");

  $fo1 = $o->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 2', "get_objects_iterator() with many to many require 18 - $db_type");

  ok(!defined $o->{'bb2'}, "get_objects_iterator() with many to many require 19 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many require 20 - $db_type");
  is($iterator->total, 2, "get_objects_iterator() with many to many require 21 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db              => $db,
      object_class    => 'MyPgObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name',
      limit           => 1,
      offset          => 5);

  ok(!$iterator->next, "get_objects_iterator() with many to many require 22 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db              => $db,
      object_class    => 'MyPgObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name',
      limit           => 1,
      offset          => 5);

  ok(@$objs == 0, "get_objects_iterator() with many to many require 23 - $db_type");

  # End "many to many" tests

  # Start multi-require tests

  $fo = MyPgColorMap->new(id => 3, object_id => 5, color_id => 2, db => $db);
  $fo->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db              => $db,
      object_class    => 'MyPgObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'colors', 'other_obj' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 2, "get_objects() multi many require 1 - $db_type");

  is($objs->[0]->id, 5, "get_objects() multi many require 2 - $db_type");
  is($objs->[1]->id, 2, "get_objects() multi many require 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() multi many require 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() multi many require 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() multi many require 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() multi many require 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() multi many require 8 - $db_type");

  $colors = $objs->[0]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 1, "get_objects() multi many require 9 - $db_type");
  ok($colors->[0]->id == 2 && $colors->[0]->name eq 'Green', "get_objects() multi many require 10 - $db_type");

  $nicks = $objs->[1]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 2, "get_objects() multi many require 11 - $db_type");
  is($nicks->[0]->nick, 'ntwo', "get_objects() multi many require 12 - $db_type");
  is($nicks->[1]->nick, 'nfour', "get_objects() multi many require 13 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() multi many require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() multi many require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[1]->name eq 'Blue', "get_objects() multi many require 16 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db              => $db,
      object_class    => 'MyPgObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'colors', 'other_obj' ],
      with_objects    => [ 'bb2' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 2, "get_objects() multi many with require 1 - $db_type");

  is($objs->[0]->id, 5, "get_objects() multi many with require 2 - $db_type");
  is($objs->[1]->id, 2, "get_objects() multi many with require 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() multi many with require 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() multi many with require 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() multi many with require 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() multi many with require 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() multi many with require 8 - $db_type");

  $colors = $objs->[0]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 1, "get_objects() multi many with require 9 - $db_type");
  ok($colors->[0]->id == 2 && $colors->[0]->name eq 'Green', "get_objects() multi many with require 10 - $db_type");

  $nicks = $objs->[1]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 2, "get_objects() multi many with require 11 - $db_type");
  is($nicks->[0]->nick, 'ntwo', "get_objects() multi many with require 12 - $db_type");
  is($nicks->[1]->nick, 'nfour', "get_objects() multi many with require 13 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() multi many with require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() multi many with require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[1]->name eq 'Blue', "get_objects() multi many with require 16 - $db_type");

  is($objs->[0]->{'bb2'}{'name'}, 'four', "get_objects() multi many with require 17 - $db_type");
  ok(!defined $objs->[1]->{'bb2'}{'name'}, "get_objects() multi many with require 18 - $db_type");

  MyPgNick->new(id => 7, o_id => 10,  nick => 'nseven', db => $db)->save;
  MyPgNick->new(id => 8, o_id => 11,  nick => 'neight', db => $db)->save;
  MyPgNick->new(id => 9, o_id => 12,  nick => 'nnine', db => $db)->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db              => $db,
      object_class    => 'MyPgObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'bb1' ],
      with_objects    => [ 'colors' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 5, "get_objects() multi many with require map 1 - $db_type");

  is($objs->[0]->id,  5, "get_objects() multi many with require map 2 - $db_type");
  is($objs->[1]->id, 10, "get_objects() multi many with require map 3 - $db_type");
  is($objs->[2]->id, 11, "get_objects() multi many with require map 4 - $db_type");
  is($objs->[3]->id, 12, "get_objects() multi many with require map 5 - $db_type");
  is($objs->[4]->id,  2, "get_objects() multi many with require map 6 - $db_type");

  # End multi-require tests

  # Start distinct tests

  my $i = 0;

  foreach my $distinct (1, [ 't1' ], [ 'rose_db_object_test' ])
  {
    $i++;

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        db              => $db,
        object_class    => 'MyPgObject',
        distinct        => $distinct,
        share_db        => 1,
        require_objects => [ 'nicks', 'colors', 'other_obj' ],
        multi_many_ok   => 1,
        sort_by         => 't1.name');

    is(scalar @$objs, 2, "get_objects() distinct multi many require $i.1 - $db_type");

    is($objs->[0]->id, 5, "get_objects() distinct multi many require $i.2 - $db_type");
    is($objs->[1]->id, 2, "get_objects() distinct multi many require $i.3 - $db_type");

    ok(!defined $objs->[0]->{'nicks'}, "get_objects() distinct multi many require $i.4 - $db_type");
    ok(!defined $objs->[0]->{'colors'}, "get_objects() distinct multi many require $i.5 - $db_type");

    ok(!defined $objs->[1]->{'nicks'}, "get_objects() distinct multi many require $i.6 - $db_type");
    ok(!defined $objs->[1]->{'colors'}, "get_objects() distinct multi many require $i.7 - $db_type");
  }

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  foreach my $distinct ([ 't2' ], [ 'rose_db_object_nicks' ], [ 'nicks' ])
  {
    $i++;

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        db              => $db,
        object_class    => 'MyPgObject',
        distinct        => $distinct,
        share_db        => 1,
        require_objects => [ 'nicks', 'colors', 'other_obj' ],
        multi_many_ok   => 1,
        nonlazy         => 1,
        sort_by         => 't1.name');

    is(scalar @$objs, 2, "get_objects() distinct multi many require $i.1 - $db_type");

    is($objs->[0]->id, 5, "get_objects() distinct multi many require $i.2 - $db_type");
    is($objs->[1]->id, 2, "get_objects() distinct multi many require $i.3 - $db_type");

    ok(defined $objs->[0]->{'nicks'}, "get_objects() distinct multi many require $i.4 - $db_type");
    ok(!defined $objs->[0]->{'colors'}, "get_objects() distinct multi many require $i.5 - $db_type");

    ok(defined $objs->[1]->{'nicks'}, "get_objects() distinct multi many require $i.6 - $db_type");
    ok(!defined $objs->[1]->{'colors'}, "get_objects() distinct multi many require $i.7 - $db_type");
  }

  # End distinct tests

  # Start pager tests

  is(Rose::DB::Object::Manager->default_objects_per_page, 20, 'default_objects_per_page 1');

  Rose::DB::Object::Manager->default_objects_per_page(3);

  my $per_page = Rose::DB::Object::Manager->default_objects_per_page;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 1,
      per_page     => 3);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 1.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 2.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => 3);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 3.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => -1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 4.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => -1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 5.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => undef);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 6.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => undef);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 7.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id');

  ok(scalar @$objs > 3, "pager 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 2,
      per_page     => 3);

  $i = 0;

  for(4 .. 6)
  {
    is($objs->[$i++]->id, $_, "pager 9.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 3,
      per_page     => 3);

  $i = 0;

  for(7 .. 9)
  {
    is($objs->[$i++]->id, $_, "pager 10.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 4,
      per_page     => 3);

  $i = 0;

  for(10 .. 11)
  {
    is($objs->[$i++]->id, $_, "pager 11.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 5,
      per_page     => 3);

  ok(scalar @$objs == 0, "pager 12 - $db_type");

  Rose::DB::Object::Manager->default_objects_per_page(20);

  # End pager tests

  # Start get_objects_from_sql tests

  $objs = 
    MyPgObjectManager->get_objects_from_sql(
      db  => $db,
      object_class => 'MyPgObject',
      prepare_cached => 1,
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  ok(scalar @$objs == 19, "get_objects_from_sql 1 - $db_type");
  is($objs->[18]->id, 1, "get_objects_from_sql 2 - $db_type");
  is($objs->[18]->save_col, 5, "get_objects_from_sql 3 - $db_type");
  is($objs->[18]->name, 'John', "get_objects_from_sql 4 - $db_type");

  $iterator = 
    MyPgObjectManager->get_objects_iterator_from_sql(
      db  => MyPgObject->init_db,
      object_class => 'MyPgObject',
      prepare_cached => 1,
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  for(0 .. 17) { $iterator->next }

  $o = $iterator->next;
  is($o->id, 1, "get_objects_iterator_from_sql 1 - $db_type");
  is($o->save_col, 5, "get_objects_iterator_from_sql 2 - $db_type");
  is($o->name, 'John', "get_objects_iterator_from_sql 3 - $db_type");
  ok(!$iterator->next,  "get_objects_iterator_from_sql 4 - $db_type");

  $objs = MyPgObjectManager->get_objects_from_sql(<<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  ok(scalar @$objs == 19, "get_objects_from_sql 5 - $db_type");
  is($objs->[18]->id, 1, "get_objects_from_sql 6 - $db_type");
  is($objs->[18]->save_col, 5, "get_objects_from_sql 7 - $db_type");
  is($objs->[18]->name, 'John', "get_objects_from_sql 8 - $db_type");

  $objs = 
    MyPgObjectManager->get_objects_from_sql(
      db   => $db,
      args => [ 19 ],
      prepare_options => { pg_placeholder_dollaronly => 1 },
      sql => <<'EOF');
SELECT * FROM rose_db_object_test WHERE id > $1 ORDER BY id DESC
EOF

  ok(scalar @$objs == 2, "get_objects_from_sql 9 - $db_type");
  is($objs->[0]->id, 60, "get_objects_from_sql 10 - $db_type");

  $iterator = 
    MyPgObjectManager->get_objects_iterator_from_sql(
      db   => $db,
      args => [ 19 ],
      prepare_options => { pg_placeholder_dollaronly => 1 },
      sql => <<'EOF');
SELECT * FROM rose_db_object_test WHERE id > $1 ORDER BY id DESC
EOF

  $o = $iterator->next;
  is($o->id, 60, "get_objects_iterator_from_sql 11 - $db_type");
  $iterator->finish();

  my $method = 
    MyPgObjectManager->make_manager_method_from_sql(
      get_em => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  $objs = MyPgObjectManager->get_em;

  ok(scalar @$objs == 19, "make_manager_method_from_sql 1 - $db_type");
  is($objs->[17]->id, 3, "make_manager_method_from_sql 2 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql 3 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql 4 - $db_type");  

  $objs = $method->('MyPgObjectManager');

  ok(scalar @$objs == 19, "make_manager_method_from_sql 5 - $db_type");
  is($objs->[17]->id, 3, "make_manager_method_from_sql 6 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql 7 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql 8 - $db_type");  

  $method = 
    MyPgObjectManager->make_manager_method_from_sql(
      iterator => 1, method => 'iter_em', sql => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  $iterator = MyPgObjectManager->iter_em;

  for(0 .. 16) { $iterator->next }

  $o = $iterator->next;
  is($objs->[17]->id, 3, "make_manager_method_from_sql iterator 1 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql iterator 2 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql iterator 3 - $db_type");  

  $iterator = $method->('MyPgObjectManager');

  for(0 .. 16) { $iterator->next }

  $o = $iterator->next;
  is($objs->[17]->id, 3, "make_manager_method_from_sql iterator 4 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql iterator 5 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql iterator 6 - $db_type");  

  $method = 
    MyPgObjectManager->make_manager_method_from_sql(
      get_more => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id > ? ORDER BY id DESC
EOF

  $objs = MyPgObjectManager->get_more(18);
  ok(scalar @$objs == 3, "make_manager_method_from_sql 9 - $db_type");
  is($objs->[2]->id, 19, "make_manager_method_from_sql 10 - $db_type");

  $method = 
    MyPgObjectManager->make_manager_method_from_sql(
      method => 'get_more_np',
      params => [ qw(id name) ],
      sql    => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE 
id > ? AND name != ? ORDER BY id DESC
EOF

  $objs = MyPgObjectManager->get_more_np(name => 'Nonesuch', id => 18);
  ok(scalar @$objs == 3, "make_manager_method_from_sql 11 - $db_type");
  is($objs->[2]->id, 19, "make_manager_method_from_sql 12 - $db_type");

  # End get_objects_from_sql tests

  # Start tough order tests

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyPgObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1);

  ok(@$objs == 5, "tough order 1 - $db_type");
  is($objs->[0]->id, 2, "tough order 2 - $db_type");
  is($objs->[1]->id, 5, "tough order 3 - $db_type");
  is($objs->[2]->id, 10, "tough order 4 - $db_type");
  is($objs->[3]->id, 11, "tough order 5 - $db_type");
  is($objs->[4]->id, 12, "tough order 6 - $db_type");

  is($objs->[0]{'nicks'}[0]{'nick'}, 'ntwo', "tough order 7 - $db_type");
  is($objs->[0]{'nicks'}[1]{'nick'}, 'nfour', "tough order 8 - $db_type");

  is($objs->[1]{'nicks'}[0]{'nick'}, 'nthree', "tough order 9 - $db_type");
  is($objs->[1]{'nicks'}[1]{'nick'}, 'nsix', "tough order 10 - $db_type");
  is($objs->[1]{'nicks'}[2]{'nick'}, 'none', "tough order 11 - $db_type");
  is($objs->[1]{'nicks'}[3]{'nick'}, 'nfive', "tough order 12 - $db_type");

  is($objs->[2]{'nicks'}[0]{'nick'}, 'nseven', "tough order 13 - $db_type");

  is($objs->[3]{'nicks'}[0]{'nick'}, 'neight', "tough order 14 - $db_type");

  is($objs->[4]{'nicks'}[0]{'nick'}, 'nnine', "tough order 15 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyPgObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1,
      sort_by         => 'name');

  ok(@$objs == 5, "tough order 16 - $db_type");
  is($objs->[0]->id, 5, "tough order 17 - $db_type");
  is($objs->[1]->id, 10, "tough order 18 - $db_type");
  is($objs->[2]->id, 11, "tough order 19 - $db_type");
  is($objs->[3]->id, 12, "tough order 20 - $db_type");
  is($objs->[4]->id, 2, "tough order 21 - $db_type");

  is($objs->[0]{'nicks'}[0]{'nick'}, 'nthree', "tough order 22 - $db_type");
  is($objs->[0]{'nicks'}[1]{'nick'}, 'nsix', "tough order 23 - $db_type");
  is($objs->[0]{'nicks'}[2]{'nick'}, 'none', "tough order 24 - $db_type");
  is($objs->[0]{'nicks'}[3]{'nick'}, 'nfive', "tough order 25 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 4, "tough order 26 - $db_type");

  is($objs->[1]{'nicks'}[0]{'nick'}, 'nseven', "tough order 27 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 1, "tough order 28 - $db_type");

  is($objs->[2]{'nicks'}[0]{'nick'}, 'neight', "tough order 29 - $db_type");
  is(scalar @{$objs->[2]{'nicks'}}, 1, "tough order 30 - $db_type");

  is($objs->[3]{'nicks'}[0]{'nick'}, 'nnine', "tough order 31 - $db_type");
  is(scalar @{$objs->[3]{'nicks'}}, 1, "tough order 32 - $db_type");

  is($objs->[4]{'nicks'}[0]{'nick'}, 'ntwo', "tough order 33 - $db_type");
  is($objs->[4]{'nicks'}[1]{'nick'}, 'nfour', "tough order 34 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 2, "tough order 35 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyPgObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1,
      sort_by         => 'name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nthree', "tough order 36 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nsix', "tough order 37 - $db_type");
  is($o->{'nicks'}[2]{'nick'}, 'none', "tough order 38 - $db_type");
  is($o->{'nicks'}[3]{'nick'}, 'nfive', "tough order 39 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "tough order 40 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nseven', "tough order 41 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 42 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'neight', "tough order 43 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 44 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nnine', "tough order 45 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 46 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "tough order 47 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "tough order 48 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "tough order 49 - $db_type");

  ok(!$iterator->next, "tough order 50 - $db_type");
  is($iterator->total, 5, "tough order 51 - $db_type");

  # End tough order tests

  # Start deep join tests

  eval 
  { 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      require_objects => [ 'nicks.type' ],
      with_objects    => [ 'nicks.type' ]);
  };

  ok($@, "deep join conflict 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      #debug => 1,
      object_class => 'MyPgObject',
      require_objects => [ 'nicks.type', 'nicks.type', 'nicks' ],
      with_objects    => [ 'nicks.type.t2', 'nicks.alts' ],
      multi_many_ok   => 1,
      nonlazy         => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'type.name');

  ok(@$objs == 2, "deep join 1 - $db_type");
  is($objs->[0]->id, 2, "deep join 2 - $db_type");
  is($objs->[1]->id, 5, "deep join 3 - $db_type");

  #SORT:
  #{
  #  $objs->[0]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[0]{'nicks'}} ];
  #}

  is($objs->[0]{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join 4 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join 5 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 2, "deep join 6 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join 7 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join 8 - $db_type");
  is($objs->[1]{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join 9 - $db_type");
  is($objs->[1]{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join 10 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 4, "deep join 11 - $db_type");

  is($objs->[0]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join 12 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join 13 - $db_type");

  is($objs->[0]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join 14 - $db_type");

  $objs->[1]{'nicks'}[1]{'alts'} = 
    [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[1]{'nicks'}[1]{'alts'}} ];
  is($objs->[1]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join 15 - $db_type");
  is($objs->[1]{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join 16 - $db_type");
  is($objs->[1]{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join 17 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[1]{'alts'}}, 3, "deep join 18 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      with_objects => [ 'nicks.type' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 21, "deep join with 1 - $db_type");
  is($objs->[0]->id, 1, "deep join with 2 - $db_type");
  is($objs->[1]->id, 2, "deep join with 3 - $db_type");
  is($objs->[2]->id, 3, "deep join with 4 - $db_type");
  is($objs->[16]->id, 17, "deep join with 5 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join with 6 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join with 7 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 2, "deep join with 8 - $db_type");

  #SORT:
  #{
  #  $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
  #}

  is($objs->[4]{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join with 9 - $db_type");
  is($objs->[4]{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join with 10 - $db_type");
  is($objs->[4]{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join with 11 - $db_type");
  is($objs->[4]{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join with 12 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 4, "deep join with 13 - $db_type");

  is(scalar @{$objs->[0]{'nicks'} ||= []}, 0, "deep join with 14 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db              => $db,
      object_class    => 'MyPgObject',
      require_objects => [ 'nicks.type', 'nicks.type', 'nicks' ],
      with_objects    => [ 'nicks.type.t2', 'nicks.alts' ],
      multi_many_ok   => 1,
      query           => [ 'id' => [ 2, 5 ] ],
      sort_by         => 'type.name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator 3 - $db_type");

  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join 3.1 - $db_type");

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator 3.1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator 3.2 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator 8 - $db_type");

  $o->{'nicks'}[1]{'alts'} = 
    [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join iterator 9 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join iterator 10 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join iterator 11 - $db_type");
  is(scalar @{$o->{'nicks'}[1]{'alts'}}, 3, "deep join iterator 12 - $db_type");

  ok(!$iterator->next, "deep join iterator 13 - $db_type");
  is($iterator->total, 2, "deep join iterator 14 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db           => $db,
      object_class => 'MyPgObject',
      with_objects => [ 'nicks.type' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  $o = $iterator->next;
  is($o->id, 1, "deep join with with iterator 1 - $db_type");

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join with with iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join with iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join with iterator 3 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join with iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join with iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join with iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join with iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join with iterator 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join iterator 9 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      require_objects => [ 'nicks.type.t2' ],
      query        => [ 'id' => [ 2, 5 ] ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 2, "deep join three-level 1 - $db_type");
  is($objs->[0]->id, 2, "deep join three-level 2 - $db_type");
  is($objs->[1]->id, 5, "deep join three-level 3 - $db_type");

  #SORT:
  #{
  #  $objs->[0]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[0]{'nicks'}} ];
  #}

  is($objs->[0]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join three-level 4 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join three-level 5 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 2, "deep join three-level 6 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join three-level 7 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join three-level 8 - $db_type");
  is($objs->[1]{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join three-level 9 - $db_type");
  is($objs->[1]{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join three-level 10 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 4, "deep join three-level 11 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      with_objects => [ 'nicks.type.t2' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 21, "deep join three-level 1 - $db_type");
  is($objs->[0]->id, 1, "deep join three-level 2 - $db_type");
  is($objs->[1]->id, 2, "deep join three-level 3 - $db_type");
  is($objs->[4]->id, 5, "deep join three-level 4 - $db_type");
  is($objs->[20]->id, 60, "deep join three-level 5 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join three-level 6 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join three-level 7 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 2, "deep join three-level 8 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[4]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join three-level 9 - $db_type");
  is($objs->[4]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join three-level 10 - $db_type");
  is($objs->[4]{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join three-level 11 - $db_type");
  is($objs->[4]{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join three-level 12 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 4, "deep join three-level 13 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db           => $db,
      object_class => 'MyPgObject',
      require_objects => [ 'nicks.type.t2' ],
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'type.name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator 3 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator 8 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db           => $db,
      object_class => 'MyPgObject',
      with_objects => [ 'nicks.type.t2' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  $o = $iterator->next;
  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator with 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator with 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator with 3 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join iterator with 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join iterator with 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join iterator with 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join iterator with 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator with 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join iterator with 9 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class => 'MyPgObject',
      require_objects => [ 'nicks.alts' ],
      multi_many_ok => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'alts.alt');

  ok(@$objs == 2, "deep join multi 1 - $db_type");
  is($objs->[0]->id, 2, "deep join multi 2 - $db_type");
  is($objs->[1]->id, 5, "deep join multi 3 - $db_type");

  is($objs->[0]{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi 4 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}[0]{'alts'}}, 1, "deep join multi 5 - $db_type");

  is($objs->[1]{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi 6 - $db_type");
  is($objs->[1]{'nicks'}[0]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi 7 - $db_type");
  is($objs->[1]{'nicks'}[0]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi 8 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[0]{'alts'}}, 3, "deep join multi 11 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      db           => $db,
      object_class  => 'MyPgObject',
      with_objects  => [ 'nicks.alts' ],
      multi_many_ok => 1,
      nonlazy       => 1,
      sort_by       => 'alts.alt');

  ok(@$objs == 21, "deep join multi with 1 - $db_type");
  is($objs->[1]->id, 2, "deep join multi with 2 - $db_type");
  is($objs->[4]->id, 5, "deep join multi with 3 - $db_type");

  SORT:
  {
    $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
    $objs->[1]{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[1]{'nicks'}[1]{'alts'}} ];
  }

  is($objs->[1]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi with with 4 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[1]{'alts'}}, 1, "deep join multi with 5 - $db_type");

  SORT:
  {
    $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
    $objs->[4]{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[4]{'nicks'}[1]{'alts'}} ];
  }

  is($objs->[4]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi with 6 - $db_type");
  is($objs->[4]{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi with 7 - $db_type");
  is($objs->[4]{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi with 8 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}[1]{'alts'}}, 3, "deep join multi with 11 - $db_type");

  is(scalar @{$objs->[0]{'nicks'} || []}, 0, "deep join multi with 12 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db           => $db,
      object_class => 'MyPgObject',
      require_objects => [ 'nicks.alts' ],
      multi_many_ok => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'alts.alt');

  $o = $iterator->next;
  is($o->id, 2, "deep join multi iter 1 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi iter 2 - $db_type");
  is(scalar @{$o->{'nicks'}[0]{'alts'}}, 1, "deep join multi iter 3 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi iter 4 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi iter 5 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi iter 6 - $db_type");
  is(scalar @{$o->{'nicks'}[0]{'alts'}}, 3, "deep join multi iter 7 - $db_type");

  ok(!$iterator->next, "deep join multi iter 8 - $db_type");
  is($iterator->total, 2, "deep join multi iter 9 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      db            => $db,
      object_class  => 'MyPgObject',
      with_objects  => [ 'nicks.alts' ],
      multi_many_ok => 1,
      nonlazy       => 1,
      #query => [ id => 2 ],
      sort_by       => 'alts.alt');

  $o = $iterator->next;
  is(scalar @{$o->{'nicks'} ||= []}, 0, "deep join multi iter with 1 - $db_type");

  $o = $iterator->next;

  SORT:
  {
    $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
    $o->{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
  }

  is($o->id, 2, "deep join multi iter with 2 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi iter with 3 - $db_type");
  is(scalar @{$o->{'nicks'}[1]{'alts'}}, 1, "deep join multi iter with 4 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  SORT:
  {
    $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
    $o->{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
  }

  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi iter with 5 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi iter with 6 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi iter with 7 - $db_type");
  is(scalar @{$o->{'nicks'}[1]{'alts'}}, 3, "deep join multi iter with 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join multi iter with 9 - $db_type");

  # End deep join tests

  # Start custom select tests

  my @selects =
  (
    't2.nick, id, t2.id, name, UPPER(name) AS derived, fk1',
    't1.id, t2.nick, t2.id, t1.name, UPPER(name) AS derived, t1.fk1',
    'rose_db_object_nicks.id, rose_db_object_test.id, rose_db_object_nicks.nick, rose_db_object_test.name, UPPER(name) AS derived',
    [ \q(t1.id + 0 AS id), qw(name t2.nick nicks.id), \q(UPPER(name) AS derived) ],
    [ qw(t2.nick t2.id t1.id t1.name), 'UPPER(name) AS derived' ],
    [ \q(UPPER(name) AS derived), qw(t2.id rose_db_object_nicks.nick rose_db_object_test.id rose_db_object_test.name) ],
    [ qw(rose_db_object_test.id rose_db_object_nicks.nick rose_db_object_test.name rose_db_object_nicks.id), 'UPPER(name) AS derived' ],
    [ qw(rose_db_object_test.id rose_db_object_test.name rose_db_object_nicks.nick t2.id), 'UPPER(name) AS derived' ],
  );

  $i = 0;

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        db              => $db,
        object_class    => 'MyPgObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && !defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && !defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        db              => $db,
        object_class    => 'MyPgObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && defined $objs->[0]->nicks->[0]->nick &&
       !defined $objs->[0]->nicks->[0]->type_id && !defined $objs->[0]->flag2 &&
       $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && defined $objs->[1]->nicks->[0]->nick &&
       !defined $objs->[1]->nicks->[0]->type_id && !defined $objs->[1]->flag2 &&
       $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  @selects =
  (
    't2.nick, t1.*, t2.id, name, UPPER(name) AS derived',
    [ qw(t2.nick t2.id t1.*), 'UPPER(name) AS derived' ],
  );

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MyPgObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyPgObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && defined $objs->[0]->nicks->[0]->nick &&
       !defined $objs->[0]->nicks->[0]->type_id && defined $objs->[0]->flag2 &&
       $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && defined $objs->[1]->nicks->[0]->nick &&
       !defined $objs->[1]->nicks->[0]->type_id && defined $objs->[1]->flag2 &&
       $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  @selects =
  (
    '*, name, UPPER(name) AS derived',
    [ '*', 'UPPER(name) AS derived' ],
  );

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MyPgObject',
        select          => $select,
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->flag2 && 
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyPgObject',
        select          => $select,
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && 
       defined $objs->[0]->flag2 && $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && 
       defined $objs->[1]->flag2 && $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  # End custom select tests

  # End test of the subselect limit code
  #Rose::DB::Object::Manager->default_limit_with_subselect(0);
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 793)  unless($HAVE_MYSQL);

  Rose::DB->default_type($db_type);

  Rose::DB->default_keyword_function_calls(1);

  my $o = MyMySQLObject->new(id         => 1,
                             name       => 'John',  
                             flag       => 1,
                             flag2      => 0,
                             fkone      => 2,
                             status     => 'active',
                             bits       => '00001',
                             start      => '2001-01-02',
                             save_col   => 5,
                             nums       => [ 1, 2, 3 ],
                             last_modified => 'now',
                             date_created  => '2004-03-30 12:34:56');

  ok($o->save, "object save() 1 - $db_type");

  my $msql_5 = ($o->db->database_version >= 5_000_003) ? 1 : 0;

  #local $Rose::DB::Object::Manager::Debug = 1;

  my $objs = 
    MyMySQLObject->get_objectz(
      #debug => 1,
      share_db     => 1,
      #hints => { calc_found_rows => 1, high_priority => 1, small_result => 1 },
      #hints => { rose_db_object_test => { calc_found_rows => 1, high_priority => 1, small_result => 1 } },
      #hints => { t1 => { calc_found_rows => 1, high_priority => 1, small_result => 1 } },
      query        =>
      [
        id         => { ge => 1 },
        id         => { ge => 1 },
        id         => [ \'1', \'id' ], #'
        id         => { gt_lt => [ -1, 991 ] },
        id         => { gt_le => [ -1, 992 ] },
        id         => { ge_lt => [ -1, 993 ] },
        id         => { ge_le => [ -1, 994 ] },
        id         => { gt_lt_sql => [ -1, 991 ] },
        id         => { gt_le_sql => [ -1, 992 ] },
        id         => { ge_lt_sql => [ -1, 993 ] },
        id         => { ge_le_sql => [ -1, 994 ] },
        id         => { gt_lt => [ -1, \991 ] },
        id         => { gt_le => [ \-1, 992 ] },
        id         => { ge_lt => [ -1, \993 ] },
        id         => { ge_le => [ \-1, 994 ] },
        id         => { between => [ 0, 99 ] },
        id         => { between => [ 0, \q(101) ] },
        id         => { between => [ \1, 99 ] },
        name       => 'John',  
        flag       => 1,
        flag2      => 0,
        \q((1 = 1 and 5 > 2)),
        [ \q(fk1 > ?), 1 ],
        or =>
        [
          bits => '00001',
          \q((2 = 2 and 6 > 3)),
          fk1 => { gt => 1 },
          and =>
          [
            status => 'active',
            status => { ne_sql => "'active'" },
            [ \q(7 > ?), 3 ],
          ],
        ],
        status     => 'active',
        bits       => '00001',
        ($msql_5 ? (items => { any_in_set => [ 'a', 'c' ] }) : ()),
        ($msql_5 ? (items => { any_in_set_sql => [ q('a'), q('c') ] }) : ()),
        ($msql_5 ? ('!items' => { any_in_set => [ 'x', 'y' ] }) : ()),
        ($msql_5 ? (items => { all_in_set => [ 'a', 'c' ] }) : ()),
        ($msql_5 ? ('!items' => { all_in_set => [ 'a', 'x' ] }) : ()),
        ($msql_5 ? (items => { in_set => 'a' }) : ()),
        ($msql_5 ? ('!items' => { in_set => 'x' }) : ()),
        ($msql_5 ? (items => { all_in_set => 'c' }) : ()),
        ($msql_5 ? (items => { '&' => 1 }) : ()),
        fixed      => { like => 'nee%' },
        or         => [ and => [ '!bits' => '00001', bits => { ne => '11111' } ],
                        and => [ bits => { lt => '10101' }, '!bits' => '10000' ] ],
        start      => '2001-01-02',
        start      => { le => \q(NOW()) },
        start      => { between => [ '1/1/1999', 'NOW()' ] },
        start      => { between_sql => [ "'1999-02-02'", 'NOW()' ] },
        save_col   => [ 1, 5 ],
        last_modified => { le => 'now' },
        date_created  => '2004-03-30 12:34:56',
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 2 - $db_type");

  my $o2 = $o->clone;
  $o2->id(2);
  $o2->name('Fred');

  ok($o2->save, "object save() 2 - $db_type");

  my $o3 = $o2->clone;
  $o3->id(3);
  $o3->name('Sue');

  ok($o3->save, "object save() 3 - $db_type");

  my $o4 = $o3->clone;
  $o4->id(4);
  $o4->name('Bob');

  ok($o4->save, "object save() 4 - $db_type");

  eval
  {
    $objs = 
      MyMySQLObjectManager->get_objectz(
        query  =>
        [
          date_created => '205-1-2', # invalid date
        ]);
  };

  ok($@, "Invalid date - $db_type");

  eval
  {
    $objs = 
      MyMySQLObjectManager->get_objectz(
        query => [ flag => [] ]);
  };

  ok($@, "Empty list 1 - $db_type");

  $objs = 
    MyMySQLObjectManager->get_objectz(
      allow_empty_lists => 1,
      query  => [ flag => [] ]);

  is(scalar @$objs, 4, "Empty list 2 - $db_type");

  eval
  {
    $objs = 
      MyMySQLObjectManager->get_objectz(
        query => [ or => [ flag => 1, status => [] ] ]);
  };

  ok($@, "Empty list 3 - $db_type");

  $objs = 
    MyMySQLObjectManager->get_objectz(
      allow_empty_lists => 1,
        query => [ or => [ flag => 1, status => [] ] ]);

  is(scalar @$objs, 4, "Empty list 4 - $db_type");

  $objs = 
    MyMySQLObjectManager->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 1,
        flag2      => 0,
        status     => 'active',
        bits       => '00001',
        start      => '2001-01-02',
        save_col   => [ 1, 5 ],
        last_modified => { le => 'now' },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is(ref $objs, 'ARRAY', "get_objects() 3 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 2, "get_objects() 4 - $db_type");
  is($objs->[0]->id, 3, "get_objects() 5 - $db_type");
  is($objs->[1]->id, 2, "get_objects() 6 - $db_type");

  my $count =
    MyMySQLObject->get_objectz_count(
      #debug        => 1,
      with_objects => [ 'bb1', 'nicks',  'bb2' ],
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 1,
        flag2      => 0,
        status     => 'active',
        bits       => '00001',
        start      => '2001-01-02',
        save_col   => [ 1, 5 ],
        last_modified => { le => 'now' },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      sort_by => 'name DESC');

  is($count, 2, "get_objects_count() 1 - $db_type");

  # Set up sub-object for this one test
  my $b1 = MyMySQLBB->new(id => 1, name => 'one');
  $b1->save;

  $objs->[0]->b1(1);
  $objs->[0]->save;

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $count =
    MyMySQLObjectManager->get_objectz_count(
      share_db     => 1,
      query_is_sql => 1,
      require_objects => [ 'bb1' ],
      query        =>
      [
        't2.name'  => { like => 'o%' },
        't2_name'  => { like => 'on%' },
        'bb1.name' => { like => '%n%' },
        'id'    => { ge => 2 },
        'name'  => { like => '%e%' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is($count, 1, "get_objects_count() require 1 - $db_type");

  $count = Rose::DB::Object::Manager->get_objects_count(
    object_class => 'MyMySQLObject',
    select       => 'name',
    distinct     => 1,
    all          => 1,
  );

  is($count, 4, "get_objects_count() distinct column 1 - $db_type");

  $count = Rose::DB::Object::Manager->get_objects_count(
    object_class => 'MyMySQLObject',
    select       => [ 'status' ],
    distinct     => 1,
    all          => 1,
  );

  is($count, 1, "get_objects_count() distinct column 2 - $db_type");

  # Clear sub-object
  $objs->[0]->b1(undef);
  $objs->[0]->save;
  $b1->delete;

  my $iterator = 
    MyMySQLObjectManager->get_objectz_iterator(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 1,
        flag2      => 0,
        status     => 'active',
        bits       => '00001',
        start      => '2001-01-02',
        save_col   => [ 1, 5 ],
        last_modified => { le => 'now' },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name');

  is(ref $iterator, 'Rose::DB::Object::Iterator', "get_objects_iterator() 3 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator next() 1 - $db_type");
  is($o->id, 2, "iterator next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator next() 3 - $db_type");
  is($o->id, 3, "iterator next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator next() 5 - $db_type");
  is($iterator->total, 2, "iterator total() - $db_type");

  my $fo = MyMySQLOtherObject->new(name => 'Foo 1',
                                   k1   => 1,
                                   k2   => 2,
                                   k3   => 3);

  ok($fo->save, "object save() 5 - $db_type");

  $fo = MyMySQLOtherObject->new(name => 'Foo 2',
                                k1   => 2,
                                k2   => 3,
                                k3   => 4);

  ok($fo->save, "object save() 6 - $db_type");

  $fo = MyMySQLBB->new(id   => 1,
                       name => 'one');
  ok($fo->save, "bb object save() 1 - $db_type");

  $fo = MyMySQLBB->new(id   => 2,
                       name => 'two');
  ok($fo->save, "bb object save() 2 - $db_type");

  $fo = MyMySQLBB->new(id   => 3,
                       name => 'three');
  ok($fo->save, "bb object save() 3 - $db_type");

  $fo = MyMySQLBB->new(id   => 4,
                       name => 'four');
  ok($fo->save, "bb object save() 4 - $db_type");

  my $o5 = MyMySQLObject->new(id         => 5,
                              name       => 'Betty',  
                              flag       => 'f',
                              flag2      => 't',
                              status     => 'with',
                              bits       => '10101',
                              start      => '2002-05-20',
                              save_col   => 123,
                              nums       => [ 4, 5, 6 ],
                              fkone      => 1,
                              fk2        => 2,
                              fk3        => 3,
                              b1         => 2,
                              b2         => 4,
                              last_modified => '2001-01-10 20:34:56',
                              date_created  => '2002-05-10 10:34:56');

  ok($o5->save, "object save() 7 - $db_type");

  my $fo1 = $o5->other_obj;

  ok($fo1 && ref $fo1 && $fo1->k1 == 1 && $fo1->k2 == 2 && $fo1->k3 == 3,
     "foreign object 1 - $db_type");

  $fo1 = $o5->bb1;
  ok($fo1 && ref $fo1 && $fo1->id == 2, "bb foreign object 1 - $db_type");

  $fo1 = $o5->bb2;
  ok($fo1 && ref $fo1 && $fo1->id == 4, "bb foreign object 2 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  # Conservative version check for hints support
  if($objs->[0]->db->database_version >= 4_000_009)
  {
    my $sql = 
      Rose::DB::Object::Manager->get_objects_sql(
        object_class => 'MyMySQLObject',
        share_db     => 1,
        with_objects => [ 'bb1' ],
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ],
        unique_aliases => 1,
        hints => { t1 => { ignore_index => 'rose_db_object_test_idx' } });

    $objs = 
      MyMySQLObject->get_objectz(
        object_class => 'MyMySQLObject',
        share_db     => 1,
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ],
        hints => { t1 => { ignore_index => 'rose_db_object_test_idx' } });

    ok($sql =~ m{\bIGNORE INDEX \(rose_db_object_test_idx\)}, "hints single table - $db_type");
    ok($sql =~ m{ t1_name,}, "unique_aliases 1 - $db_type");

    $sql = 
      Rose::DB::Object::Manager->get_objects_sql(
        object_class => 'MyMySQLObject',
        share_db     => 1,
        with_objects => [ 'bb1' ],
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ],
        hints => { ignore_index => 'rose_db_object_test_idx' });

    $objs = 
      MyMySQLObject->get_objectz(
        object_class => 'MyMySQLObject',
        share_db     => 1,
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ],
        hints => { ignore_index => 'rose_db_object_test_idx' });

    ok($sql =~ m{\bIGNORE INDEX \(rose_db_object_test_idx\)}, "hints single table 2 - $db_type");
    ok($sql !~ m{ t1_name,}, "unique_aliases 2 - $db_type");

    $sql = 
      Rose::DB::Object::Manager->get_objects_sql(
        object_class => 'MyMySQLObject',
        share_db     => 1,
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ],
        hints => { rose_db_object_test => { ignore_index => 'rose_db_object_test_idx' } });

    $objs = 
      MyMySQLObject->get_objectz(
        object_class => 'MyMySQLObject',
        share_db     => 1,
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ],
        hints => { rose_db_object_test => { ignore_index => 'rose_db_object_test_idx' } });

    ok($sql =~ m{\bIGNORE INDEX \(rose_db_object_test_idx\)}, "hints single table 3 - $db_type");
  }
  else
  {
    SKIP: {  skip("hints single table - $db_type", 3) }
  }

  # Conservative version check for select-for-update support
  if($objs->[0]->db->database_version >= 5_000_000)
  {
    my $db = Rose::DB->new;

    $db->begin_work;

    my $sql = 
      Rose::DB::Object::Manager->get_objects_sql(
        object_class => 'MyMySQLObject',
        db           => $db,
        share_db     => 1,
        with_objects => [ 'bb1' ],
        for_update   => 1,
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ]);

    $objs = 
      MyMySQLObject->get_objectz(
        object_class => 'MyMySQLObject',
        db           => $db,
        share_db     => 1,
        for_update   => 1,
        #debug       => 1,
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ]);

    ok($sql =~ m{\bFOR UPDATE\b}, "select for update - $db_type");

    $db->begin_work;

    $sql = 
      Rose::DB::Object::Manager->get_objects_sql(
        object_class => 'MyMySQLObject',
        db           => $db,
        share_db     => 1,
        with_objects => [ 'bb1' ],
        lock         => { type => 'shared' },
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ]);

    $objs = 
      MyMySQLObject->get_objectz(
        object_class => 'MyMySQLObject',
        db           => $db,
        share_db     => 1,
        lock         => { type => 'shared' },
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ]);

    ok($sql =~ m{\bLOCK IN SHARE MODE\b}, "select lock shared - $db_type");

    $db->commit;
  }
  else
  {
    SKIP: {  skip("select for update - $db_type", 2) }
  }

  $objs = 
    MyMySQLObject->get_objectz(
      object_class => 'MyMySQLObject',
      share_db     => 1,
      query        =>
      [
        't1.id'    => { ge => 2 },
        't1.name'  => { like => '%tt%' },
      ],
      require_objects => [ 'other_obj', 'bb1', 'bb2' ],
      hints   => { t2 => { ignore_index => 'rose_db_object_other_idx', 
                           use_index =>  'rose_db_object_other_idx2' } });

  ok(ref $objs->[0]->{'other_obj'} eq 'MyMySQLOtherObject', "foreign object 2 - $db_type");
  is($objs->[0]->other_obj->k2, 2, "foreign object 3 - $db_type");

  is($objs->[0]->bb1->name, 'two', "bb foreign object 3 - $db_type");
  is($objs->[0]->bb2->name, 'four', "bb foreign object 4 - $db_type");

  # Start "one to many" tests

  ok($fo = MyMySQLNick->new(id   => 1,
                            o_id => 5,
                            nick => 'none',
                            type => { name => 'nt one', t2 => { name => 'nt2 one' } },
                            alts => [ { alt => 'alt one 1' },
                                      { alt => 'alt one 2' },
                                      { alt => 'alt one 3' }, ],
                            opts => [ { opt => 'opt one 1' },
                                      { opt => 'opt one 2' } ])->save,
     "nick object save() 1 - $db_type");

  $fo = MyMySQLNick->new(id   => 2,
                         o_id => 2,
                         nick => 'ntwo',
                         type => { name => 'nt two', t2 => { name => 'nt2 two' } },
                         alts => [ { alt => 'alt two 1' } ]);
  ok($fo->save, "nick object save() 2 - $db_type");

  $fo = MyMySQLNick->new(id   => 3,
                         o_id => 5,
                         nick => 'nthree',
                         type => { name => 'nt three', t2 => { name => 'nt2 three' } },
                         opts => [ { opt => 'opt three 1' },  { opt => 'opt three 2' } ]);
  ok($fo->save, "nick object save() 3 - $db_type");

  $fo = MyMySQLNick->new(id   => 4,
                         o_id => 2,
                         nick => 'nfour',
                         type => { name => 'nt four', t2 => { name => 'nt2 four' } });
  ok($fo->save, "nick object save() 4 - $db_type");

  $fo = MyMySQLNick->new(id   => 5,
                         o_id => 5,
                         nick => 'nfive',
                         type => { name => 'nt five', t2 => { name => 'nt2 five' } });
  ok($fo->save, "nick object save() 5 - $db_type");

  $fo = MyMySQLNick->new(id   => 6,
                         o_id => 5,
                         nick => 'nsix',
                         type => { name => 'nt six', t2 => { name => 'nt2 six' } });
  ok($fo->save, "nick object save() 6 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      share_db     => 1,
      with_objects => [ 'nicks' ],
      query        =>
      [
        't1.id'    => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't2.nick'  => { like => 'n%' },
        start      => '5/20/2002',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        or         => [],
        and        => [],
        save_col   => [ 1, 5, 123 ],
        nums       => [ 4, 5, 6 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      hints   => { nicks => { force_index => 'rose_db_object_nicks_idx' },
                   t1 => { ignore_index => 'rose_db_object_test_idx' } },
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() with many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 2 - $db_type");

  ok(!defined $objs->[0]->{'status'}, "lazy main 1 - $db_type");
  is($objs->[0]->status, 'with', "lazy main 2 - $db_type");

  my $object = MyMySQLObject->new(id => $objs->[0]->id);
  $object->load(with => [ 'nicks.type' ]);
  is($object->{'status'}, undef, "lazy load(with) 1 - $db_type");

  my $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 5 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 7 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks', 'bb1' ],
      query        =>
      [
        't1.id'    => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't3.nick'  => { like => 'n%' },
        start      => '5/20/2002',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        save_col   => [ 1, 5, 123 ],
        nums       => [ 4, 5, 6 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      hints   => { ignore_index => 'rose_db_object_test_idx' },
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() with many 8 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 9 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 10 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 11 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 12 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 13 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 14 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many bb1 1 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many bb2 2 - $db_type");

  $iterator = 
    MyMySQLObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => [ 'nicks' ],
      sort_by => 't1.name');

  is(ref $iterator, 'Rose::DB::Object::Iterator', "get_objects_iterator() 1 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator many next() 1 - $db_type");
  is($o->id, 5, "iterator many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator many next() 3 - $db_type");
  is($o->id, 4, "iterator many next() 4 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator many next() 5 - $db_type");
  is($o->id, 2, "iterator many next() 6 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "iterator many sub-object 1 - $db_type");
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "iterator many sub-object 2 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "iterator many sub-object 3 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator many next() 7 - $db_type");
  is($o->id, 3, "iterator many next() 8 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator many next() 9 - $db_type");
  is($iterator->total, 4, "iterator many total() - $db_type");

  $iterator = 
    MyMySQLObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      sort_by => 't1.name',
      limit   => 2);

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator limit 2 many next() 1 - $db_type");
  is($o->id, 5, "iterator limit 2 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 2 many next() 3 - $db_type");
  is($o->id, 4, "iterator limit 2 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 2 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 2 many total() - $db_type");

  $iterator = 
    MyMySQLObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3);

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator limit 3 many next() 1 - $db_type");
  is($o->id, 5, "iterator limit 3 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 3 many next() 3 - $db_type");
  is($o->id, 4, "iterator limit 3 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 3 many next() 5 - $db_type");
  is($o->id, 2, "iterator limit 3 many next() 6 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "iterator limit 3 many sub-object 1 - $db_type");
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "iterator limit 3 many sub-object 2 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "iterator limit 3 many sub-object 3 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 3 many next() 7 - $db_type");
  is($iterator->total, 3, "iterator limit 3 many total() - $db_type");

  $objs = 
    MyMySQLObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      sort_by => 't1.name',
      limit   => 2);

  ok(ref $objs && @$objs == 2, "get_objects() limit 2 many 1 - $db_type");
  is($objs->[0]->name, 'Betty', "get_objects() limit 2 many 2 - $db_type");
  is($objs->[0]->id, 5, "get_objects() limit 2 many 3 - $db_type");

  is($objs->[1]->name, 'Bob', "get_objects() limit 2 many 4 - $db_type");
  is($objs->[1]->id, 4, "get_objects() limit 2 many 5 - $db_type");

  $objs = 
    MyMySQLObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'nicks', 'bb2' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3);

  ok(ref $objs && @$objs == 3, "get_objects() limit 3 many 1 - $db_type");
  is($objs->[0]->name, 'Betty', "get_objects() limit 3 many 2 - $db_type");
  is($objs->[0]->id, 5, "get_objects() limit 3 many 3 - $db_type");

  is($objs->[1]->name, 'Bob', "get_objects() limit 3 many 4 - $db_type");
  is($objs->[1]->id, 4, "get_objects() limit 3 many 5 - $db_type");

  is($objs->[2]->name, 'Fred', "get_objects() limit 3 many 6 - $db_type");
  is($objs->[2]->id, 2, "get_objects() limit 3 many 7 - $db_type");
  is(scalar @{$objs->[2]->{'nicks'}}, 2, 'get_objects() limit 3 many sub-object 1');
  is($objs->[2]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 3 many sub-object 2');
  is($objs->[2]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 3 many sub-object 3');

  $iterator = 
    MyMySQLObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 2,
      offset  => 1);

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 2 offset 1 many next() 1 - $db_type");
  is($o->id, 4, "iterator limit 2 offset 1 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 2 offset 1 many next() 3 - $db_type");
  is($o->id, 2, "iterator limit 2 offset 1 many next() 4 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, 'iterator limit 2 offset 1 many sub-object 1');
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', 'iterator limit 2 offset 1 many sub-object 2');
  is($o->{'nicks'}[1]{'nick'}, 'nfour', 'iterator limit 2 offset 1 many sub-object 3');

  $o = $iterator->next;
  is($o, 0, "iterator limit 2 offset 1 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 2 offset 1 many total() - $db_type");

  $iterator = 
    MyMySQLObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3,
      offset  => 2);

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 3 offset 2 many next() 1 - $db_type");
  is($o->id, 2, "iterator limit 3 offset 2 many next() 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, 'iterator limit 3 offset 2 many sub-object 1');
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', 'iterator limit 3 offset 2 many sub-object 2');
  is($o->{'nicks'}[1]{'nick'}, 'nfour', 'iterator limit 3 offset 2 many sub-object 3');

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator limit 3 offset 2 many next() 3 - $db_type");
  is($o->id, 3, "iterator limit 3 offset 2 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 3 offset 2 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 3 offset 2 many total() - $db_type");

  $objs = 
    MyMySQLObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 2,
      offset  => 1);

  ok(ref $objs && @$objs == 2, "get_objects() limit 2 offset 1 many 1 - $db_type");
  is($objs->[0]->name, 'Bob', "get_objects() limit 2 offset 1 many 2 - $db_type");
  is($objs->[0]->id, 4, "get_objects() limit 2 offset 1 many 3 - $db_type");

  is($objs->[1]->name, 'Fred', "get_objects() limit 2 offset 1 many 4 - $db_type");
  is($objs->[1]->id, 2, "get_objects() limit 2 offset 1 many 5 - $db_type");
  is(scalar @{$objs->[1]->{'nicks'}}, 2, 'get_objects() limit 2 offset 1 many sub-object 1');
  is($objs->[1]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 2 offset 1 many sub-object 2');
  is($objs->[1]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 2 offset 1 many sub-object 3');

  $objs = 
    MyMySQLObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'nicks', 'bb2' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3,
      offset  => 2);

  ok(ref $objs && @$objs == 2, "get_objects() limit 3 offset 2 many 1 - $db_type");

  is($objs->[0]->name, 'Fred', "get_objects() limit 3 offset 2 many 2 - $db_type");
  is($objs->[0]->id, 2, "get_objects() limit 3 offset 2 many 3 - $db_type");
  is(scalar @{$objs->[0]->{'nicks'}}, 2, 'get_objects() limit 3 offset 2 many sub-object 1');
  is($objs->[0]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 3 offset 2 many sub-object 2');
  is($objs->[0]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 3 offset 2 many sub-object 3');

  is($objs->[1]->name, 'Sue', "get_objects() limit 3 offset 2 many 4 - $db_type");
  is($objs->[1]->id, 3, "get_objects() limit 3 offset 2 many 5 - $db_type");

  my $o6 = $o2->clone;
  $o6->id(60);
  $o6->fkone(undef);
  $o6->fk2(undef);
  $o6->fk3(undef);
  $o6->b1(undef);
  $o6->b2(2);
  $o6->name('Ted');

  ok($o6->save, "object save() 8 - $db_type");

  my $o7 = $o2->clone;
  $o7->id(70);
  $o7->b1(3);
  $o7->b2(undef);
  $o7->name('Joe');

  ok($o7->save, "object save() 9 - $db_type");

  my $o8 = $o2->clone;
  $o8->id(80);
  $o8->b1(undef);
  $o8->b2(undef);
  $o8->name('Pete');

  ok($o8->save, "object save() 10 - $db_type");

  ok($fo->save, "object save() 10 - $db_type");

  $fo = MyMySQLNick->new(id   => 7,
                         o_id => 60,
                         nick => 'nseven');

  ok($fo->save, "nick object save() 7 - $db_type");

  $fo = MyMySQLNick->new(id   => 8,
                         o_id => 60,
                         nick => 'neight');

  ok($fo->save, "nick object save() 8 - $db_type");

  $fo = MyMySQLNick->new(id   => 9,
                         o_id => 60,
                         nick => 'neight');

  ok($fo->save, "nick object save() 8 - $db_type");

  $fo = MyMySQLNick2->new(id    => 1,
                          o_id  => 5,
                          nick2 => 'n2one');

  ok($fo->save, "nick2 object save() 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      query        => [ '!t1.id' => 5 ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 15 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 0, "get_objects() with many 16 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      object_class => 'MyMySQLObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is($count, 1, "get_objects_count() require 1 - $db_type"); 

  #local $Rose::DB::Object::Manager::Debug = 1;  
  #$DB::single = 1;

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      object_class => 'MyMySQLObject',
      share_db     => 1,
      require_objects => [ 'bb2' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is($count, 2, "get_objects_count() require 2 - $db_type"); 

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 17 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 18 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many 19 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 20 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 21 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 22 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 23 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 24 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      share_db     => 1,
      require_objects => [ 'bb1', 'bb2' ],
      with_objects    => [ 'nicks2', 'nicks' ],
      multi_many_ok   => 1,
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with multi many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with multi many 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with multi many 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with multi many 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with multi many 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with multi many 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with multi many 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with multi many 8 - $db_type");

  is($objs->[0]->{'nicks2'}[0]{'nick2'}, 'n2one', "get_objects() with multi many 9 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyMySQLObject',
      share_db     => 1,
      require_objects => [ 'bb1', 'bb2' ],
      with_objects    => [ 'nicks2', 'nicks' ],
      multi_many_ok   => 1,
      query        => [ ],
      sort_by => 't1.id');

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator with and require 1 - $db_type");
  is($o->id, 5, "iterator with and require 2 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "iterator with and require 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "iterator with and require 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "iterator with and require 5 - $db_type");
  is($nicks->[2]->nick, 'none', "iterator with and require 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "iterator with and require 7 - $db_type");

  is($o->{'nicks2'}[0]{'nick2'}, 'n2one', "iterator with and require 8 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator with and require 9 - $db_type");
  is($iterator->total, 1, "iterator with and require 10 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks', 'bb1' ],
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 25 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 8, "get_objects() with many 26 - $db_type");

  my $ids = join(',', map { $_->id } @$objs);

  is($ids, '1,2,3,4,5,60,70,80', "get_objects() with many 27 - $db_type");

  $nicks = $objs->[4]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 28 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 29 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 30 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 31 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 32 - $db_type");

  is($objs->[6]->{'bb1'}->{'name'}, 'three', "get_objects() with many 33 - $db_type");
  ok(!defined $objs->[6]->{'bb2'}, "get_objects() with many 34 - $db_type");
  ok(!defined $objs->[6]->{'nicks'}, "get_objects() with many 35 - $db_type");

  ok(!defined $objs->[7]->{'bb1'}, "get_objects() with many 36 - $db_type");
  ok(!defined $objs->[7]->{'bb1'}, "get_objects() with many 37 - $db_type");
  ok(!defined $objs->[7]->{'nicks'}, "get_objects() with many 38 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 0;

  $fo = MyMySQLNick->new(id => 7);
  ok($fo->delete, "with many clean-up 1 - $db_type");

  $fo = MyMySQLNick->new(id => 8);
  ok($fo->delete, "with many clean-up 2 - $db_type");

  $fo = MyMySQLNick->new(id => 9);
  ok($fo->delete, "with many clean-up 3 - $db_type");

  ok($o6->delete, "with many clean-up 4 - $db_type");
  ok($o7->delete, "with many clean-up 5 - $db_type");
  ok($o8->delete, "with many clean-up 6 - $db_type");

  $fo = MyMySQLNick2->new(id => 1);
  ok($fo->delete, "with many clean-up 7 - $db_type");

  # End "one to many" tests

  $iterator =
    MyMySQLObjectManager->get_objectz_iterator(
      share_db     => 1,
      query        =>
      [
        't1.id'    => { ge => 2 },
        't1.name'  => { like => '%tt%' },
      ],
      require_objects => [ 'other_obj', 'bb1', 'bb2' ]);

  $o = $iterator->next;

  ok(ref $o->{'other_obj'} eq 'MyMySQLOtherObject', "foreign object 4 - $db_type");
  is($o->other_obj->k2, 2, "foreign object 5 - $db_type");

  is($o->bb1->name, 'two', "bb foreign object 5 - $db_type");
  is($o->bb2->name, 'four', "bb foreign object 6 - $db_type");

  $objs = 
    MyMySQLObjectManager->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 1 },
        name       => 'John',  
        flag       => 1,
        flag2      => 0,
        status     => 'active',
        bits       => '1',
        start      => '1/2/2001',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 1,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 2,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 3,
                              day   => 3)
        },

        save_col   => [ 1, 5 ],
        nums       => [ 1, 2, 3 ],
        fk1        => 2,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '3/30/2004 12:34:56 pm'
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() 7 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 8 - $db_type");

  $objs = 
    MyMySQLObject->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        k1         => { lt => 900 },
        or         => [ k1 => { ne => 99 }, k1 => 100 ],
        or         => [ and => [ id => { ne => 123 }, id => { lt => 100  } ],
                        and => [ id => { ne => 456 }, id => { lt => 300  } ] ],
        '!k2'      => { gt => 999 },
        '!t2.name' => 'z',
        start      => { lt => DateTime->new(year => '2005', month => 1, day => 1) },
        '!start'   => { gt => DateTime->new(year => '2005', month => 1, day => 1) },
        'rose_db_object_test.name'   => { like => '%tt%' },
        '!rose_db_object_other.name' => 'q',
        '!rose_db_object_other.name' => [ 'x', 'y' ],
      ],
      require_objects => [ 'other_obj' ]);

  ok(ref $objs->[0]->{'other_obj'} eq 'MyMySQLOtherObject', "foreign object 6 - $db_type");
  is($objs->[0]->other_obj->k2, 2, "foreign object 7 - $db_type");

  # Test limit with offset

  foreach my $id (6 .. 20)
  {
    my $o = $o5->clone;
    $o->id($id);
    $o->name("Clone $id");

    ok($o->save, "object save() clone $id - $db_type");
  }

  $objs = 
    MyMySQLObjectManager->get_objectz(
      sort_by      => 'id DESC',
      limit        => 2,
      offset       => 8);

  ok(ref $objs eq 'ARRAY' && @$objs == 2 && 
     $objs->[0]->id == 12 && $objs->[1]->id == 11,
     "get_objects() with offset - $db_type");

  $objs = 
    MyMySQLObject->get_objectz(
      sort_by      => 'id DESC',
      require_objects => [ 'other_obj' ],
      limit        => 2,
      offset       => 8);

  ok(ref $objs eq 'ARRAY' && @$objs == 2 && 
     $objs->[0]->id == 12 && $objs->[1]->id == 11,
     "get_objects() with objects and offset - $db_type");

  $iterator = 
    MyMySQLObject->get_objectz_iterator(
      sort_by      => 'id DESC',
      limit        => 2,
      offset       => 8);

  $o = $iterator->next;
  is($o->id, 12, "get_objects_iterator() with offset 1 - $db_type");

  $o = $iterator->next;
  is($o->id, 11, "get_objects_iterator() with offset 2 - $db_type");

  is($iterator->next, 0, "get_objects_iterator() with offset 3 - $db_type");

  eval
  {
    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class => 'MyMySQLObject',
        sort_by      => 'id DESC',
        offset       => 8)
  };

  ok($@ =~ /invalid without a limit/, "get_objects() missing offset - $db_type");

  eval
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class => 'MyMySQLObject',
        sort_by      => 'id DESC',
        offset       => 8);
  };

  ok($@ =~ /invalid without a limit/, "get_objects_iterator() missing offset - $db_type");

  # Start *_sql comparison tests

  $o6->fk2(99);
  $o6->fk3(99);
  $o6->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ 'fk2' => { eq_sql => 'fk3' } ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq_sql 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq_sql 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq_sql 3 - $db_type");

  # End *_sql comparison tests

  # Start IN NULL tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => [ undef, 60 ], '!id' => \'id + 1' ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() in null 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() in null 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() in null 3 - $db_type");

  # End IN NULL tests

  # Start scalar ref tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ 'fk2' => \'fk3' ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq ref 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq ref 3 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ 'fk2' => [ \'fk3' ] ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 4 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq ref 5 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq ref 6 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ 'fk2' => { ne => \'fk3' } ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 7 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 16, "get_objects() eq ref 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ 'fk2' => { ne => [ \'fk3' ] } ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 9 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 16, "get_objects() eq ref 10 - $db_type");

  # End scalar ref tests

  # Start "many to many" tests

  $fo = MyMySQLColor->new(id => 1, name => 'Red');
  $fo->save;

  $fo = MyMySQLColor->new(id => 2, name => 'Green');
  $fo->save;

  $fo = MyMySQLColor->new(id => 3, name => 'Blue');
  $fo->save;

  $fo = MyMySQLColorMap->new(id => 1, object_id => $o2->id, color_id => 1);
  $fo->save;

  $fo = MyMySQLColorMap->new(id => 2, object_id => $o2->id, color_id => 3);
  $fo->save;

  $o2->b1(4);
  $o2->b1(2);
  $o2->fkone(2);
  $o2->fk2(3);
  $o2->fk3(4);
  $o2->save;

  my @colors = $o2->colors;
  ok(@colors == 2 && $colors[0]->name eq 'Red' &&
     $colors[1]->name eq 'Blue', "Fetch many to many 1 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyMySQLObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 1,
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many 4 - $db_type");
  is($objs->[2]->id, 1, "get_objects() with many to many 5 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many 12 - $db_type");

  my $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many 15 - $db_type");

  is($colors->[0]->map_record->color_id, $colors->[0]->id, "map_record 1 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 2 - $db_type");
  is($colors->[1]->map_record->color_id, $colors->[1]->id, "map_record 3 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 4 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyMySQLObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_record',
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $objs = [];

  while(my $obj = $iterator->next)
  {
    push(@$objs, $obj);
  }

  is(ref $objs, 'ARRAY', "get_objects_iterator() with many to many map record 1 - $db_type");
  is(scalar @$objs, 3, "get_objects_iterator() with many to many map record  2 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  is($colors->[0]->map_record->color_id, $colors->[0]->id, "map_record 5 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 6 - $db_type");
  is($colors->[1]->map_record->color_id, $colors->[1]->id, "map_record 7 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyMySQLObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_rec',
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many 2 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  is($colors->[0]->map_rec->color_id, $colors->[0]->id, "map_rec 1 - $db_type");
  is($colors->[0]->map_rec->object_id, $objs->[1]->id, "map_rec 2 - $db_type");
  is($colors->[1]->map_rec->color_id, $colors->[1]->id, "map_rec 3 - $db_type");
  is($colors->[0]->map_rec->object_id, $objs->[1]->id, "map_rec 4 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyMySQLObject',
      share_db      => 1,
      with_objects  => [ 'bb1', 'nicks', 'other_obj', 'colors', 'bb2' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many (reorder) 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many (reorder) 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many (reorder) 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many (reorder) 4 - $db_type");
  is($objs->[2]->id, 1, "get_objects() with many to many (reorder) 5 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many (reorder) 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many (reorder) 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many (reorder) 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many (reorder) 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many (reorder) 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many (reorder) 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many (reorder) 12 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many (reorder) 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many (reorder) 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many (reorder) 15 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyMySQLObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many require with 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 2, "get_objects() with many to many require with 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many require with 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many require with 4 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many require with 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many require with 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many require with 12 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many require with 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many require with 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many require with 15 - $db_type");

  $fo1 = $objs->[1]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'two', "get_objects() with many to many require with 16 - $db_type");

  $fo1 = $objs->[0]->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 1', "get_objects() with many to many require with 17 - $db_type");

  $fo1 = $objs->[1]->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 2', "get_objects() with many to many require with 18 - $db_type");

  ok(!defined $objs->[0]->{'colors'}, "get_objects() with many to many require with 19 - $db_type");
  ok(!defined $objs->[1]->{'bb2'}, "get_objects() with many to many require with 20 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyMySQLObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many 1 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many 2 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many 5 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many 7 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many 8 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many 9 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many 10 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many 11 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many 12 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 13 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 14 - $db_type");

  $o = $iterator->next;
  is($o->name, 'John', "get_objects_iterator() with many to many 15 - $db_type");
  is($o->id, 1, "get_objects_iterator() with many to many 16 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many 17 - $db_type");
  is($iterator->total, 3, "get_objects_iterator() with many to many 18 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyMySQLObject',
      share_db      => 1,
      with_objects  => [ 'bb1', 'nicks', 'other_obj', 'colors', 'bb2' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many 19 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many 20 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many 21 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many 22 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many 23 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many 24 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many 25 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many 26 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many 27 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many 28 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many 29 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many 30 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 31 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 32 - $db_type");

  $o = $iterator->next;
  is($o->name, 'John', "get_objects_iterator() with many to many 33 - $db_type");
  is($o->id, 1, "get_objects_iterator() with many to many 34 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many 35 - $db_type");
  is($iterator->total, 3, "get_objects_iterator() with many to many 36 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyMySQLObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many require 1 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many require 2 - $db_type");

  $fo1 = $o->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 1', "get_objects_iterator() with many to many require 3 - $db_type");

  ok(!defined $o->{'colors'}, "get_objects_iterator() with many to many require 4 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many require 5 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many require 6 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many require 7 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many require 8 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many require 9 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many require 10 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many require 11 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many require 12 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many require 13 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many require 16 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'two', "get_objects_iterator() with many to many require 17 - $db_type");

  $fo1 = $o->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 2', "get_objects_iterator() with many to many require 18 - $db_type");

  ok(!defined $o->{'bb2'}, "get_objects_iterator() with many to many require 19 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many require 20 - $db_type");
  is($iterator->total, 2, "get_objects_iterator() with many to many require 21 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyMySQLObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name',
      limit           => 1,
      offset          => 5);

  ok(!$iterator->next, "get_objects_iterator() with many to many require 22 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyMySQLObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name',
      limit           => 1,
      offset          => 5);

  ok(@$objs == 0, "get_objects_iterator() with many to many require 23 - $db_type");

  # End "many to many" tests

  # Start multi-require tests

  $fo = MyMySQLColorMap->new(id => 3, object_id => 5, color_id => 2);
  $fo->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyMySQLObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'colors', 'other_obj' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 2, "get_objects() multi many require 1 - $db_type");

  is($objs->[0]->id, 5, "get_objects() multi many require 2 - $db_type");
  is($objs->[1]->id, 2, "get_objects() multi many require 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() multi many require 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() multi many require 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() multi many require 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() multi many require 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() multi many require 8 - $db_type");

  $colors = $objs->[0]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 1, "get_objects() multi many require 9 - $db_type");
  ok($colors->[0]->id == 2 && $colors->[0]->name eq 'Green', "get_objects() multi many require 10 - $db_type");

  $nicks = $objs->[1]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 2, "get_objects() multi many require 11 - $db_type");
  is($nicks->[0]->nick, 'ntwo', "get_objects() multi many require 12 - $db_type");
  is($nicks->[1]->nick, 'nfour', "get_objects() multi many require 13 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() multi many require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() multi many require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[1]->name eq 'Blue', "get_objects() multi many require 16 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyMySQLObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'colors', 'other_obj' ],
      with_objects    => [ 'bb2' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 2, "get_objects() multi many with require 1 - $db_type");

  is($objs->[0]->id, 5, "get_objects() multi many with require 2 - $db_type");
  is($objs->[1]->id, 2, "get_objects() multi many with require 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() multi many with require 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() multi many with require 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() multi many with require 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() multi many with require 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() multi many with require 8 - $db_type");

  $colors = $objs->[0]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 1, "get_objects() multi many with require 9 - $db_type");
  ok($colors->[0]->id == 2 && $colors->[0]->name eq 'Green', "get_objects() multi many with require 10 - $db_type");

  $nicks = $objs->[1]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 2, "get_objects() multi many with require 11 - $db_type");
  is($nicks->[0]->nick, 'ntwo', "get_objects() multi many with require 12 - $db_type");
  is($nicks->[1]->nick, 'nfour', "get_objects() multi many with require 13 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() multi many with require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() multi many with require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[1]->name eq 'Blue', "get_objects() multi many with require 16 - $db_type");

  is($objs->[0]->{'bb2'}{'name'}, 'four', "get_objects() multi many with require 17 - $db_type");
  ok(!defined $objs->[1]->{'bb2'}{'name'}, "get_objects() multi many with require 18 - $db_type");

  MyMySQLNick->new(id => 7, o_id => 10,  nick => 'nseven')->save;
  MyMySQLNick->new(id => 8, o_id => 11,  nick => 'neight')->save;
  MyMySQLNick->new(id => 9, o_id => 12,  nick => 'nnine')->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyMySQLObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'bb1' ],
      with_objects    => [ 'colors' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 5, "get_objects() multi many with require map 1 - $db_type");

  is($objs->[0]->id,  5, "get_objects() multi many with require map 2 - $db_type");
  is($objs->[1]->id, 10, "get_objects() multi many with require map 3 - $db_type");
  is($objs->[2]->id, 11, "get_objects() multi many with require map 4 - $db_type");
  is($objs->[3]->id, 12, "get_objects() multi many with require map 5 - $db_type");
  is($objs->[4]->id,  2, "get_objects() multi many with require map 6 - $db_type");

  # End multi-require tests

  # Start distinct tests

  my $i = 0;

  foreach my $distinct (1, [ 't1' ], [ 'rose_db_object_test' ])
  {
    $i++;

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyMySQLObject',
        distinct        => $distinct,
        share_db        => 1,
        require_objects => [ 'nicks', 'colors', 'other_obj' ],
        multi_many_ok   => 1,
        sort_by         => 't1.name');

    is(scalar @$objs, 2, "get_objects() distinct multi many require $i.1 - $db_type");

    is($objs->[0]->id, 5, "get_objects() distinct multi many require $i.2 - $db_type");
    is($objs->[1]->id, 2, "get_objects() distinct multi many require $i.3 - $db_type");

    ok(!defined $objs->[0]->{'nicks'}, "get_objects() distinct multi many require $i.4 - $db_type");
    ok(!defined $objs->[0]->{'colors'}, "get_objects() distinct multi many require $i.5 - $db_type");

    ok(!defined $objs->[1]->{'nicks'}, "get_objects() distinct multi many require $i.6 - $db_type");
    ok(!defined $objs->[1]->{'colors'}, "get_objects() distinct multi many require $i.7 - $db_type");
  }

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  foreach my $distinct ([ 't2' ], [ 'rose_db_object_nicks' ], [ 'nicks' ])
  {
    $i++;

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyMySQLObject',
        distinct        => $distinct,
        share_db        => 1,
        require_objects => [ 'nicks', 'colors', 'other_obj' ],
        multi_many_ok   => 1,
        sort_by         => 't1.name');

    is(scalar @$objs, 2, "get_objects() distinct multi many require $i.1 - $db_type");

    is($objs->[0]->id, 5, "get_objects() distinct multi many require $i.2 - $db_type");
    is($objs->[1]->id, 2, "get_objects() distinct multi many require $i.3 - $db_type");

    ok(defined $objs->[0]->{'nicks'}, "get_objects() distinct multi many require $i.4 - $db_type");
    ok(!defined $objs->[0]->{'colors'}, "get_objects() distinct multi many require $i.5 - $db_type");

    ok(defined $objs->[1]->{'nicks'}, "get_objects() distinct multi many require $i.6 - $db_type");
    ok(!defined $objs->[1]->{'colors'}, "get_objects() distinct multi many require $i.7 - $db_type");
  }

  # End distinct tests

  # Start pager tests

  is(Rose::DB::Object::Manager->default_objects_per_page, 20, 'default_objects_per_page 1');

  Rose::DB::Object::Manager->default_objects_per_page(3);

  my $per_page = Rose::DB::Object::Manager->default_objects_per_page;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 1,
      per_page     => 3);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 1.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 2.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => 3);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 3.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => -1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 4.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => -1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 5.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => undef);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 6.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => undef);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 7.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id');

  ok(scalar @$objs > 3, "pager 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 2,
      per_page     => 3);

  $i = 0;

  for(4 .. 6)
  {
    is($objs->[$i++]->id, $_, "pager 9.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 3,
      per_page     => 3);

  $i = 0;

  for(7 .. 9)
  {
    is($objs->[$i++]->id, $_, "pager 10.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 4,
      per_page     => 3);

  $i = 0;

  for(10 .. 11)
  {
    is($objs->[$i++]->id, $_, "pager 11.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 5,
      per_page     => 3);

  ok(scalar @$objs == 0, "pager 12 - $db_type");

  Rose::DB::Object::Manager->default_objects_per_page(20);

  # End pager tests

  # Start get_objects_from_sql tests

  $objs = 
    MyMySQLObjectManager->get_objects_from_sql(
      db  => MyMySQLObject->init_db,
      object_class => 'MyMySQLObject',
      prepare_cached => 1,
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  ok(scalar @$objs == 19, "get_objects_from_sql 1 - $db_type");
  is($objs->[18]->id, 1, "get_objects_from_sql 2 - $db_type");
  is($objs->[18]->save_col, 5, "get_objects_from_sql 3 - $db_type");
  is($objs->[18]->name, 'John', "get_objects_from_sql 4 - $db_type");

  $iterator = 
    MyMySQLObjectManager->get_objects_iterator_from_sql(
      db  => MyMySQLObject->init_db,
      object_class => 'MyMySQLObject',
      prepare_cached => 1,
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  for(0 .. 17) { $iterator->next }

  $o = $iterator->next;
  is($o->id, 1, "get_objects_iterator_from_sql 1 - $db_type");
  is($o->save_col, 5, "get_objects_iterator_from_sql 2 - $db_type");
  is($o->name, 'John', "get_objects_iterator_from_sql 3 - $db_type");
  ok(!$iterator->next,  "get_objects_iterator_from_sql 4 - $db_type");

  $objs = MyMySQLObjectManager->get_objects_from_sql(<<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  ok(scalar @$objs == 19, "get_objects_from_sql 5 - $db_type");
  is($objs->[18]->id, 1, "get_objects_from_sql 6 - $db_type");
  is($objs->[18]->save_col, 5, "get_objects_from_sql 7 - $db_type");
  is($objs->[18]->name, 'John', "get_objects_from_sql 8 - $db_type");

  $objs = 
    MyMySQLObjectManager->get_objects_from_sql(
      args => [ 19 ],
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id > ? ORDER BY id DESC
EOF

  ok(scalar @$objs == 2, "get_objects_from_sql 9 - $db_type");
  is($objs->[0]->id, 60, "get_objects_from_sql 10 - $db_type");

  my $method = 
    MyMySQLObjectManager->make_manager_method_from_sql(
      get_em => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  $objs = MyMySQLObjectManager->get_em;

  ok(scalar @$objs == 19, "make_manager_method_from_sql 1 - $db_type");
  is($objs->[17]->id, 3, "make_manager_method_from_sql 2 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql 3 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql 4 - $db_type");  

  $objs = $method->('MyMySQLObjectManager');

  ok(scalar @$objs == 19, "make_manager_method_from_sql 5 - $db_type");
  is($objs->[17]->id, 3, "make_manager_method_from_sql 6 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql 7 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql 8 - $db_type");  

  $method = 
    MyMySQLObjectManager->make_manager_method_from_sql(
      iterator => 1, method => 'iter_em', sql => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  $iterator = MyMySQLObjectManager->iter_em;

  for(0 .. 16) { $iterator->next }

  $o = $iterator->next;
  is($objs->[17]->id, 3, "make_manager_method_from_sql iterator 1 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql iterator 2 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql iterator 3 - $db_type");  

  $iterator = $method->('MyMySQLObjectManager');

  for(0 .. 16) { $iterator->next }

  $o = $iterator->next;
  is($objs->[17]->id, 3, "make_manager_method_from_sql iterator 4 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql iterator 5 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql iterator 6 - $db_type");  

  $method = 
    MyMySQLObjectManager->make_manager_method_from_sql(
      get_more => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id > ? ORDER BY id DESC
EOF

  $objs = MyMySQLObjectManager->get_more(18);
  ok(scalar @$objs == 3, "make_manager_method_from_sql 9 - $db_type");
  is($objs->[2]->id, 19, "make_manager_method_from_sql 10 - $db_type");

  $method = 
    MyMySQLObjectManager->make_manager_method_from_sql(
      method => 'get_more_np',
      params => [ qw(id name) ],
      sql    => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE 
id > ? AND name != ? ORDER BY id DESC
EOF

  $objs = MyMySQLObjectManager->get_more_np(name => 'Nonesuch', id => 18);
  ok(scalar @$objs == 3, "make_manager_method_from_sql 11 - $db_type");
  is($objs->[2]->id, 19, "make_manager_method_from_sql 12 - $db_type");

  # End get_objects_from_sql tests

  # Start tough order tests

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyMySQLObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1);

  ok(@$objs == 5, "tough order 1 - $db_type");
  is($objs->[0]->id, 2, "tough order 2 - $db_type");
  is($objs->[1]->id, 5, "tough order 3 - $db_type");
  is($objs->[2]->id, 10, "tough order 4 - $db_type");
  is($objs->[3]->id, 11, "tough order 5 - $db_type");
  is($objs->[4]->id, 12, "tough order 6 - $db_type");

  is($objs->[0]{'nicks'}[0]{'nick'}, 'ntwo', "tough order 7 - $db_type");
  is($objs->[0]{'nicks'}[1]{'nick'}, 'nfour', "tough order 8 - $db_type");

  is($objs->[1]{'nicks'}[0]{'nick'}, 'nthree', "tough order 9 - $db_type");
  is($objs->[1]{'nicks'}[1]{'nick'}, 'nsix', "tough order 10 - $db_type");
  is($objs->[1]{'nicks'}[2]{'nick'}, 'none', "tough order 11 - $db_type");
  is($objs->[1]{'nicks'}[3]{'nick'}, 'nfive', "tough order 12 - $db_type");

  is($objs->[2]{'nicks'}[0]{'nick'}, 'nseven', "tough order 13 - $db_type");

  is($objs->[3]{'nicks'}[0]{'nick'}, 'neight', "tough order 14 - $db_type");

  is($objs->[4]{'nicks'}[0]{'nick'}, 'nnine', "tough order 15 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyMySQLObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1,
      sort_by         => 'name');

  ok(@$objs == 5, "tough order 16 - $db_type");
  is($objs->[0]->id, 5, "tough order 17 - $db_type");
  is($objs->[1]->id, 10, "tough order 18 - $db_type");
  is($objs->[2]->id, 11, "tough order 19 - $db_type");
  is($objs->[3]->id, 12, "tough order 20 - $db_type");
  is($objs->[4]->id, 2, "tough order 21 - $db_type");

  is($objs->[0]{'nicks'}[0]{'nick'}, 'nthree', "tough order 22 - $db_type");
  is($objs->[0]{'nicks'}[1]{'nick'}, 'nsix', "tough order 23 - $db_type");
  is($objs->[0]{'nicks'}[2]{'nick'}, 'none', "tough order 24 - $db_type");
  is($objs->[0]{'nicks'}[3]{'nick'}, 'nfive', "tough order 25 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 4, "tough order 26 - $db_type");

  is($objs->[1]{'nicks'}[0]{'nick'}, 'nseven', "tough order 27 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 1, "tough order 28 - $db_type");

  is($objs->[2]{'nicks'}[0]{'nick'}, 'neight', "tough order 29 - $db_type");
  is(scalar @{$objs->[2]{'nicks'}}, 1, "tough order 30 - $db_type");

  is($objs->[3]{'nicks'}[0]{'nick'}, 'nnine', "tough order 31 - $db_type");
  is(scalar @{$objs->[3]{'nicks'}}, 1, "tough order 32 - $db_type");

  is($objs->[4]{'nicks'}[0]{'nick'}, 'ntwo', "tough order 33 - $db_type");
  is($objs->[4]{'nicks'}[1]{'nick'}, 'nfour', "tough order 34 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 2, "tough order 35 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyMySQLObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1,
      sort_by         => 'name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nthree', "tough order 36 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nsix', "tough order 37 - $db_type");
  is($o->{'nicks'}[2]{'nick'}, 'none', "tough order 38 - $db_type");
  is($o->{'nicks'}[3]{'nick'}, 'nfive', "tough order 39 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "tough order 40 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nseven', "tough order 41 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 42 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'neight', "tough order 43 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 44 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nnine', "tough order 45 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 46 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "tough order 47 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "tough order 48 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "tough order 49 - $db_type");

  ok(!$iterator->next, "tough order 50 - $db_type");
  is($iterator->total, 5, "tough order 51 - $db_type");

  # End tough order tests

  # Start deep join tests

  eval 
  { 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      require_objects => [ 'nicks.type' ],
      with_objects    => [ 'nicks.type' ]);
  };

  ok($@, "deep join conflict 1 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;
  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      require_objects => [ 'nicks.type', 'nicks.type', 'nicks' ],
      with_objects    => [ 'nicks.type.t2', 'nicks.alts' ],
      multi_many_ok   => 1,
      nonlazy         => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'type.name');

  ok(@$objs == 2, "deep join 1 - $db_type");
  is($objs->[0]->id, 2, "deep join 2 - $db_type");
  is($objs->[1]->id, 5, "deep join 3 - $db_type");

  #SORT:
  #{
  #  $objs->[0]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[0]{'nicks'}} ];
  #}

  is($objs->[0]{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join 4 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join 5 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 2, "deep join 6 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join 7 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join 8 - $db_type");
  is($objs->[1]{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join 9 - $db_type");
  is($objs->[1]{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join 10 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 4, "deep join 11 - $db_type");

  is($objs->[0]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join 12 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join 13 - $db_type");

  is($objs->[0]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join 14 - $db_type");

  $objs->[1]{'nicks'}[1]{'alts'} = 
    [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[1]{'nicks'}[1]{'alts'}} ];
  is($objs->[1]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join 15 - $db_type");
  is($objs->[1]{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join 16 - $db_type");
  is($objs->[1]{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join 17 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[1]{'alts'}}, 3, "deep join 18 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      with_objects => [ 'nicks.type' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 21, "deep join with 1 - $db_type");
  is($objs->[0]->id, 1, "deep join with 2 - $db_type");
  is($objs->[1]->id, 2, "deep join with 3 - $db_type");
  is($objs->[2]->id, 3, "deep join with 4 - $db_type");
  is($objs->[16]->id, 17, "deep join with 5 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join with 6 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join with 7 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 2, "deep join with 8 - $db_type");

  #SORT:
  #{
  #  $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
  #}

  is($objs->[4]{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join with 9 - $db_type");
  is($objs->[4]{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join with 10 - $db_type");
  is($objs->[4]{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join with 11 - $db_type");
  is($objs->[4]{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join with 12 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 4, "deep join with 13 - $db_type");

  is(scalar @{$objs->[0]{'nicks'} ||= []}, 0, "deep join with 14 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyMySQLObject',
      require_objects => [ 'nicks.type', 'nicks.type', 'nicks' ],
      with_objects    => [ 'nicks.type.t2', 'nicks.alts' ],
      multi_many_ok   => 1,
      query           => [ 'id' => [ 2, 5 ] ],
      sort_by         => 'type.name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator 3 - $db_type");

  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join 3.1 - $db_type");

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator 3.1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator 3.2 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator 8 - $db_type");

  $o->{'nicks'}[1]{'alts'} = 
    [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join iterator 9 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join iterator 10 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join iterator 11 - $db_type");
  is(scalar @{$o->{'nicks'}[1]{'alts'}}, 3, "deep join iterator 12 - $db_type");

  ok(!$iterator->next, "deep join iterator 13 - $db_type");
  is($iterator->total, 2, "deep join iterator 14 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyMySQLObject',
      with_objects => [ 'nicks.type' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  $o = $iterator->next;
  is($o->id, 1, "deep join with with iterator 1 - $db_type");

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join with with iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join with iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join with iterator 3 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join with iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join with iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join with iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join with iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join with iterator 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join iterator 9 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      require_objects => [ 'nicks.type.t2' ],
      query        => [ 'id' => [ 2, 5 ] ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 2, "deep join three-level 1 - $db_type");
  is($objs->[0]->id, 2, "deep join three-level 2 - $db_type");
  is($objs->[1]->id, 5, "deep join three-level 3 - $db_type");

  #SORT:
  #{
  #  $objs->[0]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[0]{'nicks'}} ];
  #}

  is($objs->[0]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join three-level 4 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join three-level 5 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 2, "deep join three-level 6 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join three-level 7 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join three-level 8 - $db_type");
  is($objs->[1]{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join three-level 9 - $db_type");
  is($objs->[1]{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join three-level 10 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 4, "deep join three-level 11 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      with_objects => [ 'nicks.type.t2' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 21, "deep join three-level 1 - $db_type");
  is($objs->[0]->id, 1, "deep join three-level 2 - $db_type");
  is($objs->[1]->id, 2, "deep join three-level 3 - $db_type");
  is($objs->[4]->id, 5, "deep join three-level 4 - $db_type");
  is($objs->[20]->id, 60, "deep join three-level 5 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join three-level 6 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join three-level 7 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 2, "deep join three-level 8 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[4]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join three-level 9 - $db_type");
  is($objs->[4]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join three-level 10 - $db_type");
  is($objs->[4]{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join three-level 11 - $db_type");
  is($objs->[4]{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join three-level 12 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 4, "deep join three-level 13 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyMySQLObject',
      require_objects => [ 'nicks.type.t2' ],
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'type.name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator 3 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator 8 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyMySQLObject',
      with_objects => [ 'nicks.type.t2' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  $o = $iterator->next;
  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator with 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator with 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator with 3 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join iterator with 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join iterator with 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join iterator with 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join iterator with 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator with 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join iterator with 9 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyMySQLObject',
      require_objects => [ 'nicks.alts' ],
      multi_many_ok => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'alts.alt');

  ok(@$objs == 2, "deep join multi 1 - $db_type");
  is($objs->[0]->id, 2, "deep join multi 2 - $db_type");
  is($objs->[1]->id, 5, "deep join multi 3 - $db_type");

  is($objs->[0]{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi 4 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}[0]{'alts'}}, 1, "deep join multi 5 - $db_type");

  is($objs->[1]{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi 6 - $db_type");
  is($objs->[1]{'nicks'}[0]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi 7 - $db_type");
  is($objs->[1]{'nicks'}[0]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi 8 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[0]{'alts'}}, 3, "deep join multi 11 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyMySQLObject',
      with_objects  => [ 'nicks.alts' ],
      multi_many_ok => 1,
      nonlazy       => 1,
      sort_by       => 'alts.alt');

  ok(@$objs == 21, "deep join multi with 1 - $db_type");
  is($objs->[1]->id, 2, "deep join multi with 2 - $db_type");
  is($objs->[4]->id, 5, "deep join multi with 3 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #  $objs->[1]{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[1]{'nicks'}[1]{'alts'}} ];
  #}

  is($objs->[1]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi with with 4 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[1]{'alts'}}, 1, "deep join multi with 5 - $db_type");

  #SORT:
  #{
  #  $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
  #  $objs->[4]{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[4]{'nicks'}[3]{'alts'}} ];
  #}

  is($objs->[4]{'nicks'}[3]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi with 6 - $db_type");
  is($objs->[4]{'nicks'}[3]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi with 7 - $db_type");
  is($objs->[4]{'nicks'}[3]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi with 8 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}[3]{'alts'}}, 3, "deep join multi with 11 - $db_type");

  is(scalar @{$objs->[0]{'nicks'} || []}, 0, "deep join multi with 12 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyMySQLObject',
      require_objects => [ 'nicks.alts' ],
      multi_many_ok => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'alts.alt');

  $o = $iterator->next;
  is($o->id, 2, "deep join multi iter 1 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi iter 2 - $db_type");
  is(scalar @{$o->{'nicks'}[0]{'alts'}}, 1, "deep join multi iter 3 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi iter 4 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi iter 5 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi iter 6 - $db_type");
  is(scalar @{$o->{'nicks'}[0]{'alts'}}, 3, "deep join multi iter 7 - $db_type");

  ok(!$iterator->next, "deep join multi iter 8 - $db_type");
  is($iterator->total, 2, "deep join multi iter 9 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyMySQLObject',
      with_objects  => [ 'nicks.alts' ],
      multi_many_ok => 1,
      nonlazy       => 1,
      #query => [ id => 2 ],
      sort_by       => 'alts.alt');

  $o = $iterator->next;
  is(scalar @{$o->{'nicks'} ||= []}, 0, "deep join multi iter with 1 - $db_type");

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #  $o->{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
  #}

  is($o->id, 2, "deep join multi iter with 2 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi iter with 3 - $db_type");
  is(scalar @{$o->{'nicks'}[1]{'alts'}}, 1, "deep join multi iter with 4 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #  $o->{'nicks'}[3]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[3]{'alts'}} ];
  #}

  is($o->{'nicks'}[3]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi iter with 5 - $db_type");
  is($o->{'nicks'}[3]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi iter with 6 - $db_type");
  is($o->{'nicks'}[3]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi iter with 7 - $db_type");
  is(scalar @{$o->{'nicks'}[3]{'alts'}}, 3, "deep join multi iter with 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join multi iter with 9 - $db_type");

  # End deep join tests

  # Start custom select tests

  my @selects =
  (
    't2.nick, id, t2.id, name, UPPER(name) AS derived, fk1',
    't1.id, t2.nick, t2.id, t1.name, UPPER(name) AS derived, t1.fk1',
    'rose_db_object_nicks.id, rose_db_object_test.id, rose_db_object_nicks.nick, rose_db_object_test.name, UPPER(name) AS derived',
    [ \q(t1.id + 0 AS id), qw(name t2.nick nicks.id), \q(UPPER(name) AS derived) ],
    [ qw(t2.nick t2.id t1.id t1.name), 'UPPER(name) AS derived' ],
    [ \q(UPPER(name) AS derived), qw(t2.id rose_db_object_nicks.nick rose_db_object_test.id rose_db_object_test.name) ],
    [ qw(rose_db_object_test.id rose_db_object_nicks.nick rose_db_object_test.name rose_db_object_nicks.id), 'UPPER(name) AS derived' ],
    [ qw(rose_db_object_test.id rose_db_object_test.name rose_db_object_nicks.nick t2.id), 'UPPER(name) AS derived' ],
  );

  $i = 0;

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MyMySQLObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && !defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && !defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyMySQLObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && defined $objs->[0]->nicks->[0]->nick &&
       !defined $objs->[0]->nicks->[0]->type_id && !defined $objs->[0]->flag2 &&
       $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && defined $objs->[1]->nicks->[0]->nick &&
       !defined $objs->[1]->nicks->[0]->type_id && !defined $objs->[1]->flag2 &&
       $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  @selects =
  (
    't2.nick, t1.*, t2.id, name, UPPER(name) AS derived',
    [ qw(t2.nick t2.id t1.*), 'UPPER(name) AS derived' ],
  );

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MyMySQLObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyMySQLObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && defined $objs->[0]->nicks->[0]->nick &&
       !defined $objs->[0]->nicks->[0]->type_id && defined $objs->[0]->flag2 &&
       $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && defined $objs->[1]->nicks->[0]->nick &&
       !defined $objs->[1]->nicks->[0]->type_id && defined $objs->[1]->flag2 &&
       $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  @selects =
  (
    '*, name, UPPER(name) AS derived',
    [ '*', 'UPPER(name) AS derived' ],
  );

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MyMySQLObject',
        select          => $select,
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->flag2 && 
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyMySQLObject',
        select          => $select,
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && 
       defined $objs->[0]->flag2 && $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && 
       defined $objs->[1]->flag2 && $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }


  # End custom select tests
}

#
# Informix
#

SKIP: foreach my $db_type (qw(informix))
{
  skip("Informix tests", 752)  unless($HAVE_INFORMIX);

  Rose::DB->default_type($db_type);

  my($sql, $bind) = 
    Rose::DB::Object::Manager->get_objects_sql(
      object_class => 'MyInformixObject',
      query => [ name => { like => \q('%foo%') } ]);

  ok($sql =~ /name LIKE '%foo%'/, "scalar ref bind 1 - $db_type");
  is(@$bind, 0, "scalar ref bind 2 - $db_type");

  ($sql, $bind) = 
    Rose::DB::Object::Manager->get_objects_sql(
      object_class => 'MyInformixObject',
      require_objects => [ 'bb1' ],
      query => [ 'bb1.name' => { like => \q('%foo%') } ]);

  ok($sql =~ /name LIKE '%foo%'/, "scalar ref bind 3 - $db_type");
  is(@$bind, 0, "scalar ref bind 4 - $db_type");

  ($sql, $bind) = 
    Rose::DB::Object::Manager->get_objects_sql(
      object_class => 'MyInformixObject',
      require_objects => [ 'bb1' ],
      query => 
      [
        or =>
        [
          name => 'bar',
          'bb1.name' => { like => \q('%foo%') },
        ],
      ]);

  ok($sql =~ /t2\.name LIKE '%foo%'/, "scalar ref bind 5 - $db_type");
  is(@$bind, 1, "scalar ref bind 6 - $db_type");

  my $o = MyInformixObject->new(id         => 1,
                                name       => 'John',  
                                flag       => 't',
                                flag2      => 'f',
                                fkone      => 2,
                                status     => 'active',
                                bits       => '00001',
                                start      => '2001-01-02',
                                save_col   => 5,     
                                nums       => [ 1, 2, 3 ],
                                last_modified => 'now',
                                date_created  => '2004-03-30 12:34:56');

  ok($o->save, "object save() 1 - $db_type");

  my $objs = 
    MyInformixObject->get_objectz(
      #debug => 1,
      share_db     => 1,
      #hints  => { comment => '+FIRST_ROWS' },
      #hints => { first_rows => 1 },
      #hints => { rose_db_object_test => { first_rows => 1, comment => 'FOO' } },
      #hints => { t1 => { first_rows => 1 } },
      query        =>
      [
        id         => { ge => 1 },
        name       => 'John',  
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        fixed      => { like => 'nee%' },
        or         => [ and => [ '!bits' => '00001', bits => { ne => '11111' } ],
                        and => [ bits => { lt => '10101' }, '!bits' => '10000' ] ],
        start      => '01/02/2001',
        save_col   => [ 1, 5 ],
        nums       => 'SET{1,2,3}',
        fk1        => 2,
        last_modified => { le => $o->db->format_timestamp($o->db->parse_timestamp('now')) },
        date_created  => '2004-03-30 12:34:56',
        date_created  => { le => 'current' },
        date_created  => [ 'current', '2004-03-30 12:34:56' ],
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 2 - $db_type");

  my $o2 = $o->clone;
  $o2->id(2);
  $o2->name('Fred');

  ok($o2->save, "object save() 2 - $db_type");

  my $o3 = $o2->clone;
  $o3->id(3);
  $o3->name('Sue');

  ok($o3->save, "object save() 3 - $db_type");

  my $o4 = $o3->clone;
  $o4->id(4);
  $o4->name('Bob');

  ok($o4->save, "object save() 4 - $db_type");

  eval
  {
    $objs = 
      MyInformixObjectManager->get_objectz(
        query  =>
        [
          date_created => '205-1-2', # invalid date
        ]);
  };

  ok($@, "Invalid date - $db_type");

  eval
  {
    $objs = 
      MyInformixObjectManager->get_objectz(
        query => [ flag => [] ]);
  };

  ok($@, "Empty list 1 - $db_type");

  $objs = 
    MyInformixObjectManager->get_objectz(
      allow_empty_lists => 1,
      query  => [ flag => [] ]);

  is(scalar @$objs, 4, "Empty list 2 - $db_type");

  eval
  {
    $objs = 
      MyInformixObjectManager->get_objectz(
        query => [ or => [ flag => 1, status => [] ] ]);
  };

  ok($@, "Empty list 3 - $db_type");

  $objs = 
    MyInformixObjectManager->get_objectz(
      allow_empty_lists => 1,
        query => [ or => [ flag => 1, status => [] ] ]);

  is(scalar @$objs, 4, "Empty list 4 - $db_type");

  $objs = 
    MyInformixObjectManager->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start      => '01/02/2001',
        save_col   => [ 1, 5 ],
        nums       => 'SET{1,2,3}',
        last_modified => { le => $o->db->format_timestamp($o->db->parse_timestamp('now')) },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is(ref $objs, 'ARRAY', "get_objects() 3 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 2, "get_objects() 4 - $db_type");
  is($objs->[0]->id, 3, "get_objects() 5 - $db_type");
  is($objs->[1]->id, 2, "get_objects() 6 - $db_type");

  my $count =
    MyInformixObject->get_objectz_count(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start      => '01/02/2001',
        save_col   => [ 1, 5 ],
        nums       => 'SET{1,2,3}',
        last_modified => { le => $o->db->format_timestamp($o->db->parse_timestamp('now')) },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is($count, 2, "get_objects_count() 1 - $db_type");

  # Set up sub-object for this one test
  my $b1 = MyInformixBB->new(id   => 1, name => 'one');
  $b1->save;

  $objs->[0]->b1(1);
  $objs->[0]->save;

  $count =
    MyInformixObjectManager->get_objectz_count(
      share_db     => 1,
      query_is_sql => 1,
      require_objects => [ 'bb1' ],
      query        =>
      [
        't2.name'  => { like => 'o%' },
        't2_name'  => { like => 'on%' },
        'bb1.name' => { like => '%n%' },
        id         => { ge => 2 },
        name       => { like => '%e%' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is($count, 1, "get_objects_count() require 1 - $db_type");

  # Clear sub-object
  $objs->[0]->b1(undef);
  $objs->[0]->save;
  $b1->delete;

  my $save_o = $o;

  my $iterator = 
    MyInformixObjectManager->get_objectz_iterator(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start      => '01/02/2001',
        save_col   => [ 1, 5 ],
        nums       => 'SET{1,2,3}',
        last_modified => { le => $o->db->format_timestamp($o->db->parse_timestamp('now')) },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name');

  is(ref $iterator, 'Rose::DB::Object::Iterator', "get_objects_iterator() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator next() 1 - $db_type");
  is($o->id, 2, "iterator next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator next() 3 - $db_type");
  is($o->id, 3, "iterator next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator next() 5 - $db_type");
  is($iterator->total, 2, "iterator total() - $db_type");

  $iterator = 
    MyInformixObject->get_objectz_iterator(
      share_db     => 1,
      skip_first   => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start      => '01/02/2001',
        save_col   => [ 1, 5 ],
        nums       => 'SET{1,2,3}',
        last_modified => { le => $save_o->db->format_timestamp($save_o->db->parse_timestamp('now')) },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name');

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator skip_first next() 1 - $db_type");
  is($o->id, 3, "iterator skip_first next() 2 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator skip_first next() 3 - $db_type");
  is($iterator->total, 1, "iterator total() - $db_type");

  my $fo = MyInformixOtherObject->new(name => 'Foo 1',
                                      k1   => 1,
                                      k2   => 2,
                                      k3   => 3);

  ok($fo->save, "object save() 5 - $db_type");

  $fo = MyInformixOtherObject->new(name => 'Foo 2',
                                   k1   => 2,
                                   k2   => 3,
                                   k3   => 4);

  ok($fo->save, "object save() 6 - $db_type");

  $fo = MyInformixBB->new(id   => 1,
                          name => 'one');
  ok($fo->save, "bb object save() 1 - $db_type");

  $fo = MyInformixBB->new(id   => 2,
                          name => 'two');
  ok($fo->save, "bb object save() 2 - $db_type");

  $fo = MyInformixBB->new(id   => 3,
                          name => 'three');
  ok($fo->save, "bb object save() 3 - $db_type");

  $fo = MyInformixBB->new(id   => 4,
                          name => 'four');
  ok($fo->save, "bb object save() 4 - $db_type");

  my $o5 = MyInformixObject->new(id         => 5,
                                 name       => 'Betty',  
                                 flag       => 'f',
                                 flag2      => 't',
                                 status     => 'with',
                                 bits       => '10101',
                                 start      => '2002-05-20',
                                 save_col   => 123,
                                 nums       => [ 4, 5, 6 ],
                                 fkone      => 1,
                                 fk2        => 2,
                                 fk3        => 3,
                                 b1         => 2,
                                 b2         => 4,
                                 last_modified => '2001-01-10 20:34:56',
                                 date_created  => '2002-05-10 10:34:56');

  ok($o5->save, "object save() 7 - $db_type");

  my $fo1 = $o5->other_obj;

  ok($fo1 && ref $fo1 && $fo1->k1 == 1 && $fo1->k2 == 2 && $fo1->k3 == 3,
     "foreign object 1 - $db_type");

  $fo1 = $o5->bb1;
  ok($fo1 && ref $fo1 && $fo1->id == 2, "bb foreign object 1 - $db_type");

  $fo1 = $o5->bb2;
  ok($fo1 && ref $fo1 && $fo1->id == 4, "bb foreign object 2 - $db_type");

  $objs = 
    MyInformixObjectManager->get_objectz(
      share_db     => 1,
      query        =>
      [
        id    => { ge => 2 },
        name  => { like => '%tt%' },
      ],
      require_objects => [ 'other_obj' ]);

  ok(ref $objs->[0]->{'other_obj'} eq 'MyInformixOtherObject', "foreign object 2 - $db_type");
  is($objs->[0]->other_obj->k2, 2, "foreign object 3 - $db_type");

  is($objs->[0]->bb1->name, 'two', "bb foreign object 3 - $db_type");
  is($objs->[0]->bb2->name, 'four', "bb foreign object 4 - $db_type");

  # Start "one to many" tests

  ok($fo = MyInformixNick->new(id   => 1,
                               o_id => 5,
                               nick => 'none',
                               type => { name => 'nt one', t2 => { name => 'nt2 one' } },
                               alts => [ { alt => 'alt one 1' },
                                         { alt => 'alt one 2' },
                                         { alt => 'alt one 3' }, ],
                               opts => [ { opt => 'opt one 1' },
                                         { opt => 'opt one 2' } ])->save,
     "nick object save() 1 - $db_type");

  $fo = MyInformixNick->new(id   => 2,
                            o_id => 2,
                            nick => 'ntwo',
                            type => { name => 'nt two', t2 => { name => 'nt2 two' } },
                            alts => [ { alt => 'alt two 1' } ]);
  ok($fo->save, "nick object save() 2 - $db_type");

  $fo = MyInformixNick->new(id   => 3,
                            o_id => 5,
                            nick => 'nthree',
                            type => { name => 'nt three', t2 => { name => 'nt2 three' } },
                            opts => [ { opt => 'opt three 1' },  { opt => 'opt three 2' } ]);
  ok($fo->save, "nick object save() 3 - $db_type");

  $fo = MyInformixNick->new(id   => 4,
                            o_id => 2,
                            nick => 'nfour',
                            type => { name => 'nt four', t2 => { name => 'nt2 four' } });
  ok($fo->save, "nick object save() 4 - $db_type");

  $fo = MyInformixNick->new(id   => 5,
                            o_id => 5,
                            nick => 'nfive',
                            type => { name => 'nt five', t2 => { name => 'nt2 five' } });
  ok($fo->save, "nick object save() 5 - $db_type");

  $fo = MyInformixNick->new(id   => 6,
                            o_id => 5,
                            nick => 'nsix',
                            type => { name => 'nt six', t2 => { name => 'nt2 six' } });
  ok($fo->save, "nick object save() 6 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      share_db     => 1,
      with_objects => [ 'nicks' ],
      query        =>
      [
        id         => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't2.nick'  => { like => 'n%' },
        start      => '5/20/2002',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        or         => [],
        and        => [],
        save_col   => [ 1, 5, 123 ],
        nums       => [ 4, 5, 6 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() with many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 2 - $db_type");

  ok(!defined $objs->[0]->{'status'}, "lazy main 1 - $db_type");
  is($objs->[0]->status, 'with', "lazy main 2 - $db_type");

  my $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 5 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 7 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks', 'bb1' ],
      query        =>
      [
        't1.id'    => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't3.nick'  => { like => 'n%' },
        start      => '5/20/2002',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        save_col   => [ 1, 5, 123 ],
        nums       => [ 4, 5, 6 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() with many 8 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 9 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 10 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 11 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 12 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 13 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 14 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many bb1 1 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many bb2 2 - $db_type");

  $iterator = 
    MyInformixObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name');

  is(ref $iterator, 'Rose::DB::Object::Iterator', "get_objects_iterator() 1 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator many next() 1 - $db_type");
  is($o->id, 5, "iterator many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator many next() 3 - $db_type");
  is($o->id, 4, "iterator many next() 4 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator many next() 5 - $db_type");
  is($o->id, 2, "iterator many next() 6 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "iterator many sub-object 1 - $db_type");
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "iterator many sub-object 2 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "iterator many sub-object 3 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator many next() 7 - $db_type");
  is($o->id, 3, "iterator many next() 8 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator many next() 9 - $db_type");
  is($iterator->total, 4, "iterator many total() - $db_type");

  $iterator = 
    MyInformixObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      limit_with_subselect => 0,
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      sort_by => 't1.name',
      limit   => 2);

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator limit 2 many next() 1 - $db_type");
  is($o->id, 5, "iterator limit 2 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 2 many next() 3 - $db_type");
  is($o->id, 4, "iterator limit 2 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 2 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 2 many total() - $db_type");

  $iterator = 
    MyInformixObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => [ 'nicks' ],
      sort_by => 't1.name',
      limit   => 3);

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator limit 3 many next() 1 - $db_type");
  is($o->id, 5, "iterator limit 3 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 3 many next() 3 - $db_type");
  is($o->id, 4, "iterator limit 3 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 3 many next() 5 - $db_type");
  is($o->id, 2, "iterator limit 3 many next() 6 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "iterator limit 3 many sub-object 1 - $db_type");
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "iterator limit 3 many sub-object 2 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "iterator limit 3 many sub-object 3 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 3 many next() 7 - $db_type");
  is($iterator->total, 3, "iterator limit 3 many total() - $db_type");

  $objs = 
    MyInformixObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      sort_by => 't1.name',
      limit   => 2);

  ok(ref $objs && @$objs == 2, "get_objects() limit 2 many 1 - $db_type");
  is($objs->[0]->name, 'Betty', "get_objects() limit 2 many 2 - $db_type");
  is($objs->[0]->id, 5, "get_objects() limit 2 many 3 - $db_type");

  is($objs->[1]->name, 'Bob', "get_objects() limit 2 many 4 - $db_type");
  is($objs->[1]->id, 4, "get_objects() limit 2 many 5 - $db_type");

  $objs = 
    MyInformixObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'nicks', 'bb2' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3);

  ok(ref $objs && @$objs == 3, "get_objects() limit 3 many 1 - $db_type");
  is($objs->[0]->name, 'Betty', "get_objects() limit 3 many 2 - $db_type");
  is($objs->[0]->id, 5, "get_objects() limit 3 many 3 - $db_type");

  is($objs->[1]->name, 'Bob', "get_objects() limit 3 many 4 - $db_type");
  is($objs->[1]->id, 4, "get_objects() limit 3 many 5 - $db_type");

  is($objs->[2]->name, 'Fred', "get_objects() limit 3 many 6 - $db_type");
  is($objs->[2]->id, 2, "get_objects() limit 3 many 7 - $db_type");
  is(scalar @{$objs->[2]->{'nicks'}}, 2, 'get_objects() limit 3 many sub-object 1');
  is($objs->[2]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 3 many sub-object 2');
  is($objs->[2]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 3 many sub-object 3');

  $iterator = 
    MyInformixObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 2,
      offset  => 1);

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 2 offset 1 many next() 1 - $db_type");
  is($o->id, 4, "iterator limit 2 offset 1 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 2 offset 1 many next() 3 - $db_type");
  is($o->id, 2, "iterator limit 2 offset 1 many next() 4 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, 'iterator limit 2 offset 1 many sub-object 1');
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', 'iterator limit 2 offset 1 many sub-object 2');
  is($o->{'nicks'}[1]{'nick'}, 'nfour', 'iterator limit 2 offset 1 many sub-object 3');

  $o = $iterator->next;
  is($o, 0, "iterator limit 2 offset 1 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 2 offset 1 many total() - $db_type");

  $iterator = 
    MyInformixObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3,
      offset  => 2);

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 3 offset 2 many next() 1 - $db_type");
  is($o->id, 2, "iterator limit 3 offset 2 many next() 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, 'iterator limit 3 offset 2 many sub-object 1');
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', 'iterator limit 3 offset 2 many sub-object 2');
  is($o->{'nicks'}[1]{'nick'}, 'nfour', 'iterator limit 3 offset 2 many sub-object 3');

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator limit 3 offset 2 many next() 3 - $db_type");
  is($o->id, 3, "iterator limit 3 offset 2 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 3 offset 2 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 3 offset 2 many total() - $db_type");

  $objs = 
    MyInformixObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 2,
      offset  => 1);

  ok(ref $objs && @$objs == 2, "get_objects() limit 2 offset 1 many 1 - $db_type");
  is($objs->[0]->name, 'Bob', "get_objects() limit 2 offset 1 many 2 - $db_type");
  is($objs->[0]->id, 4, "get_objects() limit 2 offset 1 many 3 - $db_type");

  is($objs->[1]->name, 'Fred', "get_objects() limit 2 offset 1 many 4 - $db_type");
  is($objs->[1]->id, 2, "get_objects() limit 2 offset 1 many 5 - $db_type");
  is(scalar @{$objs->[1]->{'nicks'}}, 2, 'get_objects() limit 2 offset 1 many sub-object 1');
  is($objs->[1]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 2 offset 1 many sub-object 2');
  is($objs->[1]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 2 offset 1 many sub-object 3');

  $objs = 
    MyInformixObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'nicks', 'bb2' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3,
      offset  => 2);

  ok(ref $objs && @$objs == 2, "get_objects() limit 3 offset 2 many 1 - $db_type");

  is($objs->[0]->name, 'Fred', "get_objects() limit 3 offset 2 many 2 - $db_type");
  is($objs->[0]->id, 2, "get_objects() limit 3 offset 2 many 3 - $db_type");
  is(scalar @{$objs->[0]->{'nicks'}}, 2, 'get_objects() limit 3 offset 2 many sub-object 1');
  is($objs->[0]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 3 offset 2 many sub-object 2');
  is($objs->[0]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 3 offset 2 many sub-object 3');

  is($objs->[1]->name, 'Sue', "get_objects() limit 3 offset 2 many 4 - $db_type");
  is($objs->[1]->id, 3, "get_objects() limit 3 offset 2 many 5 - $db_type");

  my $o6 = $o2->clone;
  $o6->id(60);
  $o6->fkone(undef);
  $o6->fk2(undef);
  $o6->fk3(undef);
  $o6->b1(undef);
  $o6->b2(2);
  $o6->name('Ted');

  ok($o6->save, "object save() 8 - $db_type");

  my $o7 = $o2->clone;
  $o7->id(70);
  $o7->b1(3);
  $o7->b2(undef);
  $o7->name('Joe');

  ok($o7->save, "object save() 9 - $db_type");

  my $o8 = $o2->clone;
  $o8->id(80);
  $o8->b1(undef);
  $o8->b2(undef);
  $o8->name('Pete');

  ok($o8->save, "object save() 10 - $db_type");

  ok($fo->save, "object save() 10 - $db_type");

  $fo = MyInformixNick->new(id   => 7,
                         o_id => 60,
                         nick => 'nseven');

  ok($fo->save, "nick object save() 7 - $db_type");

  $fo = MyInformixNick->new(id   => 8,
                         o_id => 60,
                         nick => 'neight');

  ok($fo->save, "nick object save() 8 - $db_type");

  $fo = MyInformixNick->new(id   => 9,
                         o_id => 60,
                         nick => 'neight');

  ok($fo->save, "nick object save() 8 - $db_type");

  $fo = MyInformixNick2->new(id    => 1,
                          o_id  => 5,
                          nick2 => 'n2one');

  ok($fo->save, "nick2 object save() 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      query        => [ '!t1.id' => 5 ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 15 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 0, "get_objects() with many 16 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      object_class => 'MyInformixObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is($count, 1, "get_objects_count() require 1 - $db_type"); 

  #local $Rose::DB::Object::Manager::Debug = 1;  
  #$DB::single = 1;

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      object_class => 'MyInformixObject',
      share_db     => 1,
      require_objects => [ 'bb2' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is($count, 2, "get_objects_count() require 2 - $db_type"); 

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 17 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 18 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many 19 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 20 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 21 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 22 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 23 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 24 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      share_db     => 1,
      require_objects => [ 'bb1', 'bb2' ],
      with_objects    => [ 'nicks2', 'nicks' ],
      multi_many_ok   => 1,
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with multi many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with multi many 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with multi many 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with multi many 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with multi many 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with multi many 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with multi many 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with multi many 8 - $db_type");

  is($objs->[0]->{'nicks2'}[0]{'nick2'}, 'n2one', "get_objects() with multi many 9 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyInformixObject',
      share_db     => 1,
      require_objects => [ 'bb1', 'bb2' ],
      with_objects    => [ 'nicks2', 'nicks' ],
      multi_many_ok   => 1,
      query        => [ ],
      sort_by => 't1.id');

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator with and require 1 - $db_type");
  is($o->id, 5, "iterator with and require 2 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "iterator with and require 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "iterator with and require 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "iterator with and require 5 - $db_type");
  is($nicks->[2]->nick, 'none', "iterator with and require 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "iterator with and require 7 - $db_type");

  is($o->{'nicks2'}[0]{'nick2'}, 'n2one', "iterator with and require 8 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator with and require 9 - $db_type");
  is($iterator->total, 1, "iterator with and require 10 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks', 'bb1' ],
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 25 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 8, "get_objects() with many 26 - $db_type");

  my $ids = join(',', map { $_->id } @$objs);

  is($ids, '1,2,3,4,5,60,70,80', "get_objects() with many 27 - $db_type");

  $nicks = $objs->[4]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 28 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 29 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 30 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 31 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 32 - $db_type");

  is($objs->[6]->{'bb1'}->{'name'}, 'three', "get_objects() with many 33 - $db_type");
  ok(!defined $objs->[6]->{'bb2'}, "get_objects() with many 34 - $db_type");
  ok(!defined $objs->[6]->{'nicks'}, "get_objects() with many 35 - $db_type");

  ok(!defined $objs->[7]->{'bb1'}, "get_objects() with many 36 - $db_type");
  ok(!defined $objs->[7]->{'bb1'}, "get_objects() with many 37 - $db_type");
  ok(!defined $objs->[7]->{'nicks'}, "get_objects() with many 38 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 0;

  $fo = MyInformixNick->new(id => 7);
  ok($fo->delete, "with many clean-up 1 - $db_type");

  $fo = MyInformixNick->new(id => 8);
  ok($fo->delete, "with many clean-up 2 - $db_type");

  $fo = MyInformixNick->new(id => 9);
  ok($fo->delete, "with many clean-up 3 - $db_type");

  ok($o6->delete, "with many clean-up 4 - $db_type");
  ok($o7->delete, "with many clean-up 5 - $db_type");
  ok($o8->delete, "with many clean-up 6 - $db_type");

  $fo = MyInformixNick2->new(id => 1);
  ok($fo->delete, "with many clean-up 7 - $db_type");

  # End "one to many" tests

  $iterator =
    MyInformixObject->get_objectz_iterator(
      share_db     => 1,
      query        =>
      [
        't1.id'    => { ge => 2 },
        't1.name'  => { like => '%tt%' },
      ],
      require_objects => [ 'other_obj' ]);

  $o = $iterator->next;

  ok(ref $o->{'other_obj'} eq 'MyInformixOtherObject', "foreign object 4 - $db_type");
  is($o->other_obj->k2, 2, "foreign object 5 - $db_type");

  is($o->bb1->name, 'two', "bb foreign object 5 - $db_type");
  is($o->bb2->name, 'four', "bb foreign object 6 - $db_type");

  $objs = 
    MyInformixObjectManager->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 1 },
        name       => 'John',  
        flag       => 1,
        flag2      => 0,
        \q((1 = 1 and 5 > 2)),
        [ \q(fk1 > ?), 1 ],
        or =>
        [
          bits => '1',
          \q((2 = 2 and 6 > 3)),
          fk1 => { gt => 1 },
          and =>
          [
            status => 'active',
            [ \q(7 > ?), 3 ],
          ],
        ],
        status     => 'active',
        bits       => '1',
        start      => '1/2/2001',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 1,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 2,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 3,
                              day   => 3)
        },

        save_col   => [ 1, 5 ],
        nums       => [ 1, 2, 3 ],
        fk1        => 2,
        fk1        => { lt => 99 },
        fk1        => { lt => 100 },
        or         => [ nums => { in_set => [ 2, 22, 222 ] }, 
                        fk1 => { lt => 777 },
                        last_modified => '6/6/2020' ],
        nums       => { any_in_set => [ 1, 99, 100 ] },
        nums       => { in_set => [ 2, 22, 222 ] },
        nums       => { in_set => 2 },
        nums       => { all_in_set => [ 1, 2, 3 ] },
        last_modified => { le => '6/6/2020' }, # XXX: test breaks in 2020!
        date_created  => '3/30/2004 12:34:56 pm'
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() 7 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 8 - $db_type");

  $objs = 
    MyInformixObject->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        k1         => { lt => 900 },
        or         => [ k1 => { ne => 99 }, k1 => 100 ],
        or         => [ and => [ id => { ne => 123 }, id => { lt => 100  } ],
                        and => [ id => { ne => 456 }, id => { lt => 300  } ] ],
        '!k2'      => { gt => 999 },
        '!t2.name' => 'z',
        start      => { lt => DateTime->new(year => '2005', month => 1, day => 1) },
        '!start'   => { gt => DateTime->new(year => '2005', month => 1, day => 1) },
        'rose_db_object_test.name'   => { like => '%tt%' },
        '!rose_db_object_other.name' => 'q',
        '!rose_db_object_other.name' => [ 'x', 'y' ],
      ],
      require_objects => [ 'other_obj' ]);

  ok(ref $objs->[0]->{'other_obj'} eq 'MyInformixOtherObject', "foreign object 6 - $db_type");
  is($objs->[0]->other_obj->k2, 2, "foreign object 7 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $objs = 
    MyInformixObjectManager->get_objectz(
      share_db     => 1,
      queryis_sql  => 1,
      query        =>
      [
        id         => { ge => 1 },
        name       => 'John',  
        nums       => { any_in_set => [ 1, 99, 100 ] },
        '!nums'    => { any_in_set => [ 7, 9 ] },
        nums       => { in_set => [ 2, 22, 222 ] },
        nums       => { in_set => 2 },
        nums       => { all_in_set => [ 1, 2, 3 ] },
        '!nums'    => { all_in_set => [ 1, 2, 72 ] },
      ],
      limit   => 5,
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() 9 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 10 - $db_type");

  # Test limit with offset

  foreach my $id (6 .. 20)
  {
    my $o = $o5->clone;
    $o->id($id);
    $o->name("Clone $id");

    ok($o->save, "object save() clone $id - $db_type");
  }

  $objs = 
    MyInformixObject->get_objectz(
      sort_by      => 'id DESC',
      limit        => 2,
      offset       => 8);

  ok(ref $objs eq 'ARRAY' && @$objs == 2 && 
     $objs->[0]->id == 12 && $objs->[1]->id == 11,
     "get_objects() with offset - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $objs = 
    MyInformixObjectManager->get_objectz(
      sort_by      => 'id DESC',
      require_objects => [ 'other_obj' ],
      limit        => 2,
      offset       => 8);

  ok(ref $objs eq 'ARRAY' && @$objs == 2 && 
     $objs->[0]->id == 12 && $objs->[1]->id == 11,
     "get_objects() with objects and offset - $db_type");

  $iterator = 
    MyInformixObject->get_objectz_iterator(
      sort_by      => 'id DESC',
      limit        => 2,
      offset       => 8);

  $o = $iterator->next;
  is($o->id, 12, "get_objects_iterator() with offset 1 - $db_type");

  $o = $iterator->next;
  is($o->id, 11, "get_objects_iterator() with offset 2 - $db_type");

  is($iterator->next, 0, "get_objects_iterator() with offset 3 - $db_type");

  eval
  {
    $objs = 
      MyInformixObjectManager->get_objectz(
        object_class => 'MyInformixObject',
        sort_by      => 'id DESC',
        offset       => 8)
  };

  ok($@ =~ /invalid without a limit/, "get_objects() missing offset - $db_type");

  eval
  {
    $iterator = 
      MyInformixObject->get_objectz_iterator(
        object_class => 'MyInformixObject',
        sort_by      => 'id DESC',
        offset       => 8);
  };

  ok($@ =~ /invalid without a limit/, "get_objects_iterator() missing offset - $db_type");

  # Start *_sql comparison tests

  $o6->fk2(99);
  $o6->fk3(99);
  $o6->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ 'fk2' => { eq_sql => 'fk3' } ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq_sql 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq_sql 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq_sql 3 - $db_type");

  # End *_sql comparison tests

  # Start IN NULL tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => [ undef, 60 ], '!id' => \'id + 1' ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() in null 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() in null 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() in null 3 - $db_type");

  # End IN NULL tests

  # Start scalar ref tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ 'fk2' => \'fk3' ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq ref 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq ref 3 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ 'fk2' => [ \'fk3' ] ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 4 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq ref 5 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq ref 6 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ 'fk2' => { ne => \'fk3' } ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 7 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 16, "get_objects() eq ref 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ 'fk2' => { ne => [ \'fk3' ] } ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 9 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 16, "get_objects() eq ref 10 - $db_type");

  # End scalar ref tests

  # Start "many to many" tests

  $fo = MyInformixColor->new(id => 1, name => 'Red');
  $fo->save;

  $fo = MyInformixColor->new(id => 2, name => 'Green');
  $fo->save;

  $fo = MyInformixColor->new(id => 3, name => 'Blue');
  $fo->save;

  $fo = MyInformixColorMap->new(id => 1, object_id => $o2->id, color_id => 1);
  $fo->save;

  $fo = MyInformixColorMap->new(id => 2, object_id => $o2->id, color_id => 3);
  $fo->save;

  $o2->b1(4);
  $o2->b1(2);
  $o2->fkone(2);
  $o2->fk2(3);
  $o2->fk3(4);
  $o2->save;

  my @colors = $o2->colors;
  ok(@colors == 2 && $colors[0]->name eq 'Red' &&
     $colors[1]->name eq 'Blue', "Fetch many to many 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyInformixObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_record',
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many 4 - $db_type");
  is($objs->[2]->id, 1, "get_objects() with many to many 5 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many 12 - $db_type");

  my $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many 15 - $db_type");

  is($colors->[0]->map_record->color_id, $colors->[0]->id, "map_record 1 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 2 - $db_type");
  is($colors->[1]->map_record->color_id, $colors->[1]->id, "map_record 3 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 4 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyInformixObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_record',
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $objs = [];

  while(my $obj = $iterator->next)
  {
    push(@$objs, $obj);
  }

  is(ref $objs, 'ARRAY', "get_objects_iterator() with many to many map record 1 - $db_type");
  is(scalar @$objs, 3, "get_objects_iterator() with many to many map record  2 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  is($colors->[0]->map_record->color_id, $colors->[0]->id, "map_record 5 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 6 - $db_type");
  is($colors->[1]->map_record->color_id, $colors->[1]->id, "map_record 7 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyInformixObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_rec',
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many 2 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  is($colors->[0]->map_rec->color_id, $colors->[0]->id, "map_rec 1 - $db_type");
  is($colors->[0]->map_rec->object_id, $objs->[1]->id, "map_rec 2 - $db_type");
  is($colors->[1]->map_rec->color_id, $colors->[1]->id, "map_rec 3 - $db_type");
  is($colors->[0]->map_rec->object_id, $objs->[1]->id, "map_rec 4 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyInformixObject',
      share_db      => 1,
      with_objects  => [ 'bb1', 'nicks', 'other_obj', 'colors', 'bb2' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many (reorder) 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many (reorder) 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many (reorder) 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many (reorder) 4 - $db_type");
  is($objs->[2]->id, 1, "get_objects() with many to many (reorder) 5 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many (reorder) 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many (reorder) 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many (reorder) 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many (reorder) 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many (reorder) 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many (reorder) 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many (reorder) 12 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many (reorder) 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many (reorder) 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many (reorder) 15 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyInformixObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many require with 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 2, "get_objects() with many to many require with 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many require with 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many require with 4 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many require with 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many require with 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many require with 12 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many require with 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many require with 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many require with 15 - $db_type");

  $fo1 = $objs->[1]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'two', "get_objects() with many to many require with 16 - $db_type");

  $fo1 = $objs->[0]->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 1', "get_objects() with many to many require with 17 - $db_type");

  $fo1 = $objs->[1]->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 2', "get_objects() with many to many require with 18 - $db_type");

  ok(!defined $objs->[0]->{'colors'}, "get_objects() with many to many require with 19 - $db_type");
  ok(!defined $objs->[1]->{'bb2'}, "get_objects() with many to many require with 20 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyInformixObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many 1 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many 2 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many 5 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many 7 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many 8 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many 9 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many 10 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many 11 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many 12 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 13 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 14 - $db_type");

  $o = $iterator->next;
  is($o->name, 'John', "get_objects_iterator() with many to many 15 - $db_type");
  is($o->id, 1, "get_objects_iterator() with many to many 16 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many 17 - $db_type");
  is($iterator->total, 3, "get_objects_iterator() with many to many 18 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyInformixObject',
      share_db      => 1,
      with_objects  => [ 'bb1', 'nicks', 'other_obj', 'colors', 'bb2' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many 19 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many 20 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many 21 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many 22 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many 23 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many 24 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many 25 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many 26 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many 27 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many 28 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many 29 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many 30 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 31 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 32 - $db_type");

  $o = $iterator->next;
  is($o->name, 'John', "get_objects_iterator() with many to many 33 - $db_type");
  is($o->id, 1, "get_objects_iterator() with many to many 34 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many 35 - $db_type");
  is($iterator->total, 3, "get_objects_iterator() with many to many 36 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyInformixObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many require 1 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many require 2 - $db_type");

  $fo1 = $o->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 1', "get_objects_iterator() with many to many require 3 - $db_type");

  ok(!defined $o->{'colors'}, "get_objects_iterator() with many to many require 4 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many require 5 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many require 6 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many require 7 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many require 8 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many require 9 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many require 10 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many require 11 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many require 12 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many require 13 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many require 16 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'two', "get_objects_iterator() with many to many require 17 - $db_type");

  $fo1 = $o->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 2', "get_objects_iterator() with many to many require 18 - $db_type");

  ok(!defined $o->{'bb2'}, "get_objects_iterator() with many to many require 19 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many require 20 - $db_type");
  is($iterator->total, 2, "get_objects_iterator() with many to many require 21 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyInformixObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name',
      limit           => 1,
      offset          => 5);

  ok(!$iterator->next, "get_objects_iterator() with many to many require 22 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyInformixObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name',
      limit           => 1,
      offset          => 5);

  ok(@$objs == 0, "get_objects_iterator() with many to many require 23 - $db_type");

  # End "many to many" tests

  # Start multi-require tests

  $fo = MyInformixColorMap->new(id => 3, object_id => 5, color_id => 2);
  $fo->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyInformixObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'colors', 'other_obj' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 2, "get_objects() multi many require 1 - $db_type");

  is($objs->[0]->id, 5, "get_objects() multi many require 2 - $db_type");
  is($objs->[1]->id, 2, "get_objects() multi many require 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() multi many require 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() multi many require 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() multi many require 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() multi many require 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() multi many require 8 - $db_type");

  $colors = $objs->[0]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 1, "get_objects() multi many require 9 - $db_type");
  ok($colors->[0]->id == 2 && $colors->[0]->name eq 'Green', "get_objects() multi many require 10 - $db_type");

  $nicks = $objs->[1]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 2, "get_objects() multi many require 11 - $db_type");
  is($nicks->[0]->nick, 'ntwo', "get_objects() multi many require 12 - $db_type");
  is($nicks->[1]->nick, 'nfour', "get_objects() multi many require 13 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() multi many require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() multi many require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[1]->name eq 'Blue', "get_objects() multi many require 16 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyInformixObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'colors', 'other_obj' ],
      with_objects    => [ 'bb2' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 2, "get_objects() multi many with require 1 - $db_type");

  is($objs->[0]->id, 5, "get_objects() multi many with require 2 - $db_type");
  is($objs->[1]->id, 2, "get_objects() multi many with require 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() multi many with require 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() multi many with require 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() multi many with require 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() multi many with require 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() multi many with require 8 - $db_type");

  $colors = $objs->[0]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 1, "get_objects() multi many with require 9 - $db_type");
  ok($colors->[0]->id == 2 && $colors->[0]->name eq 'Green', "get_objects() multi many with require 10 - $db_type");

  $nicks = $objs->[1]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 2, "get_objects() multi many with require 11 - $db_type");
  is($nicks->[0]->nick, 'ntwo', "get_objects() multi many with require 12 - $db_type");
  is($nicks->[1]->nick, 'nfour', "get_objects() multi many with require 13 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() multi many with require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() multi many with require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[1]->name eq 'Blue', "get_objects() multi many with require 16 - $db_type");

  is($objs->[0]->{'bb2'}{'name'}, 'four', "get_objects() multi many with require 17 - $db_type");
  ok(!defined $objs->[1]->{'bb2'}{'name'}, "get_objects() multi many with require 18 - $db_type");

  MyInformixNick->new(id => 7, o_id => 10,  nick => 'nseven')->save;
  MyInformixNick->new(id => 8, o_id => 11,  nick => 'neight')->save;
  MyInformixNick->new(id => 9, o_id => 12,  nick => 'nnine')->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyInformixObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'bb1' ],
      with_objects    => [ 'colors' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 5, "get_objects() multi many with require map 1 - $db_type");

  is($objs->[0]->id,  5, "get_objects() multi many with require map 2 - $db_type");
  is($objs->[1]->id, 10, "get_objects() multi many with require map 3 - $db_type");
  is($objs->[2]->id, 11, "get_objects() multi many with require map 4 - $db_type");
  is($objs->[3]->id, 12, "get_objects() multi many with require map 5 - $db_type");
  is($objs->[4]->id,  2, "get_objects() multi many with require map 6 - $db_type");

  # End multi-require tests

  # Start distinct tests

  my $i = 0;

  # Can't do this in Informix thanks to the "nums" SET column: 
  # Error -9607 Collections are not allowed in the DISTINCT clause.
  #foreach my $distinct (1, [ 't1' ], [ 'rose_db_object_test' ])
  #{
  #  $i++;
  #
  #  $objs = 
  #    Rose::DB::Object::Manager->get_objects(
  #      object_class    => 'MyInformixObject',
  #      distinct        => $distinct,
  #      share_db        => 1,
  #      require_objects => [ 'nicks', 'colors', 'other_obj' ],
  #      multi_many_ok   => 1,
  #      sort_by         => 't1.name');
  #
  #  is(scalar @$objs, 2, "get_objects() distinct multi many require $i.1 - $db_type");
  #
  #  is($objs->[0]->id, 5, "get_objects() distinct multi many require $i.2 - $db_type");
  #  is($objs->[1]->id, 2, "get_objects() distinct multi many require $i.3 - $db_type");
  #
  #  ok(!defined $objs->[0]->{'nicks'}, "get_objects() distinct multi many require $i.4 - $db_type");
  #  ok(!defined $objs->[0]->{'colors'}, "get_objects() distinct multi many require $i.5 - $db_type");
  #
  #  ok(!defined $objs->[1]->{'nicks'}, "get_objects() distinct multi many require $i.6 - $db_type");
  #  ok(!defined $objs->[1]->{'colors'}, "get_objects() distinct multi many require $i.7 - $db_type");
  #}

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  # Can't do this in Informix thanks to the "nums" SET column: 
  # Error -9607 Collections are not allowed in the DISTINCT clause.
  #foreach my $distinct ([ 't2' ], [ 'rose_db_object_nicks' ], [ 'nicks' ])
  #{
  #  $i++;
  #
  #  $objs = 
  #    Rose::DB::Object::Manager->get_objects(
  #      object_class    => 'MyInformixObject',
  #      distinct        => $distinct,
  #      share_db        => 1,
  #      require_objects => [ 'nicks', 'colors', 'other_obj' ],
  #      multi_many_ok   => 1,
  #      sort_by         => 't1.name');
  #
  #  is(scalar @$objs, 2, "get_objects() distinct multi many require $i.1 - $db_type");
  #
  #  is($objs->[0]->id, 5, "get_objects() distinct multi many require $i.2 - $db_type");
  #  is($objs->[1]->id, 2, "get_objects() distinct multi many require $i.3 - $db_type");
  #
  #  ok(defined $objs->[0]->{'nicks'}, "get_objects() distinct multi many require $i.4 - $db_type");
  #  ok(!defined $objs->[0]->{'colors'}, "get_objects() distinct multi many require $i.5 - $db_type");
  #
  #  ok(defined $objs->[1]->{'nicks'}, "get_objects() distinct multi many require $i.6 - $db_type");
  #  ok(!defined $objs->[1]->{'colors'}, "get_objects() distinct multi many require $i.7 - $db_type");
  #}

  # End distinct tests

  # Start pager tests

  is(Rose::DB::Object::Manager->default_objects_per_page, 20, 'default_objects_per_page 1');

  Rose::DB::Object::Manager->default_objects_per_page(3);

  my $per_page = Rose::DB::Object::Manager->default_objects_per_page;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 1,
      per_page     => 3);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 1.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 2.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => 3);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 3.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => -1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 4.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => -1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 5.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => undef);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 6.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => undef);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 7.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id');

  ok(scalar @$objs > 3, "pager 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 2,
      per_page     => 3);

  $i = 0;

  for(4 .. 6)
  {
    is($objs->[$i++]->id, $_, "pager 9.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 3,
      per_page     => 3);

  $i = 0;

  for(7 .. 9)
  {
    is($objs->[$i++]->id, $_, "pager 10.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 4,
      per_page     => 3);

  $i = 0;

  for(10 .. 11)
  {
    is($objs->[$i++]->id, $_, "pager 11.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 5,
      per_page     => 3);

  ok(scalar @$objs == 0, "pager 12 - $db_type");

  Rose::DB::Object::Manager->default_objects_per_page(20);

  # End pager tests

  # Start get_objects_from_sql tests

  $objs = 
    MyInformixObjectManager->get_objects_from_sql(
      db  => MyInformixObject->init_db,
      object_class => 'MyInformixObject',
      prepare_cached => 1,
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  ok(scalar @$objs == 19, "get_objects_from_sql 1 - $db_type");
  is($objs->[18]->id, 1, "get_objects_from_sql 2 - $db_type");
  is($objs->[18]->save_col, 5, "get_objects_from_sql 3 - $db_type");
  is($objs->[18]->name, 'John', "get_objects_from_sql 4 - $db_type");

  $iterator = 
    MyInformixObjectManager->get_objects_iterator_from_sql(
      db  => MyInformixObject->init_db,
      object_class => 'MyInformixObject',
      prepare_cached => 1,
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  for(0 .. 17) { $iterator->next }

  $o = $iterator->next;
  is($o->id, 1, "get_objects_iterator_from_sql 1 - $db_type");
  is($o->save_col, 5, "get_objects_iterator_from_sql 2 - $db_type");
  is($o->name, 'John', "get_objects_iterator_from_sql 3 - $db_type");
  ok(!$iterator->next,  "get_objects_iterator_from_sql 4 - $db_type");

  $objs = MyInformixObjectManager->get_objects_from_sql(<<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  ok(scalar @$objs == 19, "get_objects_from_sql 5 - $db_type");
  is($objs->[18]->id, 1, "get_objects_from_sql 6 - $db_type");
  is($objs->[18]->save_col, 5, "get_objects_from_sql 7 - $db_type");
  is($objs->[18]->name, 'John', "get_objects_from_sql 8 - $db_type");

  $objs = 
    MyInformixObjectManager->get_objects_from_sql(
      args => [ 19 ],
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id > ? ORDER BY id DESC
EOF

  ok(scalar @$objs == 2, "get_objects_from_sql 9 - $db_type");
  is($objs->[0]->id, 60, "get_objects_from_sql 10 - $db_type");

  my $method = 
    MyInformixObjectManager->make_manager_method_from_sql(
      get_em => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  $objs = MyInformixObjectManager->get_em;

  ok(scalar @$objs == 19, "make_manager_method_from_sql 1 - $db_type");
  is($objs->[17]->id, 3, "make_manager_method_from_sql 2 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql 3 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql 4 - $db_type");  

  $objs = $method->('MyInformixObjectManager');

  ok(scalar @$objs == 19, "make_manager_method_from_sql 5 - $db_type");
  is($objs->[17]->id, 3, "make_manager_method_from_sql 6 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql 7 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql 8 - $db_type");  

  $method = 
    MyInformixObjectManager->make_manager_method_from_sql(
      iterator => 1, method => 'iter_em', sql => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  $iterator = MyInformixObjectManager->iter_em;

  for(0 .. 16) { $iterator->next }

  $o = $iterator->next;
  is($objs->[17]->id, 3, "make_manager_method_from_sql iterator 1 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql iterator 2 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql iterator 3 - $db_type");  

  $iterator = $method->('MyInformixObjectManager');

  for(0 .. 16) { $iterator->next }

  $o = $iterator->next;
  is($objs->[17]->id, 3, "make_manager_method_from_sql iterator 4 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql iterator 5 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql iterator 6 - $db_type");  

  $method = 
    MyInformixObjectManager->make_manager_method_from_sql(
      get_more => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id > ? ORDER BY id DESC
EOF

  $objs = MyInformixObjectManager->get_more(18);
  ok(scalar @$objs == 3, "make_manager_method_from_sql 9 - $db_type");
  is($objs->[2]->id, 19, "make_manager_method_from_sql 10 - $db_type");

  $method = 
    MyInformixObjectManager->make_manager_method_from_sql(
      method => 'get_more_np',
      params => [ qw(id name) ],
      sql    => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE 
id > ? AND name != ? ORDER BY id DESC
EOF

  $objs = MyInformixObjectManager->get_more_np(name => 'Nonesuch', id => 18);
  ok(scalar @$objs == 3, "make_manager_method_from_sql 11 - $db_type");
  is($objs->[2]->id, 19, "make_manager_method_from_sql 12 - $db_type");

  # End get_objects_from_sql tests

  # Start tough order tests

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyInformixObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1);

  ok(@$objs == 5, "tough order 1 - $db_type");
  is($objs->[0]->id, 2, "tough order 2 - $db_type");
  is($objs->[1]->id, 5, "tough order 3 - $db_type");
  is($objs->[2]->id, 10, "tough order 4 - $db_type");
  is($objs->[3]->id, 11, "tough order 5 - $db_type");
  is($objs->[4]->id, 12, "tough order 6 - $db_type");

  is($objs->[0]{'nicks'}[0]{'nick'}, 'ntwo', "tough order 7 - $db_type");
  is($objs->[0]{'nicks'}[1]{'nick'}, 'nfour', "tough order 8 - $db_type");

  is($objs->[1]{'nicks'}[0]{'nick'}, 'nthree', "tough order 9 - $db_type");
  is($objs->[1]{'nicks'}[1]{'nick'}, 'nsix', "tough order 10 - $db_type");
  is($objs->[1]{'nicks'}[2]{'nick'}, 'none', "tough order 11 - $db_type");
  is($objs->[1]{'nicks'}[3]{'nick'}, 'nfive', "tough order 12 - $db_type");

  is($objs->[2]{'nicks'}[0]{'nick'}, 'nseven', "tough order 13 - $db_type");

  is($objs->[3]{'nicks'}[0]{'nick'}, 'neight', "tough order 14 - $db_type");

  is($objs->[4]{'nicks'}[0]{'nick'}, 'nnine', "tough order 15 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyInformixObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1,
      sort_by         => 'name');

  ok(@$objs == 5, "tough order 16 - $db_type");
  is($objs->[0]->id, 5, "tough order 17 - $db_type");
  is($objs->[1]->id, 10, "tough order 18 - $db_type");
  is($objs->[2]->id, 11, "tough order 19 - $db_type");
  is($objs->[3]->id, 12, "tough order 20 - $db_type");
  is($objs->[4]->id, 2, "tough order 21 - $db_type");

  is($objs->[0]{'nicks'}[0]{'nick'}, 'nthree', "tough order 22 - $db_type");
  is($objs->[0]{'nicks'}[1]{'nick'}, 'nsix', "tough order 23 - $db_type");
  is($objs->[0]{'nicks'}[2]{'nick'}, 'none', "tough order 24 - $db_type");
  is($objs->[0]{'nicks'}[3]{'nick'}, 'nfive', "tough order 25 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 4, "tough order 26 - $db_type");

  is($objs->[1]{'nicks'}[0]{'nick'}, 'nseven', "tough order 27 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 1, "tough order 28 - $db_type");

  is($objs->[2]{'nicks'}[0]{'nick'}, 'neight', "tough order 29 - $db_type");
  is(scalar @{$objs->[2]{'nicks'}}, 1, "tough order 30 - $db_type");

  is($objs->[3]{'nicks'}[0]{'nick'}, 'nnine', "tough order 31 - $db_type");
  is(scalar @{$objs->[3]{'nicks'}}, 1, "tough order 32 - $db_type");

  is($objs->[4]{'nicks'}[0]{'nick'}, 'ntwo', "tough order 33 - $db_type");
  is($objs->[4]{'nicks'}[1]{'nick'}, 'nfour', "tough order 34 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 2, "tough order 35 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyInformixObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1,
      sort_by         => 'name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nthree', "tough order 36 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nsix', "tough order 37 - $db_type");
  is($o->{'nicks'}[2]{'nick'}, 'none', "tough order 38 - $db_type");
  is($o->{'nicks'}[3]{'nick'}, 'nfive', "tough order 39 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "tough order 40 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nseven', "tough order 41 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 42 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'neight', "tough order 43 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 44 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nnine', "tough order 45 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 46 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "tough order 47 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "tough order 48 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "tough order 49 - $db_type");

  ok(!$iterator->next, "tough order 50 - $db_type");
  is($iterator->total, 5, "tough order 51 - $db_type");

  # End tough order tests

  # Start deep join tests

  eval 
  { 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      require_objects => [ 'nicks.type' ],
      with_objects    => [ 'nicks.type' ]);
  };

  ok($@, "deep join conflict 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      require_objects => [ 'nicks.type', 'nicks.type', 'nicks' ],
      with_objects    => [ 'nicks.type.t2', 'nicks.alts' ],
      multi_many_ok   => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'type.name');

  ok(@$objs == 2, "deep join 1 - $db_type");
  is($objs->[0]->id, 2, "deep join 2 - $db_type");
  is($objs->[1]->id, 5, "deep join 3 - $db_type");

  is($objs->[0]{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join 4 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join 5 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 2, "deep join 6 - $db_type");

  is($objs->[1]{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join 7 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join 8 - $db_type");
  is($objs->[1]{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join 9 - $db_type");
  is($objs->[1]{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join 10 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 4, "deep join 11 - $db_type");

  is($objs->[0]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join 12 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join 13 - $db_type");

  is($objs->[0]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join 14 - $db_type");

  $objs->[1]{'nicks'}[1]{'alts'} = 
    [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[1]{'nicks'}[1]{'alts'}} ];
  is($objs->[1]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join 15 - $db_type");
  is($objs->[1]{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join 16 - $db_type");
  is($objs->[1]{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join 17 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[1]{'alts'}}, 3, "deep join 18 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      with_objects => [ 'nicks.type' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 21, "deep join with 1 - $db_type");
  is($objs->[0]->id, 1, "deep join with 2 - $db_type");
  is($objs->[1]->id, 2, "deep join with 3 - $db_type");
  is($objs->[2]->id, 3, "deep join with 4 - $db_type");
  is($objs->[16]->id, 17, "deep join with 5 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join with 6 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join with 7 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 2, "deep join with 8 - $db_type");

  #SORT:
  #{
  #  $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
  #}

  is($objs->[4]{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join with 9 - $db_type");
  is($objs->[4]{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join with 10 - $db_type");
  is($objs->[4]{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join with 11 - $db_type");
  is($objs->[4]{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join with 12 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 4, "deep join with 13 - $db_type");

  is(scalar @{$objs->[0]{'nicks'} ||= []}, 0, "deep join with 14 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyInformixObject',
      require_objects => [ 'nicks.type', 'nicks.type', 'nicks' ],
      with_objects    => [ 'nicks.type.t2', 'nicks.alts' ],
      multi_many_ok   => 1,
      query           => [ 'id' => [ 2, 5 ] ],
      sort_by         => 'type.name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator 3 - $db_type");

  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join 3.1 - $db_type");

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator 3.1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator 3.2 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator 8 - $db_type");

  $o->{'nicks'}[1]{'alts'} = 
    [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join iterator 9 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join iterator 10 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join iterator 11 - $db_type");
  is(scalar @{$o->{'nicks'}[1]{'alts'}}, 3, "deep join iterator 12 - $db_type");

  ok(!$iterator->next, "deep join iterator 13 - $db_type");
  is($iterator->total, 2, "deep join iterator 14 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyInformixObject',
      with_objects => [ 'nicks.type' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  $o = $iterator->next;
  is($o->id, 1, "deep join with with iterator 1 - $db_type");

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join with with iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join with iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join with iterator 3 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join with iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join with iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join with iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join with iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join with iterator 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join iterator 9 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      require_objects => [ 'nicks.type.t2' ],
      query        => [ 'id' => [ 2, 5 ] ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 2, "deep join three-level 1 - $db_type");
  is($objs->[0]->id, 2, "deep join three-level 2 - $db_type");
  is($objs->[1]->id, 5, "deep join three-level 3 - $db_type");

  #SORT:
  #{
  #  $objs->[0]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[0]{'nicks'}} ];
  #}

  is($objs->[0]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join three-level 4 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join three-level 5 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 2, "deep join three-level 6 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join three-level 7 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join three-level 8 - $db_type");
  is($objs->[1]{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join three-level 9 - $db_type");
  is($objs->[1]{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join three-level 10 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 4, "deep join three-level 11 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      with_objects => [ 'nicks.type.t2' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 21, "deep join three-level 1 - $db_type");
  is($objs->[0]->id, 1, "deep join three-level 2 - $db_type");
  is($objs->[1]->id, 2, "deep join three-level 3 - $db_type");
  is($objs->[4]->id, 5, "deep join three-level 4 - $db_type");
  is($objs->[20]->id, 60, "deep join three-level 5 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #}

  is($objs->[1]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join three-level 6 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join three-level 7 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 2, "deep join three-level 8 - $db_type");

  #SORT:
  #{
  #  $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
  #}

  is($objs->[4]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join three-level 9 - $db_type");
  is($objs->[4]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join three-level 10 - $db_type");
  is($objs->[4]{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join three-level 11 - $db_type");
  is($objs->[4]{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join three-level 12 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 4, "deep join three-level 13 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyInformixObject',
      require_objects => [ 'nicks.type.t2' ],
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'type.name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator 3 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator 8 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyInformixObject',
      with_objects => [ 'nicks.type.t2' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  $o = $iterator->next;
  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator with 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator with 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator with 3 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #}

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join iterator with 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join iterator with 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join iterator with 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join iterator with 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator with 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join iterator with 9 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyInformixObject',
      require_objects => [ 'nicks.alts' ],
      multi_many_ok => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'alts.alt');

  ok(@$objs == 2, "deep join multi 1 - $db_type");
  is($objs->[0]->id, 2, "deep join multi 2 - $db_type");
  is($objs->[1]->id, 5, "deep join multi 3 - $db_type");

  is($objs->[0]{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi 4 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}[0]{'alts'}}, 1, "deep join multi 5 - $db_type");

  is($objs->[1]{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi 6 - $db_type");
  is($objs->[1]{'nicks'}[0]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi 7 - $db_type");
  is($objs->[1]{'nicks'}[0]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi 8 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[0]{'alts'}}, 3, "deep join multi 11 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyInformixObject',
      with_objects  => [ 'nicks.alts' ],
      multi_many_ok => 1,
      nonlazy       => 1,
      sort_by       => 'alts.alt');

  ok(@$objs == 21, "deep join multi with 1 - $db_type");
  is($objs->[1]->id, 2, "deep join multi with 2 - $db_type");
  is($objs->[4]->id, 5, "deep join multi with 3 - $db_type");

  #SORT:
  #{
  #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  #  $objs->[1]{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[1]{'nicks'}[1]{'alts'}} ];
  #}

  is($objs->[1]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi with with 4 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[1]{'alts'}}, 1, "deep join multi with 5 - $db_type");

  #SORT:
  #{
  #  $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
  #  $objs->[4]{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[4]{'nicks'}[3]{'alts'}} ];
  #}

  is($objs->[4]{'nicks'}[3]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi with 6 - $db_type");
  is($objs->[4]{'nicks'}[3]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi with 7 - $db_type");
  is($objs->[4]{'nicks'}[3]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi with 8 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}[3]{'alts'}}, 3, "deep join multi with 11 - $db_type");

  is(scalar @{$objs->[0]{'nicks'} || []}, 0, "deep join multi with 12 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyInformixObject',
      require_objects => [ 'nicks.alts' ],
      multi_many_ok => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'alts.alt');

  $o = $iterator->next;
  is($o->id, 2, "deep join multi iter 1 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi iter 2 - $db_type");
  is(scalar @{$o->{'nicks'}[0]{'alts'}}, 1, "deep join multi iter 3 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi iter 4 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi iter 5 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi iter 6 - $db_type");
  is(scalar @{$o->{'nicks'}[0]{'alts'}}, 3, "deep join multi iter 7 - $db_type");

  ok(!$iterator->next, "deep join multi iter 8 - $db_type");
  is($iterator->total, 2, "deep join multi iter 9 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyInformixObject',
      with_objects  => [ 'nicks.alts' ],
      multi_many_ok => 1,
      nonlazy       => 1,
      #query => [ id => 2 ],
      sort_by       => 'alts.alt');

  $o = $iterator->next;
  is(scalar @{$o->{'nicks'} ||= []}, 0, "deep join multi iter with 1 - $db_type");

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #  $o->{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
  #}

  is($o->id, 2, "deep join multi iter with 2 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi iter with 3 - $db_type");
  is(scalar @{$o->{'nicks'}[1]{'alts'}}, 1, "deep join multi iter with 4 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  #SORT:
  #{
  #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  #  $o->{'nicks'}[3]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[3]{'alts'}} ];
  #}

  is($o->{'nicks'}[3]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi iter with 5 - $db_type");
  is($o->{'nicks'}[3]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi iter with 6 - $db_type");
  is($o->{'nicks'}[3]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi iter with 7 - $db_type");
  is(scalar @{$o->{'nicks'}[3]{'alts'}}, 3, "deep join multi iter with 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join multi iter with 9 - $db_type");

  # End deep join tests

  # Start custom select tests

  my @selects =
  (
    't2.nick, id, t2.id, name, UPPER(name) AS derived, fk1',
    't1.id, t2.nick, t2.id, t1.name, UPPER(name) AS derived, t1.fk1',
    'rose_db_object_nicks.id, rose_db_object_test.id, rose_db_object_nicks.nick, rose_db_object_test.name, UPPER(name) AS derived',
    [ \q(t1.id + 0 AS id), qw(name t2.nick nicks.id), \q(UPPER(name) AS derived) ],
    [ qw(t2.nick t2.id t1.id t1.name), 'UPPER(name) AS derived' ],
    [ \q(UPPER(name) AS derived), qw(t2.id rose_db_object_nicks.nick rose_db_object_test.id rose_db_object_test.name) ],
    [ qw(rose_db_object_test.id rose_db_object_nicks.nick rose_db_object_test.name rose_db_object_nicks.id), 'UPPER(name) AS derived' ],
    [ qw(rose_db_object_test.id rose_db_object_test.name rose_db_object_nicks.nick t2.id), 'UPPER(name) AS derived' ],
  );

  $i = 0;

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MyInformixObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && !defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && !defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyInformixObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && defined $objs->[0]->nicks->[0]->nick &&
       !defined $objs->[0]->nicks->[0]->type_id && !defined $objs->[0]->flag2 &&
       $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && defined $objs->[1]->nicks->[0]->nick &&
       !defined $objs->[1]->nicks->[0]->type_id && !defined $objs->[1]->flag2 &&
       $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  @selects =
  (
    't2.nick, t1.*, t2.id, name, UPPER(name) AS derived',
    [ qw(t2.nick t2.id t1.*), 'UPPER(name) AS derived' ],
  );

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MyInformixObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyInformixObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && defined $objs->[0]->nicks->[0]->nick &&
       !defined $objs->[0]->nicks->[0]->type_id && defined $objs->[0]->flag2 &&
       $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && defined $objs->[1]->nicks->[0]->nick &&
       !defined $objs->[1]->nicks->[0]->type_id && defined $objs->[1]->flag2 &&
       $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  @selects =
  (
    '*, name, UPPER(name) AS derived',
    [ '*', 'UPPER(name) AS derived' ],
  );

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MyInformixObject',
        select          => $select,
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->flag2 && 
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyInformixObject',
        select          => $select,
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && 
       defined $objs->[0]->flag2 && $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && 
       defined $objs->[1]->flag2 && $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  # End custom select tests
}

#
# SQLite
#

SKIP: foreach my $db_type (qw(sqlite))
{
  skip("SQLite tests", 796)  unless($HAVE_SQLITE);

  Rose::DB->default_type($db_type);

  my($sql, $bind) = 
    Rose::DB::Object::Manager->get_objects_sql(
      object_class => 'MySQLiteObject',
      where => 
      [
        name  => { '@' => \q(xxx) },
        start => { lt => \q(CURRENT_TIMESTAMP) },
      ]);

  like($sql, qr/\bname @ xxx\b/, "strict_ops 1.0 - $db_type");
  like($sql, qr/\bstart < CURRENT_TIMESTAMP\b/, "strict_ops 1.1 - $db_type");

  eval
  {
    ($sql, $bind) = 
      Rose::DB::Object::Manager->get_objects_sql(
        object_class => 'MySQLiteObject',
        strict_ops => 1,
        where => [ name => { '@' => \q(xxx) } ]);
  };

  ok($@, "strict_ops 2 - $db_type");

  Rose::DB::Object::Manager->strict_ops(1);

  eval
  {
    ($sql, $bind) = 
      Rose::DB::Object::Manager->get_objects_sql(
        object_class => 'MySQLiteObject',
        where => [ name => { '@' => \q(xxx) } ]);
  };

  ok($@, "strict_ops 3 - $db_type");

  Rose::DB::Object::Manager->strict_ops(0);

  ($sql, $bind) = 
    Rose::DB::Object::Manager->get_objects_sql(
      object_class => 'MySQLiteObject',
      where => [ name => { like => \q('%foo%') } ]);

  ok($sql =~ /name LIKE '%foo%'/, "scalar ref bind 1 - $db_type");
  is(@$bind, 0, "scalar ref bind 2 - $db_type");

  ($sql, $bind) = 
    Rose::DB::Object::Manager->get_objects_sql(
      object_class => 'MySQLiteObject',
      require_objects => [ 'bb1' ],
      query => [ 'bb1.name' => { like => \q('%foo%') } ]);

  ok($sql =~ /name LIKE '%foo%'/, "scalar ref bind 3 - $db_type");
  is(@$bind, 0, "scalar ref bind 4 - $db_type");

  ($sql, $bind) = 
    Rose::DB::Object::Manager->get_objects_sql(
      object_class => 'MySQLiteObject',
      require_objects => [ 'bb1' ],
      query => 
      [
        or =>
        [
          name => 'bar',
          'bb1.name' => { like => \q('%foo%') },
        ],
      ]);

  ok($sql =~ /t2\.name LIKE '%foo%'/, "scalar ref bind 5 - $db_type");
  is(@$bind, 1, "scalar ref bind 6 - $db_type");

  # Return ignored, just chaging arg validity
  my $xcount =
    MySQLiteObjectManager->object_count(
      share_db     => 1,
      #debug => 1,
      require_objects => [ 'bb1' ],
      query        =>
      [
         foo   => { ne => 'xxx' },
        't2.x' => { like => 'o%' },
      ]);

  my $o = MySQLiteObject->new(id         => 1,
                          name       => 'John',  
                          flag       => 't',
                          flag2      => 'f',
                          fkone      => 2,
                          status     => 'active',
                          bits       => '00001',
                          start      => '2001-01-02',
                          save_col   => 5,     
                          nums       => [ 1, 2, 3 ],
                          last_modified => 'now',
                          date_created  => '2004-03-30 12:34:56');

  ok($o->save, "object save() 1 - $db_type");

  my $objs = 
    MySQLiteObject->get_objectz(
      share_db     => 1,
      #query_is_sql => 1,
      #debug => 1,
      query        =>
      [
        id         => { gt_lt => [ -1, 991 ] },
        id         => { gt_le => [ -1, 992 ] },
        id         => { ge_lt => [ -1, 993 ] },
        id         => { ge_le => [ -1, 994 ] },
        id         => { gt_lt_sql => [ -1, 991 ] },
        id         => { gt_le_sql => [ -1, 992 ] },
        id         => { ge_lt_sql => [ -1, 993 ] },
        id         => { ge_le_sql => [ -1, 994 ] },
        id         => { gt_lt => [ -1, \991 ] },
        id         => { gt_le => [ \-1, 992 ] },
        id         => { ge_lt => [ -1, \993 ] },
        id         => { ge_le => [ \-1, 994 ] },
        id         => { between => [ 0, 99 ] },
        id         => { between => [ 0, \q(101) ] },
        id         => { between => [ \1, 99 ] },
        id         => { ge => 1 },
        id         => { ne => undef },
        fk3        => { eq => undef },
        name       => 'John', 
        name       => { field => 'LOWER(name)', eq => 'john' },
        flag       => 1,
        flag2      => 0,
        \q((1 = 1 and 5 > 2)),
        [ \q(fk1 > ?), 1 ],
        start      => { le => \q(CURRENT_TIMESTAMP) },
        start      => { between => [ '1/1/1999', 'CURRENT_TIMESTAMP' ] },
        start      => { between_sql => [ "'1999-02-02'", 'CURRENT_TIMESTAMP' ] },
        or =>
        [
          bits => '00001',
          \q((2 = 2 and 6 > 3)),
          save_col => [ 1, 5 ],
          and =>
          [
            status => 'active',
            [ \q(7 > ?), 3 ],
          ],
        ],
        status     => 'active',
        bits       => '00001',
        fixed      => { like => 'nee%' },
        or         => [ and => [ '!bits' => '00001', bits => { ne => '11111' } ],
                        and => [ bits => { lt => '10101' }, '!bits' => '10000' ] ],
        start      => '2001-01-02',
        save_col   => [ 1, 5 ],
        nums       => '{1,2,3}',
        fk1        => 2,
        last_modified => { le => $o->db->format_timestamp(DateTime->now->add(days => 2)) },
        date_created  => '2004-03-30 12:34:56.000000000'
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => [ 'id', \q(LOWER(name)) ]);

  is(ref $objs, 'ARRAY', "get_objects() 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 2 - $db_type");

  my $o2 = $o->clone;
  $o2->id(2);
  $o2->name('Fred');

  ok($o2->save, "object save() 2 - $db_type");

  my $o3 = $o2->clone;
  $o3->id(3);
  $o3->name('Sue');

  ok($o3->save, "object save() 3 - $db_type");

  my $o4 = $o3->clone;
  $o4->id(4);
  $o4->name('Bob');

  ok($o4->save, "object save() 4 - $db_type");

  eval
  {
    $objs = 
      MySQLiteObject->get_objectz(
        where  =>
        [
          date_created => '205-1-2', # invalid date
        ]);
  };

  ok($@, "Invalid date - $db_type");

  eval
  {
    $objs = 
      MySQLiteObject->get_objectz(
        where => [ flag => [] ]);
  };

  ok($@, "Empty list 1 - $db_type");

  $objs = 
    MySQLiteObject->get_objectz(
      allow_empty_lists => 1,
      query  => [ flag => [] ]);

  is(scalar @$objs, 4, "Empty list 2 - $db_type");

  eval
  {
    $objs = 
      MySQLiteObject->get_objectz(
        query => [ or => [ flag => 1, status => [] ] ]);
  };

  ok($@, "Empty list 3 - $db_type");

  $objs = 
    MySQLiteObject->get_objectz(
      allow_empty_lists => 1,
        query => [ or => [ flag => 1, status => [] ] ]);

  is(scalar @$objs, 4, "Empty list 4 - $db_type");

  $objs = 
    MySQLiteObjectManager->get_objectz(
      share_db     => 1,
      query_is_sql => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 1,
        flag2      => 0,
        status     => 'active',
        bits       => q(b'00001'),
        start      => '2001-01-02',
        save       => [ 1, 5 ],
        nums       => '{1,2,3}',
        last_modified => { le => $o->db->format_timestamp(DateTime->now->add(days => 2)) },
        date_created  => '2004-03-30 12:34:56.000000000',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is(ref $objs, 'ARRAY', "get_objects() 3 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 2, "get_objects() 4 - $db_type");
  is($objs->[0]->id, 3, "get_objects() 5 - $db_type");
  is($objs->[1]->id, 2, "get_objects() 6 - $db_type");

  my $count =
    MySQLiteObjectManager->object_count(
      share_db     => 1,
      query_is_sql => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 1,
        flag2      => 0,
        status     => 'active',
        bits       => q(b'00001'),
        start      => '2001-01-02',
        save       => [ 1, 5 ],
        nums       => '{1,2,3}',
        last_modified => { le => $o->db->format_timestamp(DateTime->now->add(days => 2)) },
        date_created  => '2004-03-30 12:34:56.000000000',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is($count, 2, "get_objects_count() 1 - $db_type");

  # Set up sub-object for this one test
  my $b1 = MySQLiteBB->new(id   => 1, name => 'one');
  $b1->save;

  $objs->[0]->b1(1);
  $objs->[0]->save;

  $count =
    MySQLiteObjectManager->object_count(
      share_db     => 1,
      #query_is_sql => 1,
      require_objects => [ 'bb1' ],
      query        =>
      [
        't2.name'  => { like => 'o%' },
        't2_name'  => { like => 'on%' },
        'bb1.name' => { like => '%n%' },
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 1,
        flag2      => 0,
        status     => 'active',
        bits       => q(b'00001'),
        start      => '2001-01-02',
        save       => [ 1, 5 ],
        nums       => '{1,2,3}',
        last_modified => { le => $o->db->format_timestamp(DateTime->now->add(days => 2)) },
        date_created  => '2004-03-30 12:34:56.000000000',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is($count, 1, "get_objects_count() require 1 - $db_type");

  $count = MySQLiteObjectManager->object_count(
    select   => 'name',
    distinct => 1,
    all      => 1,
  );

  is($count, 4, "get_objects_count() distinct column 1 - $db_type");

  $count = MySQLiteObjectManager->object_count(
    select   => [ 'status' ],
    distinct => 1,
    all      => 1,
  );

  is($count, 1, "get_objects_count() distinct column 2 - $db_type");

  # Clear sub-object
  $objs->[0]->b1(undef);
  $objs->[0]->save;
  $b1->delete;

  my $iterator = 
    MySQLiteObjectManager->get_objectz_iterator(
      share_db     => 1,
      query_is_sql => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 1,
        flag2      => 0,
        status     => 'active',
        bits       => q(b'00001'),
        start      => '2001-01-02',
        save       => [ 1, 5 ],
        nums       => '{1,2,3}',
        last_modified => { le => $o->db->format_timestamp(DateTime->now->add(days => 2)) },
        date_created  => '2004-03-30 12:34:56.000000000',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name');

  is(ref $iterator, 'Rose::DB::Object::Iterator', "get_objects_iterator() 1 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator next() 1 - $db_type");
  is($o->id, 2, "iterator next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator next() 3 - $db_type");
  is($o->id, 3, "iterator next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator next() 5 - $db_type");
  is($iterator->total, 2, "iterator total() - $db_type");

  my $fo = MySQLiteOtherObject->new(name => 'Foo 1',
                                k1   => 1,
                                k2   => 2,
                                k3   => 3);

  ok($fo->save, "object save() 5 - $db_type");

  $fo = MySQLiteOtherObject->new(name => 'Foo 2',
                             k1   => 2,
                             k2   => 3,
                             k3   => 4);

  ok($fo->save, "object save() 6 - $db_type");

  $fo = MySQLiteBB->new(id   => 1,
                    name => 'one');
  ok($fo->save, "bb object save() 1 - $db_type");

  $fo = MySQLiteBB->new(id   => 2,
                    name => 'two');
  ok($fo->save, "bb object save() 2 - $db_type");

  $fo = MySQLiteBB->new(id   => 3,
                    name => 'three');
  ok($fo->save, "bb object save() 3 - $db_type");

  $fo = MySQLiteBB->new(id   => 4,
                    name => 'four');
  ok($fo->save, "bb object save() 4 - $db_type");

  my $o5 = MySQLiteObject->new(id         => 5,
                               name       => 'Betty',  
                               flag       => 'f',
                               flag2      => 't',
                               status     => 'with',
                               bits       => '10101',
                               start      => '2002-05-20',
                               save_col   => 123,
                               nums       => [ 4, 5, 6 ],
                               fkone      => 1,
                               fk2        => 2,
                               fk3        => 3,
                               b1         => 2,
                               b2         => 4,
                               last_modified => '2001-01-10 20:34:56',
                               date_created  => '2002-05-10 10:34:56');

  ok($o5->save, "object save() 7 - $db_type");

  my $fo1 = $o5->other_obj;

  ok($fo1 && ref $fo1 && $fo1->k1 == 1 && $fo1->k2 == 2 && $fo1->k3 == 3,
     "foreign object 1 - $db_type");

  $fo1 = $o5->bb1;
  ok($fo1 && ref $fo1 && $fo1->id == 2, "bb foreign object 1 - $db_type");

  $fo1 = $o5->bb2;
  ok($fo1 && ref $fo1 && $fo1->id == 4, "bb foreign object 2 - $db_type");

  $objs = 
    MySQLiteObjectManager->get_objectz(
      share_db     => 1,
      query_is_sql => 1,
      query        =>
      [
        't1.id'    => { ge => 2 },
        't1.name'  => { like => '%tt%' },
      ],
      require_objects => [ 'other_obj', 'bb1', 'bb2' ]);

  ok(ref $objs->[0]->{'other_obj'} eq 'MySQLiteOtherObject', "foreign object 2 - $db_type");
  is($objs->[0]->other_obj->k2, 2, "foreign object 3 - $db_type");

  is($objs->[0]->bb1->name, 'two', "bb foreign object 3 - $db_type");
  is($objs->[0]->bb2->name, 'four', "bb foreign object 4 - $db_type");

  $iterator =
    MySQLiteObjectManager->get_objectz_iterator(
      share_db     => 1,
      query_is_sql => 1,
      query        =>
      [
        't1.id'    => { ge => 2 },
        't1.name'  => { like => '%tt%' },
      ],
      require_objects => [ 'other_obj', 'bb1', 'bb2' ]);

  $o = $iterator->next;

  ok(ref $o->{'other_obj'} eq 'MySQLiteOtherObject', "foreign object 4 - $db_type");
  is($o->other_obj->k2, 2, "foreign object 5 - $db_type");

  is($o->bb1->name, 'two', "bb foreign object 5 - $db_type");
  is($o->bb2->name, 'four', "bb foreign object 6 - $db_type");

  # Start "one to many" tests

  ok($fo = MySQLiteNick->new(eyedee   => 1,
                             o_id => 5,
                             nick => 'none',
                             type => { name => 'nt one', t2 => { name => 'nt2 one' } },
                             alts => [ { alt => 'alt one 1' },
                                       { alt => 'alt one 2' },
                                       { alt => 'alt one 3' }, ],
                             opts => [ { opt => 'opt one 1' },
                                       { opt => 'opt one 2' } ])->save,
      "nick object save() 1 - $db_type");

  $fo = MySQLiteNick->new(eyedee   => 2,
                          o_id => 2,
                          nick => 'ntwo',
                          type => { name => 'nt two', t2 => { name => 'nt2 two' } },
                          alts => [ { alt => 'alt two 1' } ]);
  ok($fo->save, "nick object save() 2 - $db_type");

  $fo = MySQLiteNick->new(eyedee   => 3,
                          o_id => 5,
                          nick => 'nthree',
                          type => { name => 'nt three', t2 => { name => 'nt2 three' } },
                          opts => [ { opt => 'opt three 1' },  { opt => 'opt three 2' } ]);
  ok($fo->save, "nick object save() 3 - $db_type");

  $fo = MySQLiteNick->new(eyedee   => 4,
                          o_id => 2,
                          nick => 'nfour',
                          type => { name => 'nt four', t2 => { name => 'nt2 four' } });
  ok($fo->save, "nick object save() 4 - $db_type");

  $fo = MySQLiteNick->new(eyedee   => 5,
                          o_id => 5,
                          nick => 'nfive',
                          type => { name => 'nt five', t2 => { name => 'nt2 five' } });
  ok($fo->save, "nick object save() 5 - $db_type");

  $fo = MySQLiteNick->new(eyedee   => 6,
                          o_id => 5,
                          nick => 'nsix',
                          type => { name => 'nt six', t2 => { name => 'nt2 six' } });
  ok($fo->save, "nick object save() 6 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      share_db     => 1,
      with_objects => [ 'nicks' ],
      query        =>
      [
        't1.id'    => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 0,
        flag2      => 1,
        bits       => '10101',
        't2.nick'  => { like => 'n%' },
        'eyedee'   => { ne => 12345 },
        start      => '5/20/2002',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        or         => [],
        and        => [],
        save_col   => [ 1, 5, 123 ],
        #nums       => [ 4, 5, 6 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() with many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 2 - $db_type");

  ok(!defined $objs->[0]->{'status'}, "lazy main 1 - $db_type");
  is($objs->[0]->status, 'with', "lazy main 2 - $db_type");

  my $object = MySQLiteObject->new(id => $objs->[0]->id);
  $object->load(with => [ 'nicks.type' ]);
  is($object->{'status'}, undef, "lazy load(with) 1 - $db_type");

  my $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  # SQLite seems to disobey the "ORDER BY t1.id, t2.nick DESC" clause
  $nicks = [ sort { $b->nick cmp $a->nick } @$nicks ];

  is(scalar @$nicks, 4, "get_objects() with many 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 5 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 7 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks', 'bb1' ],
      query        =>
      [
        't1.id'    => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 0,
        flag2      => 1,
        bits       => '10101',
        't3.nick'  => { like => 'n%' },
        start      => '5/20/2002',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        save_col   => [ 1, 5, 123 ],
        nums       => [ 4, 5, 6 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() with many 8 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 9 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  # SQLite seems to disobey the "ORDER BY t1.id, t2.nick DESC" clause
  $nicks = [ sort { $b->nick cmp $a->nick } @$nicks ];

  is(scalar @$nicks, 4, "get_objects() with many 10 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 11 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 12 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 13 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 14 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many bb1 1 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many bb2 2 - $db_type");

  $iterator = 
    MySQLiteObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => [ 'nicks' ],
      sort_by => 't1.name');

  is(ref $iterator, 'Rose::DB::Object::Iterator', "get_objects_iterator() 1 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator many next() 1 - $db_type");
  is($o->id, 5, "iterator many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator many next() 3 - $db_type");
  is($o->id, 4, "iterator many next() 4 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator many next() 5 - $db_type");
  is($o->id, 2, "iterator many next() 6 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "iterator many sub-object 1 - $db_type");
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "iterator many sub-object 2 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "iterator many sub-object 3 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator many next() 7 - $db_type");
  is($o->id, 3, "iterator many next() 8 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator many next() 9 - $db_type");
  is($iterator->total, 4, "iterator many total() - $db_type");

  $iterator = 
    MySQLiteObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      sort_by => 't1.name',
      limit   => 2);

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator limit 2 many next() 1 - $db_type");
  is($o->id, 5, "iterator limit 2 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 2 many next() 3 - $db_type");
  is($o->id, 4, "iterator limit 2 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 2 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 2 many total() - $db_type");

  $iterator = 
    MySQLiteObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3);

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator limit 3 many next() 1 - $db_type");
  is($o->id, 5, "iterator limit 3 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 3 many next() 3 - $db_type");
  is($o->id, 4, "iterator limit 3 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 3 many next() 5 - $db_type");
  is($o->id, 2, "iterator limit 3 many next() 6 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "iterator limit 3 many sub-object 1 - $db_type");
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "iterator limit 3 many sub-object 2 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "iterator limit 3 many sub-object 3 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 3 many next() 7 - $db_type");
  is($iterator->total, 3, "iterator limit 3 many total() - $db_type");

  $objs = 
    MySQLiteObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      sort_by => 't1.name',
      limit   => 2);

  ok(ref $objs && @$objs == 2, "get_objects() limit 2 many 1 - $db_type");
  is($objs->[0]->name, 'Betty', "get_objects() limit 2 many 2 - $db_type");
  is($objs->[0]->id, 5, "get_objects() limit 2 many 3 - $db_type");

  is($objs->[1]->name, 'Bob', "get_objects() limit 2 many 4 - $db_type");
  is($objs->[1]->id, 4, "get_objects() limit 2 many 5 - $db_type");

  $objs = 
    MySQLiteObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'nicks', 'bb2' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3);

  ok(ref $objs && @$objs == 3, "get_objects() limit 3 many 1 - $db_type");
  is($objs->[0]->name, 'Betty', "get_objects() limit 3 many 2 - $db_type");
  is($objs->[0]->id, 5, "get_objects() limit 3 many 3 - $db_type");

  is($objs->[1]->name, 'Bob', "get_objects() limit 3 many 4 - $db_type");
  is($objs->[1]->id, 4, "get_objects() limit 3 many 5 - $db_type");

  is($objs->[2]->name, 'Fred', "get_objects() limit 3 many 6 - $db_type");
  is($objs->[2]->id, 2, "get_objects() limit 3 many 7 - $db_type");
  is(scalar @{$objs->[2]->{'nicks'}}, 2, 'get_objects() limit 3 many sub-object 1');
  is($objs->[2]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 3 many sub-object 2');
  is($objs->[2]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 3 many sub-object 3');

  $iterator = 
    MySQLiteObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 2,
      offset  => 1);

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 2 offset 1 many next() 1 - $db_type");
  is($o->id, 4, "iterator limit 2 offset 1 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 2 offset 1 many next() 3 - $db_type");
  is($o->id, 2, "iterator limit 2 offset 1 many next() 4 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, 'iterator limit 2 offset 1 many sub-object 1');
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', 'iterator limit 2 offset 1 many sub-object 2');
  is($o->{'nicks'}[1]{'nick'}, 'nfour', 'iterator limit 2 offset 1 many sub-object 3');

  $o = $iterator->next;
  is($o, 0, "iterator limit 2 offset 1 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 2 offset 1 many total() - $db_type");

  $iterator = 
    MySQLiteObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3,
      offset  => 2);

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 3 offset 2 many next() 1 - $db_type");
  is($o->id, 2, "iterator limit 3 offset 2 many next() 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, 'iterator limit 3 offset 2 many sub-object 1');
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', 'iterator limit 3 offset 2 many sub-object 2');
  is($o->{'nicks'}[1]{'nick'}, 'nfour', 'iterator limit 3 offset 2 many sub-object 3');

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator limit 3 offset 2 many next() 3 - $db_type");
  is($o->id, 3, "iterator limit 3 offset 2 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 3 offset 2 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 3 offset 2 many total() - $db_type");

  $objs = 
    MySQLiteObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 2,
      offset  => 1);

  ok(ref $objs && @$objs == 2, "get_objects() limit 2 offset 1 many 1 - $db_type");
  is($objs->[0]->name, 'Bob', "get_objects() limit 2 offset 1 many 2 - $db_type");
  is($objs->[0]->id, 4, "get_objects() limit 2 offset 1 many 3 - $db_type");

  is($objs->[1]->name, 'Fred', "get_objects() limit 2 offset 1 many 4 - $db_type");
  is($objs->[1]->id, 2, "get_objects() limit 2 offset 1 many 5 - $db_type");
  is(scalar @{$objs->[1]->{'nicks'}}, 2, 'get_objects() limit 2 offset 1 many sub-object 1');
  is($objs->[1]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 2 offset 1 many sub-object 2');
  is($objs->[1]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 2 offset 1 many sub-object 3');

  $objs = 
    MySQLiteObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'nicks', 'bb2' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3,
      offset  => 2);

  ok(ref $objs && @$objs == 2, "get_objects() limit 3 offset 2 many 1 - $db_type");

  is($objs->[0]->name, 'Fred', "get_objects() limit 3 offset 2 many 2 - $db_type");
  is($objs->[0]->id, 2, "get_objects() limit 3 offset 2 many 3 - $db_type");
  is(scalar @{$objs->[0]->{'nicks'}}, 2, 'get_objects() limit 3 offset 2 many sub-object 1');
  is($objs->[0]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 3 offset 2 many sub-object 2');
  is($objs->[0]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 3 offset 2 many sub-object 3');

  is($objs->[1]->name, 'Sue', "get_objects() limit 3 offset 2 many 4 - $db_type");
  is($objs->[1]->id, 3, "get_objects() limit 3 offset 2 many 5 - $db_type");

  my $o6 = $o2->clone;
  $o6->id(60);
  $o6->fkone(undef);
  $o6->fk2(undef);
  $o6->fk3(undef);
  $o6->b1(undef);
  $o6->b2(2);
  $o6->name('Ted');

  ok($o6->save, "object save() 8 - $db_type");

  my $o7 = $o2->clone;
  $o7->id(70);
  $o7->b1(3);
  $o7->b2(undef);
  $o7->name('Joe');

  ok($o7->save, "object save() 9 - $db_type");

  my $o8 = $o2->clone;
  $o8->id(80);
  $o8->b1(undef);
  $o8->b2(undef);
  $o8->name('Pete');

  ok($o8->save, "object save() 10 - $db_type");

  $fo = MySQLiteNick->new(eyedee   => 7,
                      o_id => 60,
                      nick => 'nseven');

  ok($fo->save, "nick object save() 7 - $db_type");

  $fo = MySQLiteNick->new(eyedee   => 8,
                      o_id => 60,
                      nick => 'neight');

  ok($fo->save, "nick object save() 8 - $db_type");

  $fo = MySQLiteNick->new(eyedee   => 9,
                      o_id => 60,
                      nick => 'neight');

  ok($fo->save, "nick object save() 8 - $db_type");

  $fo = MySQLiteNick2->new(id    => 1,
                       o_id  => 5,
                       nick2 => 'n2one');

  ok($fo->save, "nick2 object save() 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      query        => [ '!t1.id' => 5 ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 15 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 0, "get_objects() with many 16 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      object_class => 'MySQLiteObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is($count, 1, "get_objects_count() require 1 - $db_type"); 

  #local $Rose::DB::Object::Manager::Debug = 1;  
  #$DB::single = 1;

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      object_class => 'MySQLiteObject',
      share_db     => 1,
      require_objects => [ 'bb2' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is($count, 2, "get_objects_count() require 2 - $db_type"); 

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 17 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 18 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many 19 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  # SQLite seems to disobey the "ORDER BY t1.id, t2.nick DESC" clause
  $nicks = [ sort { $b->nick cmp $a->nick } @$nicks ];

  is(scalar @$nicks, 4, "get_objects() with many 20 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 21 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 22 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 23 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 24 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      share_db     => 1,
      require_objects => [ 'bb1', 'bb2' ],
      with_objects    => [ 'nicks2', 'nicks' ],
      multi_many_ok   => 1,
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with multi many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with multi many 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with multi many 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  # SQLite seems to disobey the "ORDER BY t1.id, t2.nick DESC" clause
  $nicks = [ sort { $b->nick cmp $a->nick } @$nicks ];

  is(scalar @$nicks, 4, "get_objects() with multi many 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with multi many 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with multi many 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with multi many 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with multi many 8 - $db_type");

  is($objs->[0]->{'nicks2'}[0]{'nick2'}, 'n2one', "get_objects() with multi many 9 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MySQLiteObject',
      share_db     => 1,
      require_objects => [ 'bb1', 'bb2' ],
      with_objects    => [ 'nicks2', 'nicks' ],
      multi_many_ok   => 1,
      query        => [ ],
      sort_by => 't1.id');

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator with and require 1 - $db_type");
  is($o->id, 5, "iterator with and require 2 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  # SQLite seems to disobey the "ORDER BY t1.id, t2.nick DESC" clause
  $nicks = [ sort { $b->nick cmp $a->nick } @$nicks ];

  is(scalar @$nicks, 4, "iterator with and require 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "iterator with and require 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "iterator with and require 5 - $db_type");
  is($nicks->[2]->nick, 'none', "iterator with and require 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "iterator with and require 7 - $db_type");

  is($o->{'nicks2'}[0]{'nick2'}, 'n2one', "iterator with and require 8 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator with and require 9 - $db_type");
  is($iterator->total, 1, "iterator with and require 10 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks', 'bb1' ],
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 25 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 8, "get_objects() with many 26 - $db_type");

  my $ids = join(',', map { $_->id } @$objs);

  is($ids, '1,2,3,4,5,60,70,80', "get_objects() with many 27 - $db_type");

  $nicks = $objs->[4]->{'nicks'}; # make sure this isn't hitting the db

  # SQLite seems to disobey the "ORDER BY t1.id, t2.nick DESC" clause
  $nicks = [ sort { $b->nick cmp $a->nick } @$nicks ];

  is(scalar @$nicks, 4, "get_objects() with many 28 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 29 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 30 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 31 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 32 - $db_type");

  is($objs->[6]->{'bb1'}->{'name'}, 'three', "get_objects() with many 33 - $db_type");
  ok(!defined $objs->[6]->{'bb2'}, "get_objects() with many 34 - $db_type");
  ok(!defined $objs->[6]->{'nicks'}, "get_objects() with many 35 - $db_type");

  ok(!defined $objs->[7]->{'bb1'}, "get_objects() with many 36 - $db_type");
  ok(!defined $objs->[7]->{'bb1'}, "get_objects() with many 37 - $db_type");
  ok(!defined $objs->[7]->{'nicks'}, "get_objects() with many 38 - $db_type");

  $fo = MySQLiteNick->new(eyedee => 7);
  ok($fo->delete, "with many clean-up 1 - $db_type");

  $fo = MySQLiteNick->new(eyedee => 8);
  ok($fo->delete, "with many clean-up 2 - $db_type");

  $fo = MySQLiteNick->new(eyedee => 9);
  ok($fo->delete, "with many clean-up 3 - $db_type");

  ok($o6->delete, "with many clean-up 4 - $db_type");
  ok($o7->delete, "with many clean-up 5 - $db_type");
  ok($o8->delete, "with many clean-up 6 - $db_type");

  $fo = MySQLiteNick2->new(id => 1);
  ok($fo->delete, "with many clean-up 7 - $db_type");

  # End "one to many" tests

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      share_db     => 1,
      query        =>
      [
        id         => { ge => 1 },
        name       => 'John',  
        flag       => 1,
        flag2      => 0,
        status     => 'active',
        bits       => '1',
        start      => '1/2/2001',
        '!start'   => { gt => DateTime->new(year  => '2005', 
                                            month => 1,
                                            day   => 1) },
        '!rose_db_object_test.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 2,
                              day   => 2)
        },

        '!t1.start' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 3,
                              day   => 3)
        },

        save_col   => [ 1, 5 ],
        nums       => [ 1, 2, 3 ],
        fk1        => 2,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '3/30/2004 12:34:56 pm'
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() 7 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 8 - $db_type");

  $objs = 
    MySQLiteObjectManager->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        k1         => { lt => 900 },
        or         => [ k1 => { ne => 99 }, k1 => 100 ],
        or         => [ and => [ id => { ne => 123 }, id => { lt => 100  } ],
                        and => [ id => { ne => 456 }, id => { lt => 300  } ] ],
        '!k2'      => { gt => 999 },
        '!t2.name' => 'z',
        start      => { lt => DateTime->new(year => '2005', month => 1, day => 1) },
        '!start'   => { gt => DateTime->new(year => '2005', month => 1, day => 1) },
        'rose_db_object_test.name'   => { like => '%tt%' },
        '!rose_db_object_other.name' => 'q',
        '!rose_db_object_other.name' => [ 'x', 'y' ],
      ],
      require_objects => [ 'other_obj' ]);

  ok(ref $objs->[0]->{'other_obj'} eq 'MySQLiteOtherObject', "foreign object 6 - $db_type");
  is($objs->[0]->other_obj->k2, 2, "foreign object 7 - $db_type");

  # Test limit with offset

  foreach my $id (6 .. 20)
  {
    my $o = $o5->clone;
    $o->id($id);
    $o->name("Clone $id");

    ok($o->save, "object save() clone $id - $db_type");
  }

  $objs = 
    MySQLiteObjectManager->get_objectz(
      object_class => 'MySQLiteObject',
      sort_by      => 'id DESC',
      limit        => 2,
      offset       => 8);

  ok(ref $objs eq 'ARRAY' && @$objs == 2 && 
     $objs->[0]->id == 12 && $objs->[1]->id == 11,
     "get_objects() with offset - $db_type");

  $objs = 
    MySQLiteObjectManager->get_objectz(
      object_class => 'MySQLiteObject',
      sort_by      => 'id DESC',
      require_objects => [ 'other_obj' ],
      limit        => 2,
      offset       => 8);

  ok(ref $objs eq 'ARRAY' && @$objs == 2 && 
     $objs->[0]->id == 12 && $objs->[1]->id == 11,
     "get_objects() with objects and offset - $db_type");

  $iterator = 
    MySQLiteObjectManager->get_objectz_iterator(
      object_class => 'MySQLiteObject',
      sort_by      => 'id DESC',
      limit        => 2,
      offset       => 8);

  $o = $iterator->next;
  is($o->id, 12, "get_objects_iterator() with offset 1 - $db_type");

  $o = $iterator->next;
  is($o->id, 11, "get_objects_iterator() with offset 2 - $db_type");

  is($iterator->next, 0, "get_objects_iterator() with offset 3 - $db_type");

  eval
  {
    $objs = 
      MySQLiteObjectManager->get_objectz(
        object_class => 'MySQLiteObject',
        sort_by      => 'id DESC',
        offset       => 8)
  };

  ok($@ =~ /invalid without a limit/, "get_objects() missing offset - $db_type");

  eval
  {
    $iterator = 
      MySQLiteObjectManager->get_objectz_iterator(
        object_class => 'MySQLiteObject',
        sort_by      => 'id DESC',
        offset       => 8);
  };

  ok($@ =~ /invalid without a limit/, "get_objects_iterator() missing offset - $db_type");

  # Start *_sql comparison tests

  $o6->fk2(99);
  $o6->fk3(99);
  $o6->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ 'fk2' => { eq_sql => 'fk3' } ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq_sql 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq_sql 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq_sql 3 - $db_type");

  # End *_sql comparison tests

  # Start IN NULL tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => [ undef, 60 ], '!id' => \'id + 1' ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() in null 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() in null 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() in null 3 - $db_type");

  # End IN NULL tests

  # Start scalar ref tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ 'fk2' => \'fk3' ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq ref 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq ref 3 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      #query        => [ 'fk2' => [ \'fk3' ] ], #'
      query        => [ 'fk2' => \'fk3' ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 4 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq ref 5 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq ref 6 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ 'fk2' => { ne => \'fk3' } ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 7 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 16, "get_objects() eq ref 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ 'fk2' => { ne => [ \'fk3' ] } ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 9 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 16, "get_objects() eq ref 10 - $db_type");

  # End scalar ref tests

  # Start "many to many" tests

  $fo = MySQLiteColor->new(id => 1, name => 'Red');
  $fo->save;

  $fo = MySQLiteColor->new(id => 2, name => 'Green');
  $fo->save;

  $fo = MySQLiteColor->new(id => 3, name => 'Blue');
  $fo->save;

  $fo = MySQLiteColorMap->new(id => 1, object_id => $o2->id, color_id => 1);
  $fo->save;

  $fo = MySQLiteColorMap->new(id => 2, object_id => $o2->id, color_id => 3);
  $fo->save;

  $o2->b1(4);
  $o2->b1(2);
  $o2->fkone(2);
  $o2->fk2(3);
  $o2->fk3(4);
  $o2->save;

  my @colors = $o2->colors;
  ok(@colors == 2 && $colors[0]->name eq 'Red' &&
     $colors[1]->name eq 'Blue', "Fetch many to many 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MySQLiteObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_record',
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  test_memory_cycle_ok($objs, "get_objects() with many to many cycle - $db_type");

  is(ref $objs, 'ARRAY', "get_objects() with many to many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many 4 - $db_type");
  is($objs->[2]->id, 1, "get_objects() with many to many 5 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many 12 - $db_type");

  my $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many 15 - $db_type");

  is($colors->[0]->map_record->color_id, $colors->[0]->id, "map_record 1 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 2 - $db_type");
  is($colors->[1]->map_record->color_id, $colors->[1]->id, "map_record 3 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 4 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MySQLiteObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_record',
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $objs = [];

  while(my $obj = $iterator->next)
  {
    push(@$objs, $obj);
  }

  is(ref $objs, 'ARRAY', "get_objects_iterator() with many to many map record 1 - $db_type");
  is(scalar @$objs, 3, "get_objects_iterator() with many to many map record  2 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  is($colors->[0]->map_record->color_id, $colors->[0]->id, "map_record 5 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 6 - $db_type");
  is($colors->[1]->map_record->color_id, $colors->[1]->id, "map_record 7 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MySQLiteObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_rec',
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many 2 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  is($colors->[0]->map_rec->color_id, $colors->[0]->id, "map_rec 1 - $db_type");
  is($colors->[0]->map_rec->object_id, $objs->[1]->id, "map_rec 2 - $db_type");
  is($colors->[1]->map_rec->color_id, $colors->[1]->id, "map_rec 3 - $db_type");
  is($colors->[0]->map_rec->object_id, $objs->[1]->id, "map_rec 4 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MySQLiteObject',
      share_db      => 1,
      with_objects  => [ 'bb1', 'nicks', 'other_obj', 'colors', 'bb2' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many (reorder) 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many (reorder) 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many (reorder) 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many (reorder) 4 - $db_type");
  is($objs->[2]->id, 1, "get_objects() with many to many (reorder) 5 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many (reorder) 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many (reorder) 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many (reorder) 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many (reorder) 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many (reorder) 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many (reorder) 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many (reorder) 12 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many (reorder) 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many (reorder) 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many (reorder) 15 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MySQLiteObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many require with 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 2, "get_objects() with many to many require with 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many require with 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many require with 4 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many require with 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many require with 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many require with 12 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many require with 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many require with 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many require with 15 - $db_type");

  $fo1 = $objs->[1]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'two', "get_objects() with many to many require with 16 - $db_type");

  $fo1 = $objs->[0]->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 1', "get_objects() with many to many require with 17 - $db_type");

  $fo1 = $objs->[1]->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 2', "get_objects() with many to many require with 18 - $db_type");

  ok(!defined $objs->[0]->{'colors'}, "get_objects() with many to many require with 19 - $db_type");
  ok(!defined $objs->[1]->{'bb2'}, "get_objects() with many to many require with 20 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MySQLiteObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many 1 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many 2 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many 5 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many 7 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many 8 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many 9 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many 10 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many 11 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many 12 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 13 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 14 - $db_type");

  $o = $iterator->next;
  is($o->name, 'John', "get_objects_iterator() with many to many 15 - $db_type");
  is($o->id, 1, "get_objects_iterator() with many to many 16 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many 17 - $db_type");
  is($iterator->total, 3, "get_objects_iterator() with many to many 18 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MySQLiteObject',
      share_db      => 1,
      with_objects  => [ 'bb1', 'nicks', 'other_obj', 'colors', 'bb2' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many 19 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many 20 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many 21 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many 22 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many 23 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many 24 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many 25 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many 26 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many 27 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many 28 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many 29 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many 30 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 31 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 32 - $db_type");

  $o = $iterator->next;
  is($o->name, 'John', "get_objects_iterator() with many to many 33 - $db_type");
  is($o->id, 1, "get_objects_iterator() with many to many 34 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many 35 - $db_type");
  is($iterator->total, 3, "get_objects_iterator() with many to many 36 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MySQLiteObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many require 1 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many require 2 - $db_type");

  $fo1 = $o->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 1', "get_objects_iterator() with many to many require 3 - $db_type");

  ok(!defined $o->{'colors'}, "get_objects_iterator() with many to many require 4 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many require 5 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many require 6 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many require 7 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many require 8 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many require 9 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many require 10 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many require 11 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many require 12 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many require 13 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many require 16 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'two', "get_objects_iterator() with many to many require 17 - $db_type");

  $fo1 = $o->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 2', "get_objects_iterator() with many to many require 18 - $db_type");

  ok(!defined $o->{'bb2'}, "get_objects_iterator() with many to many require 19 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many require 20 - $db_type");
  is($iterator->total, 2, "get_objects_iterator() with many to many require 21 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MySQLiteObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name',
      limit           => 1,
      offset          => 5);

  ok(!$iterator->next, "get_objects_iterator() with many to many require 22 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MySQLiteObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name',
      limit           => 1,
      offset          => 5);

  ok(@$objs == 0, "get_objects_iterator() with many to many require 23 - $db_type");

  # End "many to many" tests

  # Start multi-require tests

  $fo = MySQLiteColorMap->new(id => 3, object_id => 5, color_id => 2);
  $fo->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MySQLiteObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'colors', 'other_obj' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 2, "get_objects() multi many require 1 - $db_type");

  is($objs->[0]->id, 5, "get_objects() multi many require 2 - $db_type");
  is($objs->[1]->id, 2, "get_objects() multi many require 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() multi many require 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() multi many require 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() multi many require 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() multi many require 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() multi many require 8 - $db_type");

  $colors = $objs->[0]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 1, "get_objects() multi many require 9 - $db_type");
  ok($colors->[0]->id == 2 && $colors->[0]->name eq 'Green', "get_objects() multi many require 10 - $db_type");

  $nicks = $objs->[1]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 2, "get_objects() multi many require 11 - $db_type");
  is($nicks->[0]->nick, 'ntwo', "get_objects() multi many require 12 - $db_type");
  is($nicks->[1]->nick, 'nfour', "get_objects() multi many require 13 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() multi many require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() multi many require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[1]->name eq 'Blue', "get_objects() multi many require 16 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MySQLiteObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'colors', 'other_obj' ],
      with_objects    => [ 'bb2' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 2, "get_objects() multi many with require 1 - $db_type");

  is($objs->[0]->id, 5, "get_objects() multi many with require 2 - $db_type");
  is($objs->[1]->id, 2, "get_objects() multi many with require 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() multi many with require 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() multi many with require 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() multi many with require 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() multi many with require 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() multi many with require 8 - $db_type");

  $colors = $objs->[0]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 1, "get_objects() multi many with require 9 - $db_type");
  ok($colors->[0]->id == 2 && $colors->[0]->name eq 'Green', "get_objects() multi many with require 10 - $db_type");

  $nicks = $objs->[1]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 2, "get_objects() multi many with require 11 - $db_type");
  is($nicks->[0]->nick, 'ntwo', "get_objects() multi many with require 12 - $db_type");
  is($nicks->[1]->nick, 'nfour', "get_objects() multi many with require 13 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() multi many with require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() multi many with require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[1]->name eq 'Blue', "get_objects() multi many with require 16 - $db_type");

  is($objs->[0]->{'bb2'}{'name'}, 'four', "get_objects() multi many with require 17 - $db_type");
  ok(!defined $objs->[1]->{'bb2'}{'name'}, "get_objects() multi many with require 18 - $db_type");

  MySQLiteNick->new(eyedee => 7, o_id => 10,  nick => 'nseven')->save;
  MySQLiteNick->new(eyedee => 8, o_id => 11,  nick => 'neight')->save;
  MySQLiteNick->new(eyedee => 9, o_id => 12,  nick => 'nnine')->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MySQLiteObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'bb1' ],
      with_objects    => [ 'colors' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 5, "get_objects() multi many with require map 1 - $db_type");

  is($objs->[0]->id,  5, "get_objects() multi many with require map 2 - $db_type");
  is($objs->[1]->id, 10, "get_objects() multi many with require map 3 - $db_type");
  is($objs->[2]->id, 11, "get_objects() multi many with require map 4 - $db_type");
  is($objs->[3]->id, 12, "get_objects() multi many with require map 5 - $db_type");
  is($objs->[4]->id,  2, "get_objects() multi many with require map 6 - $db_type");

  # End multi-require tests

  # Start distinct tests

  my $i = 0;

  foreach my $distinct (1, [ 't1' ], [ 'rose_db_object_test' ])
  {
    $i++;

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MySQLiteObject',
        distinct        => $distinct,
        share_db        => 1,
        require_objects => [ 'nicks', 'colors', 'other_obj' ],
        multi_many_ok   => 1,
        sort_by         => 't1.name');

    is(scalar @$objs, 2, "get_objects() distinct multi many require $i.1 - $db_type");

    is($objs->[0]->id, 5, "get_objects() distinct multi many require $i.2 - $db_type");
    is($objs->[1]->id, 2, "get_objects() distinct multi many require $i.3 - $db_type");

    ok(!defined $objs->[0]->{'nicks'}, "get_objects() distinct multi many require $i.4 - $db_type");
    ok(!defined $objs->[0]->{'colors'}, "get_objects() distinct multi many require $i.5 - $db_type");

    ok(!defined $objs->[1]->{'nicks'}, "get_objects() distinct multi many require $i.6 - $db_type");
    ok(!defined $objs->[1]->{'colors'}, "get_objects() distinct multi many require $i.7 - $db_type");
  }

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  foreach my $distinct ([ 't2' ], [ 'rose_db_object_nicks' ], [ 'nicks' ])
  {
    $i++;

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MySQLiteObject',
        distinct        => $distinct,
        share_db        => 1,
        require_objects => [ 'nicks', 'colors', 'other_obj' ],
        multi_many_ok   => 1,
        nonlazy         => 1,
        sort_by         => 't1.name');

    is(scalar @$objs, 2, "get_objects() distinct multi many require $i.1 - $db_type");

    is($objs->[0]->id, 5, "get_objects() distinct multi many require $i.2 - $db_type");
    is($objs->[1]->id, 2, "get_objects() distinct multi many require $i.3 - $db_type");

    ok(defined $objs->[0]->{'nicks'}, "get_objects() distinct multi many require $i.4 - $db_type");
    ok(!defined $objs->[0]->{'colors'}, "get_objects() distinct multi many require $i.5 - $db_type");

    ok(defined $objs->[1]->{'nicks'}, "get_objects() distinct multi many require $i.6 - $db_type");
    ok(!defined $objs->[1]->{'colors'}, "get_objects() distinct multi many require $i.7 - $db_type");
  }

  # End distinct tests

  # Start pager tests

  is(Rose::DB::Object::Manager->default_objects_per_page, 20, 'default_objects_per_page 1');

  Rose::DB::Object::Manager->default_objects_per_page(3);

  my $per_page = Rose::DB::Object::Manager->default_objects_per_page;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 1,
      per_page     => 3);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 1.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 2.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => 3);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 3.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => -1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 4.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => -1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 5.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => undef);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 6.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => undef);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 7.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id');

  ok(scalar @$objs > 3, "pager 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 2,
      per_page     => 3);

  $i = 0;

  for(4 .. 6)
  {
    is($objs->[$i++]->id, $_, "pager 9.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 3,
      per_page     => 3);

  $i = 0;

  for(7 .. 9)
  {
    is($objs->[$i++]->id, $_, "pager 10.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 4,
      per_page     => 3);

  $i = 0;

  for(10 .. 11)
  {
    is($objs->[$i++]->id, $_, "pager 11.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 5,
      per_page     => 3);

  ok(scalar @$objs == 0, "pager 12 - $db_type");

  Rose::DB::Object::Manager->default_objects_per_page(20);

  # End pager tests

  # Start get_objects_from_sql tests

  eval
  {
    $objs = 
      MySQLiteObjectManager->get_objects_from_sql(
        db  => MySQLiteObject->init_db,
        object_class => 'MySQLiteObject',
      sql => <<"EOF");
SELECT id, id as nonesuch FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF
  };

  like($@, qr/method "nonesuch"/, "get_objects_from_sql error message - $db_type");

  $objs = 
    MySQLiteObjectManager->get_objects_from_sql(
      db  => MySQLiteObject->init_db,
      object_class => 'MySQLiteObject',
      prepare_cached => 1,
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  ok(scalar @$objs == 19, "get_objects_from_sql 1 - $db_type");
  is($objs->[18]->id, 1, "get_objects_from_sql 2 - $db_type");
  is($objs->[18]->save_col, 5, "get_objects_from_sql 3 - $db_type");
  is($objs->[18]->name, 'John', "get_objects_from_sql 4 - $db_type");

  $iterator = 
    MySQLiteObjectManager->get_objects_iterator_from_sql(
      db  => MySQLiteObject->init_db,
      object_class => 'MySQLiteObject',
      prepare_cached => 1,
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  for(0 .. 17) { $iterator->next }

  $o = $iterator->next;
  is($o->id, 1, "get_objects_iterator_from_sql 1 - $db_type");
  is($o->save_col, 5, "get_objects_iterator_from_sql 2 - $db_type");
  is($o->name, 'John', "get_objects_iterator_from_sql 3 - $db_type");
  ok(!$iterator->next,  "get_objects_iterator_from_sql 4 - $db_type");

  $objs = MySQLiteObjectManager->get_objects_from_sql(<<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  ok(scalar @$objs == 19, "get_objects_from_sql 5 - $db_type");
  is($objs->[18]->id, 1, "get_objects_from_sql 6 - $db_type");
  is($objs->[18]->save_col, 5, "get_objects_from_sql 7 - $db_type");
  is($objs->[18]->name, 'John', "get_objects_from_sql 8 - $db_type");

  $objs = 
    MySQLiteObjectManager->get_objects_from_sql(
      args => [ 19 ],
      sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id > ? ORDER BY id DESC
EOF

  ok(scalar @$objs == 2, "get_objects_from_sql 9 - $db_type");
  is($objs->[0]->id, 60, "get_objects_from_sql 10 - $db_type");

  my $method = 
    MySQLiteObjectManager->make_manager_method_from_sql(
      get_em => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  $objs = MySQLiteObjectManager->get_em;

  ok(scalar @$objs == 19, "make_manager_method_from_sql 1 - $db_type");
  is($objs->[17]->id, 3, "make_manager_method_from_sql 2 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql 3 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql 4 - $db_type");  

  $objs = $method->('MySQLiteObjectManager');

  ok(scalar @$objs == 19, "make_manager_method_from_sql 5 - $db_type");
  is($objs->[17]->id, 3, "make_manager_method_from_sql 6 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql 7 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql 8 - $db_type");  

  $method = 
    MySQLiteObjectManager->make_manager_method_from_sql(
      iterator => 1, method => 'iter_em', sql => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

  $iterator = MySQLiteObjectManager->iter_em;

  for(0 .. 16) { $iterator->next }

  $o = $iterator->next;
  is($objs->[17]->id, 3, "make_manager_method_from_sql iterator 1 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql iterator 2 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql iterator 3 - $db_type");  

  $iterator = $method->('MySQLiteObjectManager');

  for(0 .. 16) { $iterator->next }

  $o = $iterator->next;
  is($objs->[17]->id, 3, "make_manager_method_from_sql iterator 4 - $db_type");
  is($objs->[17]->extra, 7, "make_manager_method_from_sql iterator 5 - $db_type");
  is($objs->[17]->name, 'Sue', "make_manager_method_from_sql iterator 6 - $db_type");   

  $method = 
    MySQLiteObjectManager->make_manager_method_from_sql(
      get_more => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE id > ? ORDER BY id DESC
EOF

  $objs = MySQLiteObjectManager->get_more(18);
  ok(scalar @$objs == 3, "make_manager_method_from_sql 9 - $db_type");
  is($objs->[2]->id, 19, "make_manager_method_from_sql 10 - $db_type");

  $method = 
    MySQLiteObjectManager->make_manager_method_from_sql(
      method => 'get_more_np',
      params => [ qw(id name) ],
      sql    => <<"EOF");
SELECT *, save + fk1 AS extra FROM rose_db_object_test WHERE 
id > ? AND name != ? ORDER BY id DESC
EOF

  $objs = MySQLiteObjectManager->get_more_np(name => 'Nonesuch', id => 18);
  ok(scalar @$objs == 3, "make_manager_method_from_sql 11 - $db_type");
  is($objs->[2]->id, 19, "make_manager_method_from_sql 12 - $db_type");

  # End get_objects_from_sql tests

  # Start tough order tests

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MySQLiteObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1);

  ok(@$objs == 5, "tough order 1 - $db_type");
  is($objs->[0]->id, 2, "tough order 2 - $db_type");
  is($objs->[1]->id, 5, "tough order 3 - $db_type");
  is($objs->[2]->id, 10, "tough order 4 - $db_type");
  is($objs->[3]->id, 11, "tough order 5 - $db_type");
  is($objs->[4]->id, 12, "tough order 6 - $db_type");

  $objs->[0]{'nicks'} = [ sort { $b->{'nick'} cmp $a->{'nick'} } @{$objs->[0]{'nicks'}} ];

  is($objs->[0]{'nicks'}[0]{'nick'}, 'ntwo', "tough order 7 - $db_type");
  is($objs->[0]{'nicks'}[1]{'nick'}, 'nfour', "tough order 8 - $db_type");

  $objs->[1]{'nicks'} = [ sort { $b->{'nick'} cmp $a->{'nick'} } @{$objs->[1]{'nicks'}} ];

  is($objs->[1]{'nicks'}[0]{'nick'}, 'nthree', "tough order 9 - $db_type");
  is($objs->[1]{'nicks'}[1]{'nick'}, 'nsix', "tough order 10 - $db_type");
  is($objs->[1]{'nicks'}[2]{'nick'}, 'none', "tough order 11 - $db_type");
  is($objs->[1]{'nicks'}[3]{'nick'}, 'nfive', "tough order 12 - $db_type");

  is($objs->[2]{'nicks'}[0]{'nick'}, 'nseven', "tough order 13 - $db_type");

  is($objs->[3]{'nicks'}[0]{'nick'}, 'neight', "tough order 14 - $db_type");

  is($objs->[4]{'nicks'}[0]{'nick'}, 'nnine', "tough order 15 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MySQLiteObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1,
      sort_by         => 'name');

  ok(@$objs == 5, "tough order 16 - $db_type");
  is($objs->[0]->id, 5, "tough order 17 - $db_type");
  is($objs->[1]->id, 10, "tough order 18 - $db_type");
  is($objs->[2]->id, 11, "tough order 19 - $db_type");
  is($objs->[3]->id, 12, "tough order 20 - $db_type");
  is($objs->[4]->id, 2, "tough order 21 - $db_type");

  is($objs->[0]{'nicks'}[0]{'nick'}, 'nthree', "tough order 22 - $db_type");
  is($objs->[0]{'nicks'}[1]{'nick'}, 'nsix', "tough order 23 - $db_type");
  is($objs->[0]{'nicks'}[2]{'nick'}, 'none', "tough order 24 - $db_type");
  is($objs->[0]{'nicks'}[3]{'nick'}, 'nfive', "tough order 25 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 4, "tough order 26 - $db_type");

  is($objs->[1]{'nicks'}[0]{'nick'}, 'nseven', "tough order 27 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 1, "tough order 28 - $db_type");

  is($objs->[2]{'nicks'}[0]{'nick'}, 'neight', "tough order 29 - $db_type");
  is(scalar @{$objs->[2]{'nicks'}}, 1, "tough order 30 - $db_type");

  is($objs->[3]{'nicks'}[0]{'nick'}, 'nnine', "tough order 31 - $db_type");
  is(scalar @{$objs->[3]{'nicks'}}, 1, "tough order 32 - $db_type");

  is($objs->[4]{'nicks'}[0]{'nick'}, 'ntwo', "tough order 33 - $db_type");
  is($objs->[4]{'nicks'}[1]{'nick'}, 'nfour', "tough order 34 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 2, "tough order 35 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MySQLiteObject',
      require_objects => [ 'nicks' ],
      nonlazy         => 1,
      sort_by         => 'name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nthree', "tough order 36 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nsix', "tough order 37 - $db_type");
  is($o->{'nicks'}[2]{'nick'}, 'none', "tough order 38 - $db_type");
  is($o->{'nicks'}[3]{'nick'}, 'nfive', "tough order 39 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "tough order 40 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nseven', "tough order 41 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 42 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'neight', "tough order 43 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 44 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'nnine', "tough order 45 - $db_type");
  is(scalar @{$o->{'nicks'}}, 1, "tough order 46 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "tough order 47 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "tough order 48 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "tough order 49 - $db_type");

  ok(!$iterator->next, "tough order 50 - $db_type");
  is($iterator->total, 5, "tough order 51 - $db_type");

  # End tough order tests

  # Start deep join tests

  eval 
  { 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      require_objects => [ 'nicks.type' ],
      with_objects    => [ 'nicks.type' ]);
  };

  ok($@, "deep join conflict 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      require_objects => [ 'nicks.type', 'nicks.type', 'nicks' ],
      with_objects    => [ 'nicks.type.t2', 'nicks.alts' ],
      multi_many_ok   => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'type.name');

  ok(@$objs == 2, "deep join 1 - $db_type");
  is($objs->[0]->id, 2, "deep join 2 - $db_type");
  is($objs->[1]->id, 5, "deep join 3 - $db_type");

  is($objs->[0]{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join 4 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join 5 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 2, "deep join 6 - $db_type");

  is($objs->[1]{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join 7 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join 8 - $db_type");
  is($objs->[1]{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join 9 - $db_type");
  is($objs->[1]{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join 10 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 4, "deep join 11 - $db_type");

  is($objs->[0]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join 12 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join 13 - $db_type");

  is($objs->[0]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join 14 - $db_type");

  $objs->[1]{'nicks'}[1]{'alts'} = 
    [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[1]{'nicks'}[1]{'alts'}} ];
  is($objs->[1]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join 15 - $db_type");
  is($objs->[1]{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join 16 - $db_type");
  is($objs->[1]{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join 17 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[1]{'alts'}}, 3, "deep join 18 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      with_objects => [ 'nicks.type' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 21, "deep join with 1 - $db_type");
  is($objs->[0]->id, 1, "deep join with 2 - $db_type");
  is($objs->[1]->id, 2, "deep join with 3 - $db_type");
  is($objs->[2]->id, 3, "deep join with 4 - $db_type");
  is($objs->[16]->id, 17, "deep join with 5 - $db_type");

  SORT:
  {
    $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  }

  is($objs->[1]{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join with 6 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join with 7 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 2, "deep join with 8 - $db_type");

  SORT:
  {
    $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
  }

  is($objs->[4]{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join with 9 - $db_type");
  is($objs->[4]{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join with 10 - $db_type");
  is($objs->[4]{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join with 11 - $db_type");
  is($objs->[4]{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join with 12 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 4, "deep join with 13 - $db_type");

  is(scalar @{$objs->[0]{'nicks'} ||= []}, 0, "deep join with 14 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MySQLiteObject',
      require_objects => [ 'nicks.type', 'nicks.type', 'nicks' ],
      with_objects    => [ 'nicks.type.t2', 'nicks.alts' ],
      multi_many_ok   => 1,
      query           => [ 'id' => [ 2, 5 ] ],
      sort_by         => 'type.name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator 3 - $db_type");

  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join 3.1 - $db_type");

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator 3.1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator 3.2 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator 8 - $db_type");

  $o->{'nicks'}[1]{'alts'} = 
    [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join iterator 9 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join iterator 10 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join iterator 11 - $db_type");
  is(scalar @{$o->{'nicks'}[1]{'alts'}}, 3, "deep join iterator 12 - $db_type");

  ok(!$iterator->next, "deep join iterator 13 - $db_type");
  is($iterator->total, 2, "deep join iterator 14 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MySQLiteObject',
      with_objects => [ 'nicks.type' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  $o = $iterator->next;
  is($o->id, 1, "deep join with with iterator 1 - $db_type");

  $o = $iterator->next;

  SORT:
  {
    $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  }

  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join with with iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join with iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join with iterator 3 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  SORT:
  {
    $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  }

  is($o->{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join with iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join with iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join with iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join with iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join with iterator 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join iterator 9 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      require_objects => [ 'nicks.type.t2' ],
      query        => [ 'id' => [ 2, 5 ] ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 2, "deep join three-level 1 - $db_type");
  is($objs->[0]->id, 2, "deep join three-level 2 - $db_type");
  is($objs->[1]->id, 5, "deep join three-level 3 - $db_type");

  SORT:
  {
    $objs->[0]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[0]{'nicks'}} ];
  }

  is($objs->[0]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join three-level 4 - $db_type");
  is($objs->[0]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join three-level 5 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}}, 2, "deep join three-level 6 - $db_type");

  SORT:
  {
    $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  }

  is($objs->[1]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join three-level 7 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join three-level 8 - $db_type");
  is($objs->[1]{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join three-level 9 - $db_type");
  is($objs->[1]{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join three-level 10 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 4, "deep join three-level 11 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      with_objects => [ 'nicks.type.t2' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  ok(@$objs == 21, "deep join three-level 1 - $db_type");
  is($objs->[0]->id, 1, "deep join three-level 2 - $db_type");
  is($objs->[1]->id, 2, "deep join three-level 3 - $db_type");
  is($objs->[4]->id, 5, "deep join three-level 4 - $db_type");
  is($objs->[20]->id, 60, "deep join three-level 5 - $db_type");

  SORT:
  {
    $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
  }

  is($objs->[1]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join three-level 6 - $db_type");
  is($objs->[1]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join three-level 7 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}}, 2, "deep join three-level 8 - $db_type");

  SORT:
  {
    $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
  }

  is($objs->[4]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join three-level 9 - $db_type");
  is($objs->[4]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join three-level 10 - $db_type");
  is($objs->[4]{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join three-level 11 - $db_type");
  is($objs->[4]{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join three-level 12 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}}, 4, "deep join three-level 13 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MySQLiteObject',
      require_objects => [ 'nicks.type.t2' ],
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'type.name');

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator 3 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join iterator 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join iterator 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join iterator 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join iterator 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator 8 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MySQLiteObject',
      with_objects => [ 'nicks.type.t2' ],
      nonlazy      => 1,
      sort_by      => 'type.name');

  $o = $iterator->next;
  $o = $iterator->next;

  SORT:
  {
    $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  }

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator with 1 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator with 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "deep join iterator with 3 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  SORT:
  {
    $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
  }

  is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join iterator with 4 - $db_type");
  is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join iterator with 5 - $db_type");
  is($o->{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join iterator with 6 - $db_type");
  is($o->{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join iterator with 7 - $db_type");
  is(scalar @{$o->{'nicks'}}, 4, "deep join iterator with 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join iterator with 9 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MySQLiteObject',
      require_objects => [ 'nicks.alts' ],
      multi_many_ok => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'alts.alt');

  ok(@$objs == 2, "deep join multi 1 - $db_type");
  is($objs->[0]->id, 2, "deep join multi 2 - $db_type");
  is($objs->[1]->id, 5, "deep join multi 3 - $db_type");

  is($objs->[0]{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi 4 - $db_type");
  is(scalar @{$objs->[0]{'nicks'}[0]{'alts'}}, 1, "deep join multi 5 - $db_type");

  is($objs->[1]{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi 6 - $db_type");
  is($objs->[1]{'nicks'}[0]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi 7 - $db_type");
  is($objs->[1]{'nicks'}[0]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi 8 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[0]{'alts'}}, 3, "deep join multi 11 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MySQLiteObject',
      with_objects  => [ 'nicks.alts' ],
      multi_many_ok => 1,
      nonlazy       => 1,
      sort_by       => 'alts.alt');

  ok(@$objs == 21, "deep join multi with 1 - $db_type");
  is($objs->[1]->id, 2, "deep join multi with 2 - $db_type");
  is($objs->[4]->id, 5, "deep join multi with 3 - $db_type");

  SORT:
  {
    $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
    $objs->[1]{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[1]{'nicks'}[1]{'alts'}} ];
  }

  is($objs->[1]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi with with 4 - $db_type");
  is(scalar @{$objs->[1]{'nicks'}[1]{'alts'}}, 1, "deep join multi with 5 - $db_type");

  SORT:
  {
    $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
    $objs->[4]{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[4]{'nicks'}[1]{'alts'}} ];
  }

  is($objs->[4]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi with 6 - $db_type");
  is($objs->[4]{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi with 7 - $db_type");
  is($objs->[4]{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi with 8 - $db_type");
  is(scalar @{$objs->[4]{'nicks'}[1]{'alts'}}, 3, "deep join multi with 11 - $db_type");

  is(scalar @{$objs->[0]{'nicks'} || []}, 0, "deep join multi with 12 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MySQLiteObject',
      require_objects => [ 'nicks.alts' ],
      multi_many_ok => 1,
      query        => [ 'id' => [ 2, 5 ] ],
      sort_by      => 'alts.alt');

  $o = $iterator->next;
  is($o->id, 2, "deep join multi iter 1 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi iter 2 - $db_type");
  is(scalar @{$o->{'nicks'}[0]{'alts'}}, 1, "deep join multi iter 3 - $db_type");

  $o = $iterator->next;
  is($o->{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi iter 4 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi iter 5 - $db_type");
  is($o->{'nicks'}[0]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi iter 6 - $db_type");
  is(scalar @{$o->{'nicks'}[0]{'alts'}}, 3, "deep join multi iter 7 - $db_type");

  ok(!$iterator->next, "deep join multi iter 8 - $db_type");
  is($iterator->total, 2, "deep join multi iter 9 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MySQLiteObject',
      with_objects  => [ 'nicks.alts' ],
      multi_many_ok => 1,
      nonlazy       => [ 'nicks' ],
      #query => [ id => 2 ],
      sort_by       => 'alts.alt');

  $o = $iterator->next;
  is(scalar @{$o->{'nicks'} ||= []}, 0, "deep join multi iter with 1 - $db_type");

  $o = $iterator->next;

  SORT:
  {
    $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
    $o->{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
  }

  is($o->id, 2, "deep join multi iter with 2 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi iter with 3 - $db_type");
  is(scalar @{$o->{'nicks'}[1]{'alts'}}, 1, "deep join multi iter with 4 - $db_type");

  $o = $iterator->next;
  $o = $iterator->next;

  $o = $iterator->next;

  SORT:
  {
    $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
    $o->{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
  }

  is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi iter with 5 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi iter with 6 - $db_type");
  is($o->{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi iter with 7 - $db_type");
  is(scalar @{$o->{'nicks'}[1]{'alts'}}, 3, "deep join multi iter with 8 - $db_type");

  while($iterator->next) { }
  is($iterator->total, 21, "deep join multi iter with 9 - $db_type");

  # End deep join tests

  # Start custom select tests

  my @selects =
  (
    't2.nick, id, t2.id, name, UPPER(name) AS derived, fk1',
    't1.id, t2.nick, t2.id, t1.name, UPPER(name) AS derived, t1.fk1',
    'rose_db_object_nicks.id, rose_db_object_test.id, rose_db_object_nicks.nick, rose_db_object_test.name, UPPER(name) AS derived',
    [ \q(t1.id + 0 AS id), qw(name t2.nick nicks.id), \q(UPPER(name) AS derived) ],
    [ qw(t2.nick t2.id t1.id t1.name), 'UPPER(name) AS derived' ],
    [ \q(UPPER(name) AS derived), qw(t2.id rose_db_object_nicks.nick rose_db_object_test.id rose_db_object_test.name) ],
    [ qw(rose_db_object_test.id rose_db_object_nicks.nick rose_db_object_test.name rose_db_object_nicks.id), 'UPPER(name) AS derived' ],
    [ qw(rose_db_object_test.id rose_db_object_test.name rose_db_object_nicks.nick t2.id), 'UPPER(name) AS derived' ],
  );

  $i = 0;

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MySQLiteObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && !defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && !defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MySQLiteObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && defined $objs->[0]->nicks->[0]->nick &&
       !defined $objs->[0]->nicks->[0]->type_id && !defined $objs->[0]->flag2 &&
       $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && defined $objs->[1]->nicks->[0]->nick &&
       !defined $objs->[1]->nicks->[0]->type_id && !defined $objs->[1]->flag2 &&
       $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  @selects =
  (
    't2.nick, t1.*, t2.id, name, UPPER(name) AS derived',
    [ qw(t2.nick t2.id t1.*), 'UPPER(name) AS derived' ],
  );

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MySQLiteObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
       !defined $o->nicks->[0]->type_id && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MySQLiteObject',
        select          => $select,
        require_objects => [ 'nicks' ],
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && defined $objs->[0]->nicks->[0]->nick &&
       !defined $objs->[0]->nicks->[0]->type_id && defined $objs->[0]->flag2 &&
       $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && defined $objs->[1]->nicks->[0]->nick &&
       !defined $objs->[1]->nicks->[0]->type_id && defined $objs->[1]->flag2 &&
       $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  @selects =
  (
    '*, name, UPPER(name) AS derived',
    [ '*', 'UPPER(name) AS derived' ],
  );

  #local $Rose::DB::Object::Manager::Debug = 1;

  foreach my $select (@selects)
  {
    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MySQLiteObject',
        select          => $select,
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    $o = $iterator->next;

    ok($o->id > 2 && defined $o->name && defined $o->flag2 && 
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;

    $o = $iterator->next;
    ok($o->id > 2 && defined $o->name && defined $o->flag2 &&
       $o->derived eq 'DERIVED: ' . uc($o->name),
       "custom select $i - $db_type");

    $i++;
    ok(!$iterator->next, "custom select $i - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MySQLiteObject',
        select          => $select,
        query           => [ id => { gt => 2 } ],
        sort_by         => 'id',
        limit           => 2);

    $i++;

    ok($objs->[0]->id > 2 && defined $objs->[0]->name && 
       defined $objs->[0]->flag2 && $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
       "custom select $i - $db_type");

    $i++;

    ok($objs->[1]->id > 2 && defined $objs->[1]->name && 
       defined $objs->[1]->flag2 && $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
       "custom select $i - $db_type");

    $i++;
    is(scalar @$objs, 2, "custom select $i - $db_type");
  }

  # End custom select tests
}

#
# Oracle
#

SKIP: foreach my $db_type (qw(oracle))
{
  skip("Oracle tests", 782)  unless($HAVE_ORACLE);

  Rose::DB->default_type($db_type);

  my $o = MyOracleObject->new(id         => 1,
                              name       => 'John',  
                              flag       => 't',
                              flag2      => 'f',
                              fkone      => 2,
                              status     => 'active',
                              bits       => '00001',
                              start_date => '2001-01-02',
                              save_col   => 5,     
                              last_modified => 'now',
                              date_created  => '2004-03-30 12:34:56');

  ok($o->save, "object save() 1 - $db_type");

  my $objs = 
    MyOracleObject->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 1 },
        name       => 'John',  
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        fixed      => { like => 'nee%' },
        or         => [ and => [ '!bits' => '00001', bits => { ne => '11111' } ],
                        and => [ bits => { lt => '10101' }, '!bits' => '10000' ] ],
        start_date => '01/02/2001',
        save_col   => [ 1, 5 ],
        fk1        => 2,
        last_modified => { le => $o->last_modified },
        date_created  => '2004-03-30 12:34:56',
        date_created  => { le => 'now' },
        date_created  => [ 'now', '2004-03-30 12:34:56' ],
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 2 - $db_type");

  my $o2 = $o->clone;
  $o2->id(2);
  $o2->name('Fred');

  ok($o2->save, "object save() 2 - $db_type");

  my $o3 = $o2->clone;
  $o3->id(3);
  $o3->name('Sue');

  ok($o3->save, "object save() 3 - $db_type");

  my $o4 = $o3->clone;
  $o4->id(4);
  $o4->name('Bob');

  ok($o4->save, "object save() 4 - $db_type");

  eval
  {
    $objs = 
      MyOracleObjectManager->get_objectz(
        query  =>
        [
          date_created => '205-1-2', # invalid date
        ]);
  };

  ok($@, "Invalid date - $db_type");

  eval
  {
    $objs = 
      MyOracleObjectManager->get_objectz(
        query => [ flag => [] ]);
  };

  ok($@, "Empty list 1 - $db_type");

  $objs = 
    MyOracleObjectManager->get_objectz(
      allow_empty_lists => 1,
      query  => [ flag => [] ]);

  is(scalar @$objs, 4, "Empty list 2 - $db_type");

  eval
  {
    $objs = 
      MyOracleObjectManager->get_objectz(
        query => [ or => [ flag => 1, status => [] ] ]);
  };

  ok($@, "Empty list 3 - $db_type");

  $objs = 
    MyOracleObjectManager->get_objectz(
      allow_empty_lists => 1,
        query => [ or => [ flag => 1, status => [] ] ]);

  is(scalar @$objs, 4, "Empty list 4 - $db_type");

  $objs = 
    MyOracleObjectManager->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start_date => '01/02/2001',
        save_col   => [ 1, 5 ],
        last_modified => { le => parse_date('now') },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is(ref $objs, 'ARRAY', "get_objects() 3 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 2, "get_objects() 4 - $db_type");
  is($objs->[0]->id, 3, "get_objects() 5 - $db_type");
  is($objs->[1]->id, 2, "get_objects() 6 - $db_type");

  my $count =
    MyOracleObject->get_objectz_count(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start_date => '01/02/2001',
        save_col   => [ 1, 5 ],
        last_modified => { le => parse_date('now') },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is($count, 2, "get_objects_count() 1 - $db_type");

  # Set up sub-object for this one test
  my $b1 = MyOracleBB->new(id   => 1, name => 'one');
  $b1->save;

  $objs->[0]->b1(1);
  $objs->[0]->save;

  $count =
    MyOracleObjectManager->get_objectz_count(
      share_db     => 1,
      query_is_sql => 1,
      require_objects => [ 'bb1' ],
      query        =>
      [
        't2.name'  => { like => 'o%' },
        't2_name'  => { like => 'on%' },
        'bb1.name' => { like => '%n%' },
        id         => { ge => 2 },
        name       => { like => '%e%' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name DESC');

  is($count, 1, "get_objects_count() require 1 - $db_type");

  # Clear sub-object
  $objs->[0]->b1(undef);
  $objs->[0]->save;
  $b1->delete;

  my $save_o = $o;

  my $iterator = 
    MyOracleObjectManager->get_objectz_iterator(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start_date => '01/02/2001',
        save_col   => [ 1, 5 ],
        last_modified => { le => parse_date('now') },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name');

  is(ref $iterator, 'Rose::DB::Object::Iterator', "get_objects_iterator() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator next() 1 - $db_type");
  is($o->id, 2, "iterator next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator next() 3 - $db_type");
  is($o->id, 3, "iterator next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator next() 5 - $db_type");
  is($iterator->total, 2, "iterator total() - $db_type");

  $iterator = 
    MyOracleObject->get_objectz_iterator(
      share_db     => 1,
      skip_first   => 1,
      query        =>
      [
        id         => { ge => 2 },
        name       => { like => '%e%' },
        flag       => 't',
        flag2      => 'f',
        status     => 'active',
        bits       => '00001',
        start_date => '01/02/2001',
        save_col   => [ 1, 5 ],
        last_modified => { le => parse_date('now') },
        date_created  => '2004-03-30 12:34:56',
        status        => { like => 'AC%', field => 'UPPER(status)' },
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'name');

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator skip_first next() 1 - $db_type");
  is($o->id, 3, "iterator skip_first next() 2 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator skip_first next() 3 - $db_type");
  is($iterator->total, 1, "iterator total() - $db_type");

  my $fo = MyOracleOtherObject->new(name => 'Foo 1',
                                      k1   => 1,
                                      k2   => 2,
                                      k3   => 3);

  ok($fo->save, "object save() 5 - $db_type");

  $fo = MyOracleOtherObject->new(name => 'Foo 2',
                                   k1   => 2,
                                   k2   => 3,
                                   k3   => 4);

  ok($fo->save, "object save() 6 - $db_type");

  $fo = MyOracleBB->new(id   => 1,
                          name => 'one');
  ok($fo->save, "bb object save() 1 - $db_type");

  $fo = MyOracleBB->new(id   => 2,
                          name => 'two');
  ok($fo->save, "bb object save() 2 - $db_type");

  $fo = MyOracleBB->new(id   => 3,
                          name => 'three');
  ok($fo->save, "bb object save() 3 - $db_type");

  $fo = MyOracleBB->new(id   => 4,
                          name => 'four');
  ok($fo->save, "bb object save() 4 - $db_type");

  my $o5 = MyOracleObject->new(id         => 5,
                                name       => 'Betty',  
                                flag       => 'f',
                                flag2      => 't',
                                status     => 'with',
                                bits       => '10101',
                                start_date => '2002-05-20',
                                save_col   => 123,
                                fkone      => 1,
                                fk2        => 2,
                                fk3        => 3,
                                b1         => 2,
                                b2         => 4,
                                last_modified => '2001-01-10 20:34:56',
                                date_created  => '2002-05-10 10:34:56');

  ok($o5->save, "object save() 7 - $db_type");

  my $fo1;

  if(oracle_is_broken())
  {
    SKIP: { skip("tests that trigger the dreaded ORA-00600 kpofdr-long error", 7) }
  }
  else
  {
    $fo1 = $o5->other_obj;

    ok($fo1 && ref $fo1 && $fo1->k1 == 1 && $fo1->k2 == 2 && $fo1->k3 == 3,
       "foreign object 1 - $db_type");

    $fo1 = $o5->bb1;
    ok($fo1 && ref $fo1 && $fo1->id == 2, "bb foreign object 1 - $db_type");

    $fo1 = $o5->bb2;
    ok($fo1 && ref $fo1 && $fo1->id == 4, "bb foreign object 2 - $db_type");

    $objs = 
      MyOracleObjectManager->get_objectz(
        share_db     => 1,
        query        =>
        [
          id    => { ge => 2 },
          name  => { like => '%tt%' },
        ],
        require_objects => [ 'other_obj' ]);

    ok(ref $objs->[0]->{'other_obj'} eq 'MyOracleOtherObject', "foreign object 2 - $db_type");
    is($objs->[0]->other_obj->k2, 2, "foreign object 3 - $db_type");

    is($objs->[0]->bb1->name, 'two', "bb foreign object 3 - $db_type");
    is($objs->[0]->bb2->name, 'four', "bb foreign object 4 - $db_type");
  }

  # Start "one to many" tests

  ok($fo = MyOracleNick->new(id   => 1,
                             o_id => 5,
                             nick => 'none',
                             type => { id => 1, name => 'nt one', t2 => { id => 1, name => 'nt2 one' } },
                             alts => [ { id => 1, alt => 'alt one 1' },
                                       { id => 2, alt => 'alt one 2' },
                                       { id => 3, alt => 'alt one 3' }, ],
                             opts => [ { id => 1, opt => 'opt one 1' },
                                       { id => 2, opt => 'opt one 2' } ])->save,
     "nick object save() 1 - $db_type");

  $fo = MyOracleNick->new(id   => 2,
                          o_id => 2,
                          nick => 'ntwo',
                          type => { id => 2, name => 'nt two', t2 => { id => 2, name => 'nt2 two' } },
                          alts => [ { id => 4, alt => 'alt two 1' } ]);
  ok($fo->save, "nick object save() 2 - $db_type");

  $fo = MyOracleNick->new(id   => 3,
                          o_id => 5,
                          nick => 'nthree',
                          type => { id => 3, name => 'nt three', t2 => { id => 3, name => 'nt2 three' } },
                          opts => [ { id => 3, opt => 'opt three 1' },  { id => 4, opt => 'opt three 2' } ]);
  ok($fo->save, "nick object save() 3 - $db_type");

  $fo = MyOracleNick->new(id   => 4,
                          o_id => 2,
                          nick => 'nfour',
                          type => { id => 4, name => 'nt four', t2 => { id => 4, name => 'nt2 four' } });
  ok($fo->save, "nick object save() 4 - $db_type");

  $fo = MyOracleNick->new(id   => 5,
                          o_id => 5,
                          nick => 'nfive',
                          type => { id => 5, name => 'nt five', t2 => { id => 5, name => 'nt2 five' } });
  ok($fo->save, "nick object save() 5 - $db_type");

  $fo = MyOracleNick->new(id   => 6,
                          o_id => 5,
                          nick => 'nsix',
                          type => { id => 6, name => 'nt six', t2 => { id => 6, name => 'nt2 six' } });
  ok($fo->save, "nick object save() 6 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  my $db = Rose::DB->new;

  $db->begin_work;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      db           => $db,
      share_db     => 1,
      with_objects => [ 'nicks' ],
      for_update   => 1,
      lock         =>
      {
        on   => [ qw(nicks.type_id flag) ],
        wait => 60,
      },
      query        =>
      [
        id         => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't2.nick'  => { like => 'n%' },
        start_date => '5/20/2002',
        '!start_date' => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start_date' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start_date' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        or         => [],
        and        => [],
        save_col   => [ 1, 5, 123 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  $db->commit;
 $db->begin_work;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      db           => $db,
      share_db     => 1,
      with_objects => [ 'nicks' ],
      for_update   => 1,
      lock         =>
      {
        on => [ qw(nicks.type_id flag) ],
        skip_locked => 1,
      },
      query        =>
      [
        id         => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't2.nick'  => { like => 'n%' },
        start_date => '5/20/2002',
        '!start_date' => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start_date' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start_date' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        or         => [],
        and        => [],
        save_col   => [ 1, 5, 123 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  $db->commit;
  $db->begin_work;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      db           => $db,
      share_db     => 1,
      with_objects => [ 'nicks' ],
      lock         =>
      {
        type    => 'for update',
        columns => [ qw(rose_db_object_nicks.type_id rose_db_object_test.flag), \q(save) ],
        nowait  => 1,
      },
      query        =>
      [
        id         => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't2.nick'  => { like => 'n%' },
        start_date => '5/20/2002',
        '!start_date' => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start_date' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start_date' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        or         => [],
        and        => [],
        save_col   => [ 1, 5, 123 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() with many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 2 - $db_type");

  ok(!defined $objs->[0]->{'status'}, "lazy main 1 - $db_type");
  is($objs->[0]->status, 'with', "lazy main 2 - $db_type");

  my $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 5 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 7 - $db_type");

  $db->commit;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks', 'bb1' ],
      query        =>
      [
        't1.id'    => { ge => 1 },
        't1.name'  => 'Betty',  
        flag       => 'f',
        flag2      => 1,
        bits       => '10101',
        't3.nick'  => { like => 'n%' },
        start_date => '5/20/2002',
        '!start_date' => { gt => DateTime->new(year  => '2005', 
                                            month => 12,
                                            day   => 1) },
        '!rose_db_object_test.start_date' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 2)
        },

        '!t1.start_date' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 12,
                              day   => 3)
        },

        save_col   => [ 1, 5, 123 ],
        fk1        => 1,
        last_modified => { le => '6/6/2020' }, # XXX: breaks in 2020!
        date_created  => '5/10/2002 10:34:56 am'
      ],
      clauses => [ "LOWER(status) LIKE 'w%'" ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() with many 8 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 9 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 10 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 11 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 12 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 13 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 14 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many bb1 1 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many bb2 2 - $db_type");

  $iterator = 
    MyOracleObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      nonlazy => 1,
      sort_by => 't1.name');

  is(ref $iterator, 'Rose::DB::Object::Iterator', "get_objects_iterator() 1 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator many next() 1 - $db_type");
  is($o->id, 5, "iterator many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator many next() 3 - $db_type");
  is($o->id, 4, "iterator many next() 4 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator many next() 5 - $db_type");
  is($o->id, 2, "iterator many next() 6 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "iterator many sub-object 1 - $db_type");
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "iterator many sub-object 2 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "iterator many sub-object 3 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator many next() 7 - $db_type");
  is($o->id, 3, "iterator many next() 8 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator many next() 9 - $db_type");
  is($iterator->total, 4, "iterator many total() - $db_type");

  $iterator = 
    MyOracleObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      limit_with_subselect => 0,
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      sort_by => 't1.name',
      limit   => 2);

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator limit 2 many next() 1 - $db_type");
  is($o->id, 5, "iterator limit 2 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 2 many next() 3 - $db_type");
  is($o->id, 4, "iterator limit 2 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 2 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 2 many total() - $db_type");

  $iterator = 
    MyOracleObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => [ 'nicks' ],
      sort_by => 't1.name',
      limit   => 3);

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator limit 3 many next() 1 - $db_type");
  is($o->id, 5, "iterator limit 3 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 3 many next() 3 - $db_type");
  is($o->id, 4, "iterator limit 3 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 3 many next() 5 - $db_type");
  is($o->id, 2, "iterator limit 3 many next() 6 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, "iterator limit 3 many sub-object 1 - $db_type");
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', "iterator limit 3 many sub-object 2 - $db_type");
  is($o->{'nicks'}[1]{'nick'}, 'nfour', "iterator limit 3 many sub-object 3 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 3 many next() 7 - $db_type");
  is($iterator->total, 3, "iterator limit 3 many total() - $db_type");

  $objs = 
    MyOracleObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      sort_by => 't1.name',
      limit   => 2);

  ok(ref $objs && @$objs == 2, "get_objects() limit 2 many 1 - $db_type");
  is($objs->[0]->name, 'Betty', "get_objects() limit 2 many 2 - $db_type");
  is($objs->[0]->id, 5, "get_objects() limit 2 many 3 - $db_type");

  is($objs->[1]->name, 'Bob', "get_objects() limit 2 many 4 - $db_type");
  is($objs->[1]->id, 4, "get_objects() limit 2 many 5 - $db_type");

  $objs = 
    MyOracleObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'nicks', 'bb2' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3);

  ok(ref $objs && @$objs == 3, "get_objects() limit 3 many 1 - $db_type");
  is($objs->[0]->name, 'Betty', "get_objects() limit 3 many 2 - $db_type");
  is($objs->[0]->id, 5, "get_objects() limit 3 many 3 - $db_type");

  is($objs->[1]->name, 'Bob', "get_objects() limit 3 many 4 - $db_type");
  is($objs->[1]->id, 4, "get_objects() limit 3 many 5 - $db_type");

  is($objs->[2]->name, 'Fred', "get_objects() limit 3 many 6 - $db_type");
  is($objs->[2]->id, 2, "get_objects() limit 3 many 7 - $db_type");
  is(scalar @{$objs->[2]->{'nicks'}}, 2, 'get_objects() limit 3 many sub-object 1');
  is($objs->[2]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 3 many sub-object 2');
  is($objs->[2]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 3 many sub-object 3');

  $iterator = 
    MyOracleObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 2,
      offset  => 1);

  $o = $iterator->next;
  is($o->name, 'Bob', "iterator limit 2 offset 1 many next() 1 - $db_type");
  is($o->id, 4, "iterator limit 2 offset 1 many next() 2 - $db_type");

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 2 offset 1 many next() 3 - $db_type");
  is($o->id, 2, "iterator limit 2 offset 1 many next() 4 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, 'iterator limit 2 offset 1 many sub-object 1');
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', 'iterator limit 2 offset 1 many sub-object 2');
  is($o->{'nicks'}[1]{'nick'}, 'nfour', 'iterator limit 2 offset 1 many sub-object 3');

  $o = $iterator->next;
  is($o, 0, "iterator limit 2 offset 1 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 2 offset 1 many total() - $db_type");

  $iterator = 
    MyOracleObjectManager->get_objectz_iterator(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3,
      offset  => 2);

  $o = $iterator->next;
  is($o->name, 'Fred', "iterator limit 3 offset 2 many next() 1 - $db_type");
  is($o->id, 2, "iterator limit 3 offset 2 many next() 2 - $db_type");
  is(scalar @{$o->{'nicks'}}, 2, 'iterator limit 3 offset 2 many sub-object 1');
  is($o->{'nicks'}[0]{'nick'}, 'ntwo', 'iterator limit 3 offset 2 many sub-object 2');
  is($o->{'nicks'}[1]{'nick'}, 'nfour', 'iterator limit 3 offset 2 many sub-object 3');

  $o = $iterator->next;
  is($o->name, 'Sue', "iterator limit 3 offset 2 many next() 3 - $db_type");
  is($o->id, 3, "iterator limit 3 offset 2 many next() 4 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator limit 3 offset 2 many next() 5 - $db_type");
  is($iterator->total, 2, "iterator limit 3 offset 2 many total() - $db_type");

  $objs = 
    MyOracleObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 2,
      offset  => 1);

  ok(ref $objs && @$objs == 2, "get_objects() limit 2 offset 1 many 1 - $db_type");
  is($objs->[0]->name, 'Bob', "get_objects() limit 2 offset 1 many 2 - $db_type");
  is($objs->[0]->id, 4, "get_objects() limit 2 offset 1 many 3 - $db_type");

  is($objs->[1]->name, 'Fred', "get_objects() limit 2 offset 1 many 4 - $db_type");
  is($objs->[1]->id, 2, "get_objects() limit 2 offset 1 many 5 - $db_type");
  is(scalar @{$objs->[1]->{'nicks'}}, 2, 'get_objects() limit 2 offset 1 many sub-object 1');
  is($objs->[1]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 2 offset 1 many sub-object 2');
  is($objs->[1]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 2 offset 1 many sub-object 3');

  $objs = 
    MyOracleObjectManager->get_objectz(
      share_db     => 1,
      with_objects => [ 'nicks', 'bb2' ],
      query        =>
      [
        't1.id'  => { ge => 2 },
      ],
      limit_with_subselect => 0,
      nonlazy => 1,
      sort_by => 't1.name',
      limit   => 3,
      offset  => 2);

  ok(ref $objs && @$objs == 2, "get_objects() limit 3 offset 2 many 1 - $db_type");

  is($objs->[0]->name, 'Fred', "get_objects() limit 3 offset 2 many 2 - $db_type");
  is($objs->[0]->id, 2, "get_objects() limit 3 offset 2 many 3 - $db_type");
  is(scalar @{$objs->[0]->{'nicks'}}, 2, 'get_objects() limit 3 offset 2 many sub-object 1');
  is($objs->[0]->{'nicks'}[0]{'nick'}, 'ntwo', 'get_objects() limit 3 offset 2 many sub-object 2');
  is($objs->[0]->{'nicks'}[1]{'nick'}, 'nfour', 'get_objects() limit 3 offset 2 many sub-object 3');

  is($objs->[1]->name, 'Sue', "get_objects() limit 3 offset 2 many 4 - $db_type");
  is($objs->[1]->id, 3, "get_objects() limit 3 offset 2 many 5 - $db_type");

  my $o6 = $o2->clone;
  $o6->id(60);
  $o6->fkone(undef);
  $o6->fk2(undef);
  $o6->fk3(undef);
  $o6->b1(undef);
  $o6->b2(2);
  $o6->name('Ted');

  ok($o6->save, "object save() 8 - $db_type");

  my $o7 = $o2->clone;
  $o7->id(70);
  $o7->b1(3);
  $o7->b2(undef);
  $o7->name('Joe');

  ok($o7->save, "object save() 9 - $db_type");

  my $o8 = $o2->clone;
  $o8->id(80);
  $o8->b1(undef);
  $o8->b2(undef);
  $o8->name('Pete');

  ok($o8->save, "object save() 10 - $db_type");

  ok($fo->save, "object save() 10 - $db_type");

  $fo = MyOracleNick->new(id   => 7,
                         o_id => 60,
                         nick => 'nseven');

  ok($fo->save, "nick object save() 7 - $db_type");

  $fo = MyOracleNick->new(id   => 8,
                         o_id => 60,
                         nick => 'neight');

  ok($fo->save, "nick object save() 8 - $db_type");

  $fo = MyOracleNick->new(id   => 9,
                         o_id => 60,
                         nick => 'neight');

  ok($fo->save, "nick object save() 8 - $db_type");

  $fo = MyOracleNick2->new(id    => 1,
                          o_id  => 5,
                          nick2 => 'n2one');

  ok($fo->save, "nick2 object save() 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      query        => [ '!t1.id' => 5 ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 15 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 0, "get_objects() with many 16 - $db_type");

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      object_class => 'MyOracleObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is($count, 1, "get_objects_count() require 1 - $db_type"); 

  #local $Rose::DB::Object::Manager::Debug = 1;  
  #$DB::single = 1;

  $count = 
    Rose::DB::Object::Manager->get_objects_count(
      object_class => 'MyOracleObject',
      share_db     => 1,
      require_objects => [ 'bb2' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is($count, 2, "get_objects_count() require 2 - $db_type"); 

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      share_db     => 1,
      require_objects => [ 'bb2', 'bb1' ],
      with_objects    => [ 'nicks' ],
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 17 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with many 18 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many 19 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 20 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 21 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 22 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 23 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 24 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      share_db     => 1,
      require_objects => [ 'bb1', 'bb2' ],
      with_objects    => [ 'nicks2', 'nicks' ],
      multi_many_ok   => 1,
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with multi many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() with multi many 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with multi many 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with multi many 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with multi many 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with multi many 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with multi many 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with multi many 8 - $db_type");

  is($objs->[0]->{'nicks2'}[0]{'nick2'}, 'n2one', "get_objects() with multi many 9 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class => 'MyOracleObject',
      share_db     => 1,
      require_objects => [ 'bb1', 'bb2' ],
      with_objects    => [ 'nicks2', 'nicks' ],
      multi_many_ok   => 1,
      query        => [ ],
      sort_by => 't1.id');

  $o = $iterator->next;
  is($o->name, 'Betty', "iterator with and require 1 - $db_type");
  is($o->id, 5, "iterator with and require 2 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "iterator with and require 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "iterator with and require 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "iterator with and require 5 - $db_type");
  is($nicks->[2]->nick, 'none', "iterator with and require 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "iterator with and require 7 - $db_type");

  is($o->{'nicks2'}[0]{'nick2'}, 'n2one', "iterator with and require 8 - $db_type");

  $o = $iterator->next;
  is($o, 0, "iterator with and require 9 - $db_type");
  is($iterator->total, 1, "iterator with and require 10 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      share_db     => 1,
      with_objects => [ 'bb2', 'nicks', 'bb1' ],
      query        => [ ],
      sort_by => 't1.id');

  is(ref $objs, 'ARRAY', "get_objects() with many 25 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 8, "get_objects() with many 26 - $db_type");

  my $ids = join(',', map { $_->id } @$objs);

  is($ids, '1,2,3,4,5,60,70,80', "get_objects() with many 27 - $db_type");

  $nicks = $objs->[4]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many 28 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many 29 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many 30 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many 31 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many 32 - $db_type");

  is($objs->[6]->{'bb1'}->{'name'}, 'three', "get_objects() with many 33 - $db_type");
  ok(!defined $objs->[6]->{'bb2'}, "get_objects() with many 34 - $db_type");
  ok(!defined $objs->[6]->{'nicks'}, "get_objects() with many 35 - $db_type");

  ok(!defined $objs->[7]->{'bb1'}, "get_objects() with many 36 - $db_type");
  ok(!defined $objs->[7]->{'bb1'}, "get_objects() with many 37 - $db_type");
  ok(!defined $objs->[7]->{'nicks'}, "get_objects() with many 38 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 0;

  $fo = MyOracleNick->new(id => 7);
  ok($fo->delete, "with many clean-up 1 - $db_type");

  $fo = MyOracleNick->new(id => 8);
  ok($fo->delete, "with many clean-up 2 - $db_type");

  $fo = MyOracleNick->new(id => 9);
  ok($fo->delete, "with many clean-up 3 - $db_type");

  ok($o6->delete, "with many clean-up 4 - $db_type");
  ok($o7->delete, "with many clean-up 5 - $db_type");
  ok($o8->delete, "with many clean-up 6 - $db_type");

  $fo = MyOracleNick2->new(id => 1);
  ok($fo->delete, "with many clean-up 7 - $db_type");

  # End "one to many" tests

  if(oracle_is_broken())
  {
    SKIP: { skip("tests that trigger the dreaded ORA-00600 kpofdr-long error", 4) }
  }
  else
  {
    $iterator =
      MyOracleObject->get_objectz_iterator(
        share_db     => 1,
        query        =>
        [
          't1.id'    => { ge => 2 },
          't1.name'  => { like => '%tt%' },
        ],
        require_objects => [ 'other_obj' ]);

    $o = $iterator->next;

    ok(ref $o->{'other_obj'} eq 'MyOracleOtherObject', "foreign object 4 - $db_type");
    is($o->other_obj->k2, 2, "foreign object 5 - $db_type");

    is($o->bb1->name, 'two', "bb foreign object 5 - $db_type");
    is($o->bb2->name, 'four', "bb foreign object 6 - $db_type");
  }

  $objs = 
    MyOracleObjectManager->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 1 },
        name       => 'John',  
        flag       => 1,
        flag2      => 0,
        status     => 'active',
        bits       => '1',
        start_date => '1/2/2001',
        '!start_date' => { gt => DateTime->new(year  => '2005', 
                                            month => 1,
                                            day   => 1) },
        '!rose_db_object_test.start_date' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 2,
                              day   => 2)
        },

        '!t1.start_date' => 
        {
          gt => DateTime->new(year  => '2005', 
                              month => 3,
                              day   => 3)
        },

        save_col   => [ 1, 5 ],
        fk1        => 2,
        fk1        => { lt => 99 },
        fk1        => { lt => 100 },
        or         => [ fk1 => { lt => 777 },
                        last_modified => '6/6/2020' ],
        last_modified => { le => '6/6/2020' }, # XXX: test breaks in 2020!
        date_created  => '3/30/2004 12:34:56 pm'
      ],
      clauses => [ "LOWER(status) LIKE 'ac%'" ],
      limit   => 5,
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() 7 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 8 - $db_type");

  $objs = 
    MyOracleObject->get_objectz(
      share_db     => 1,
      query        =>
      [
        id         => { ge => 2 },
        k1         => { lt => 900 },
        or         => [ k1 => { ne => 99 }, k1 => 100 ],
        or         => [ and => [ id => { ne => 123 }, id => { lt => 100  } ],
                        and => [ id => { ne => 456 }, id => { lt => 300  } ] ],
        '!k2'      => { gt => 999 },
        '!t2.name' => 'z',
        start_date => { lt => DateTime->new(year => '2005', month => 1, day => 1) },
        '!start_date' => { gt => DateTime->new(year => '2005', month => 1, day => 1) },
        'rose_db_object_test.name'   => { like => '%tt%' },
        '!rose_db_object_other.name' => 'q',
        '!rose_db_object_other.name' => [ 'x', 'y' ],
      ],
      require_objects => [ 'other_obj' ]);

  ok(ref $objs->[0]->{'other_obj'} eq 'MyOracleOtherObject', "foreign object 6 - $db_type");
  is($objs->[0]->other_obj->k2, 2, "foreign object 7 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $objs = 
    MyOracleObjectManager->get_objectz(
      share_db     => 1,
      queryis_sql  => 1,
      query        =>
      [
        id         => { ge => 1 },
        name       => 'John',  
      ],
      limit   => 5,
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() 9 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() 10 - $db_type");

  # Test limit with offset

  foreach my $id (6 .. 20)
  {
    my $o = $o5->clone;
    $o->id($id);
    $o->name("Clone $id");

    ok($o->save, "object save() clone $id - $db_type");
  }

  $objs = 
    MyOracleObject->get_objectz(
      sort_by      => 'id DESC',
      limit        => 2,
      offset       => 8);

  ok(ref $objs eq 'ARRAY' && @$objs == 2 && 
     $objs->[0]->id == 12 && $objs->[1]->id == 11,
     "get_objects() with offset - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;

  $objs = 
    MyOracleObjectManager->get_objectz(
      sort_by      => 'id DESC',
      require_objects => [ 'other_obj' ],
      limit        => 2,
      offset       => 8);

  ok(ref $objs eq 'ARRAY' && @$objs == 2 && 
     $objs->[0]->id == 12 && $objs->[1]->id == 11,
     "get_objects() with objects and offset - $db_type");

  $iterator = 
    MyOracleObject->get_objectz_iterator(
      sort_by      => 'id DESC',
      limit        => 2,
      offset       => 8);

  $o = $iterator->next;
  is($o->id, 12, "get_objects_iterator() with offset 1 - $db_type");

  $o = $iterator->next;
  is($o->id, 11, "get_objects_iterator() with offset 2 - $db_type");

  is($iterator->next, 0, "get_objects_iterator() with offset 3 - $db_type");

  eval
  {
    $objs = 
      MyOracleObjectManager->get_objectz(
        object_class => 'MyOracleObject',
        sort_by      => 'id DESC',
        offset       => 8)
  };

  ok($@ =~ /invalid without a limit/, "get_objects() missing offset - $db_type");

  eval
  {
    $iterator = 
      MyOracleObject->get_objectz_iterator(
        object_class => 'MyOracleObject',
        sort_by      => 'id DESC',
        offset       => 8);
  };

  ok($@ =~ /invalid without a limit/, "get_objects_iterator() missing offset - $db_type");

  # Start *_sql comparison tests

  $o6->fk2(99);
  $o6->fk3(99);
  $o6->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ 'fk2' => { eq_sql => 'fk3' } ],
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq_sql 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq_sql 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq_sql 3 - $db_type");

  # End *_sql comparison tests

  # Start IN NULL tests

  if(oracle_is_broken())
  {
    SKIP: { skip("tests that trigger the dreaded ORA-00600 kpofdr-long error", 3) }
  }
  else
  {
    #local $Rose::DB::Object::Manager::Debug = 1;
    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class => 'MyOracleObject',
        query        => [ id => [ undef, 60 ], '!id' => \'id + 1' ], #'
        sort_by => 'id');

    is(ref $objs, 'ARRAY', "get_objects() in null 1 - $db_type");
    $objs ||= [];
    is(scalar @$objs, 1, "get_objects() in null 2 - $db_type");

    is($objs->[0]->id, 60, "get_objects() in null 3 - $db_type");
  }

  # End IN NULL tests

  # Start scalar ref tests

  #local $Rose::DB::Object::Manager::Debug = 1;
  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ 'fk2' => \'fk3' ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq ref 2 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq ref 3 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ 'fk2' => [ \'fk3' ] ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 4 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 1, "get_objects() eq ref 5 - $db_type");

  is($objs->[0]->id, 60, "get_objects() eq ref 6 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ 'fk2' => { ne => \'fk3' } ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 7 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 16, "get_objects() eq ref 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ 'fk2' => { ne => [ \'fk3' ] } ], #'
      sort_by => 'id');

  is(ref $objs, 'ARRAY', "get_objects() eq ref 9 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 16, "get_objects() eq ref 10 - $db_type");

  # End scalar ref tests

  # Start "many to many" tests

  $fo = MyOracleColor->new(id => 1, name => 'Red');
  $fo->save;

  $fo = MyOracleColor->new(id => 2, name => 'Green');
  $fo->save;

  $fo = MyOracleColor->new(id => 3, name => 'Blue');
  $fo->save;

  $fo = MyOracleColorMap->new(id => 1, object_id => $o2->id, color_id => 1);
  $fo->save;

  $fo = MyOracleColorMap->new(id => 2, object_id => $o2->id, color_id => 3);
  $fo->save;

  $o2->b1(4);
  $o2->b1(2);
  $o2->fkone(2);
  $o2->fk2(3);
  $o2->fk3(4);
  $o2->save;

  my @colors = $o2->colors;
  ok(@colors == 2 && $colors[0]->name eq 'Red' &&
     $colors[1]->name eq 'Blue', "Fetch many to many 1 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyOracleObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_record',
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many 4 - $db_type");
  is($objs->[2]->id, 1, "get_objects() with many to many 5 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many 12 - $db_type");

  my $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many 15 - $db_type");

  is($colors->[0]->map_record->color_id, $colors->[0]->id, "map_record 1 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 2 - $db_type");
  is($colors->[1]->map_record->color_id, $colors->[1]->id, "map_record 3 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 4 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyOracleObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_record',
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $objs = [];

  while(my $obj = $iterator->next)
  {
    push(@$objs, $obj);
  }

  is(ref $objs, 'ARRAY', "get_objects_iterator() with many to many map record 1 - $db_type");
  is(scalar @$objs, 3, "get_objects_iterator() with many to many map record  2 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  is($colors->[0]->map_record->color_id, $colors->[0]->id, "map_record 5 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 6 - $db_type");
  is($colors->[1]->map_record->color_id, $colors->[1]->id, "map_record 7 - $db_type");
  is($colors->[0]->map_record->object_id, $objs->[1]->id, "map_record 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyOracleObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      with_map_records => 'map_rec',
      query         => [ id => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many 2 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  is($colors->[0]->map_rec->color_id, $colors->[0]->id, "map_rec 1 - $db_type");
  is($colors->[0]->map_rec->object_id, $objs->[1]->id, "map_rec 2 - $db_type");
  is($colors->[1]->map_rec->color_id, $colors->[1]->id, "map_rec 3 - $db_type");
  is($colors->[0]->map_rec->object_id, $objs->[1]->id, "map_rec 4 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class  => 'MyOracleObject',
      share_db      => 1,
      with_objects  => [ 'bb1', 'nicks', 'other_obj', 'colors', 'bb2' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many (reorder) 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 3, "get_objects() with many to many (reorder) 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many (reorder) 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many (reorder) 4 - $db_type");
  is($objs->[2]->id, 1, "get_objects() with many to many (reorder) 5 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many (reorder) 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many (reorder) 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many (reorder) 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many (reorder) 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many (reorder) 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many (reorder) 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many (reorder) 12 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many (reorder) 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many (reorder) 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many (reorder) 15 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyOracleObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name');

  is(ref $objs, 'ARRAY', "get_objects() with many to many require with 1 - $db_type");
  $objs ||= [];
  is(scalar @$objs, 2, "get_objects() with many to many require with 2 - $db_type");

  is($objs->[0]->id, 5, "get_objects() with many to many require with 3 - $db_type");
  is($objs->[1]->id, 2, "get_objects() with many to many require with 4 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() with many to many require with 6 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() with many to many 7 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() with many to many 8 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() with many to many 9 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() with many to many 10 - $db_type");

  $fo1 = $objs->[0]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects() with many to many require with 11 - $db_type");

  $fo1 = $objs->[0]->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects() with many to many require with 12 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() with many to many require with 13 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() with many to many require with 14 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects() with many to many require with 15 - $db_type");

  $fo1 = $objs->[1]->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'two', "get_objects() with many to many require with 16 - $db_type");

  $fo1 = $objs->[0]->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 1', "get_objects() with many to many require with 17 - $db_type");

  $fo1 = $objs->[1]->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 2', "get_objects() with many to many require with 18 - $db_type");

  ok(!defined $objs->[0]->{'colors'}, "get_objects() with many to many require with 19 - $db_type");
  ok(!defined $objs->[1]->{'bb2'}, "get_objects() with many to many require with 20 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyOracleObject',
      share_db      => 1,
      with_objects  => [ 'other_obj', 'bb2', 'nicks', 'bb1', 'colors' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many 1 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many 2 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many 3 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many 4 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many 5 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many 6 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many 7 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many 8 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many 9 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many 10 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many 11 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many 12 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 13 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 14 - $db_type");

  $o = $iterator->next;
  is($o->name, 'John', "get_objects_iterator() with many to many 15 - $db_type");
  is($o->id, 1, "get_objects_iterator() with many to many 16 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many 17 - $db_type");
  is($iterator->total, 3, "get_objects_iterator() with many to many 18 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class  => 'MyOracleObject',
      share_db      => 1,
      with_objects  => [ 'bb1', 'nicks', 'other_obj', 'colors', 'bb2' ],
      multi_many_ok => 1,
      query         => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by       => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many 19 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many 20 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many 21 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many 22 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many 23 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many 24 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many 25 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many 26 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many 27 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many 28 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many 29 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many 30 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 31 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many 32 - $db_type");

  $o = $iterator->next;
  is($o->name, 'John', "get_objects_iterator() with many to many 33 - $db_type");
  is($o->id, 1, "get_objects_iterator() with many to many 34 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many 35 - $db_type");
  is($iterator->total, 3, "get_objects_iterator() with many to many 36 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyOracleObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name');

  $o = $iterator->next;
  is($o->name, 'Betty', "get_objects_iterator() with many to many require 1 - $db_type");
  is($o->id, 5, "get_objects_iterator() with many to many require 2 - $db_type");

  $fo1 = $o->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 1', "get_objects_iterator() with many to many require 3 - $db_type");

  ok(!defined $o->{'colors'}, "get_objects_iterator() with many to many require 4 - $db_type");

  $nicks = $o->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects_iterator() with many to many require 5 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects_iterator() with many to many require 6 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects_iterator() with many to many require 7 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects_iterator() with many to many require 8 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects_iterator() with many to many require 9 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 2, "get_objects_iterator() with many to many require 10 - $db_type");

  $fo1 = $o->{'bb2'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->id == 4, "get_objects_iterator() with many to many require 11 - $db_type"); 

  $o = $iterator->next;
  is($o->name, 'Fred', "get_objects_iterator() with many to many require 12 - $db_type");
  is($o->id, 2, "get_objects_iterator() with many to many require 13 - $db_type");

  $colors = $o->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects_iterator() with many to many require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[0]->name eq 'Red', "get_objects_iterator() with many to many require 16 - $db_type");

  $fo1 = $o->{'bb1'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'two', "get_objects_iterator() with many to many require 17 - $db_type");

  $fo1 = $o->{'other_obj'}; # make sure this isn't hitting the db
  ok($fo1 && ref $fo1 && $fo1->name eq 'Foo 2', "get_objects_iterator() with many to many require 18 - $db_type");

  ok(!defined $o->{'bb2'}, "get_objects_iterator() with many to many require 19 - $db_type");

  $o = $iterator->next;
  is($o, 0, "get_objects_iterator() with many to many require 20 - $db_type");
  is($iterator->total, 2, "get_objects_iterator() with many to many require 21 - $db_type");

  $iterator = 
    Rose::DB::Object::Manager->get_objects_iterator(
      object_class    => 'MyOracleObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name',
      limit           => 1,
      offset          => 5);

  ok(!$iterator->next, "get_objects_iterator() with many to many require 22 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyOracleObject',
      share_db        => 1,
      with_objects    => [ 'nicks', 'colors', 'bb2' ],
      multi_many_ok   => 1,
      require_objects => [ 'bb1', 'other_obj' ],
      query           => [ 't1.id' => [ 1, 2, 5 ] ],
      sort_by         => 't1.name',
      limit           => 1,
      offset          => 5);

  ok(@$objs == 0, "get_objects_iterator() with many to many require 23 - $db_type");

  # End "many to many" tests

  # Start multi-require tests

  $fo = MyOracleColorMap->new(id => 3, object_id => 5, color_id => 2);
  $fo->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyOracleObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'colors', 'other_obj' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 2, "get_objects() multi many require 1 - $db_type");

  is($objs->[0]->id, 5, "get_objects() multi many require 2 - $db_type");
  is($objs->[1]->id, 2, "get_objects() multi many require 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() multi many require 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() multi many require 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() multi many require 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() multi many require 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() multi many require 8 - $db_type");

  $colors = $objs->[0]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 1, "get_objects() multi many require 9 - $db_type");
  ok($colors->[0]->id == 2 && $colors->[0]->name eq 'Green', "get_objects() multi many require 10 - $db_type");

  $nicks = $objs->[1]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 2, "get_objects() multi many require 11 - $db_type");
  is($nicks->[0]->nick, 'ntwo', "get_objects() multi many require 12 - $db_type");
  is($nicks->[1]->nick, 'nfour', "get_objects() multi many require 13 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() multi many require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() multi many require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[1]->name eq 'Blue', "get_objects() multi many require 16 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyOracleObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'colors', 'other_obj' ],
      with_objects    => [ 'bb2' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 2, "get_objects() multi many with require 1 - $db_type");

  is($objs->[0]->id, 5, "get_objects() multi many with require 2 - $db_type");
  is($objs->[1]->id, 2, "get_objects() multi many with require 3 - $db_type");

  $nicks = $objs->[0]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 4, "get_objects() multi many with require 4 - $db_type");
  is($nicks->[0]->nick, 'nthree', "get_objects() multi many with require 5 - $db_type");
  is($nicks->[1]->nick, 'nsix', "get_objects() multi many with require 6 - $db_type");
  is($nicks->[2]->nick, 'none', "get_objects() multi many with require 7 - $db_type");
  is($nicks->[3]->nick, 'nfive', "get_objects() multi many with require 8 - $db_type");

  $colors = $objs->[0]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 1, "get_objects() multi many with require 9 - $db_type");
  ok($colors->[0]->id == 2 && $colors->[0]->name eq 'Green', "get_objects() multi many with require 10 - $db_type");

  $nicks = $objs->[1]->{'nicks'}; # make sure this isn't hitting the db

  is(scalar @$nicks, 2, "get_objects() multi many with require 11 - $db_type");
  is($nicks->[0]->nick, 'ntwo', "get_objects() multi many with require 12 - $db_type");
  is($nicks->[1]->nick, 'nfour', "get_objects() multi many with require 13 - $db_type");

  $colors = $objs->[1]->{'colors'}; # make sure this isn't hitting the db
  ok($colors && ref $colors && @$colors == 2, "get_objects() multi many with require 14 - $db_type");
  ok($colors->[0]->id == 1 && $colors->[0]->name eq 'Red', "get_objects() multi many with require 15 - $db_type");
  ok($colors->[1]->id == 3 && $colors->[1]->name eq 'Blue', "get_objects() multi many with require 16 - $db_type");

  is($objs->[0]->{'bb2'}{'name'}, 'four', "get_objects() multi many with require 17 - $db_type");
  ok(!defined $objs->[1]->{'bb2'}{'name'}, "get_objects() multi many with require 18 - $db_type");

  MyOracleNick->new(id => 7, o_id => 10,  nick => 'nseven')->save;
  MyOracleNick->new(id => 8, o_id => 11,  nick => 'neight')->save;
  MyOracleNick->new(id => 9, o_id => 12,  nick => 'nnine')->save;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class    => 'MyOracleObject',
      share_db        => 1,
      require_objects => [ 'nicks', 'bb1' ],
      with_objects    => [ 'colors' ],
      multi_many_ok   => 1,
      sort_by         => 't1.name');

  is(scalar @$objs, 5, "get_objects() multi many with require map 1 - $db_type");

  is($objs->[0]->id,  5, "get_objects() multi many with require map 2 - $db_type");
  is($objs->[1]->id, 10, "get_objects() multi many with require map 3 - $db_type");
  is($objs->[2]->id, 11, "get_objects() multi many with require map 4 - $db_type");
  is($objs->[3]->id, 12, "get_objects() multi many with require map 5 - $db_type");
  is($objs->[4]->id,  2, "get_objects() multi many with require map 6 - $db_type");

  # End multi-require tests

  # Start distinct tests

  my $i = 0;

  foreach my $distinct (1, [ 't1' ], [ 'rose_db_object_test' ])
  {
    $i++;

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyOracleObject',
        distinct        => $distinct,
        share_db        => 1,
        require_objects => [ 'nicks', 'colors', 'other_obj' ],
        multi_many_ok   => 1,
        sort_by         => 't1.name');

    is(scalar @$objs, 2, "get_objects() distinct multi many require $i.1 - $db_type");

    is($objs->[0]->id, 5, "get_objects() distinct multi many require $i.2 - $db_type");
    is($objs->[1]->id, 2, "get_objects() distinct multi many require $i.3 - $db_type");

    ok(!defined $objs->[0]->{'nicks'}, "get_objects() distinct multi many require $i.4 - $db_type");
    ok(!defined $objs->[0]->{'colors'}, "get_objects() distinct multi many require $i.5 - $db_type");

    ok(!defined $objs->[1]->{'nicks'}, "get_objects() distinct multi many require $i.6 - $db_type");
    ok(!defined $objs->[1]->{'colors'}, "get_objects() distinct multi many require $i.7 - $db_type");
  }

  #local $Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  foreach my $distinct ([ 't2' ], [ 'rose_db_object_nicks' ], [ 'nicks' ])
  {
    $i++;

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyOracleObject',
        distinct        => $distinct,
        share_db        => 1,
        require_objects => [ 'nicks', 'colors', 'other_obj' ],
        multi_many_ok   => 1,
        sort_by         => 't1.name');

    is(scalar @$objs, 2, "get_objects() distinct multi many require $i.1 - $db_type");

    is($objs->[0]->id, 5, "get_objects() distinct multi many require $i.2 - $db_type");
    is($objs->[1]->id, 2, "get_objects() distinct multi many require $i.3 - $db_type");

    ok(defined $objs->[0]->{'nicks'}, "get_objects() distinct multi many require $i.4 - $db_type");
    ok(!defined $objs->[0]->{'colors'}, "get_objects() distinct multi many require $i.5 - $db_type");

    ok(defined $objs->[1]->{'nicks'}, "get_objects() distinct multi many require $i.6 - $db_type");
    ok(!defined $objs->[1]->{'colors'}, "get_objects() distinct multi many require $i.7 - $db_type");
  }

  # End distinct tests

  # Start pager tests

  is(Rose::DB::Object::Manager->default_objects_per_page, 20, 'default_objects_per_page 1');

  Rose::DB::Object::Manager->default_objects_per_page(3);

  my $per_page = Rose::DB::Object::Manager->default_objects_per_page;

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 1,
      per_page     => 3);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 1.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 2.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => 3);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 3.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => -1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 4.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => -1);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 5.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => undef);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 6.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      per_page     => undef);

  $i = 0;

  for(1 .. 3)
  {
    is($objs->[$i++]->id, $_, "pager 7.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id');

  ok(scalar @$objs > 3, "pager 8 - $db_type");

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 2,
      per_page     => 3);

  $i = 0;

  for(4 .. 6)
  {
    is($objs->[$i++]->id, $_, "pager 9.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 3,
      per_page     => 3);

  $i = 0;

  for(7 .. 9)
  {
    is($objs->[$i++]->id, $_, "pager 10.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 4,
      per_page     => 3);

  $i = 0;

  for(10 .. 11)
  {
    is($objs->[$i++]->id, $_, "pager 11.$_ - $db_type");
  }

  $objs = 
    Rose::DB::Object::Manager->get_objects(
      object_class => 'MyOracleObject',
      query        => [ id => { le => 11 } ],
      sort_by      => 't1.id',
      page         => 5,
      per_page     => 3);

  ok(scalar @$objs == 0, "pager 12 - $db_type");

  Rose::DB::Object::Manager->default_objects_per_page(20);

  # End pager tests

  # Start get_objects_from_sql tests

  if(oracle_is_broken())
  {
    SKIP: { skip("tests that trigger the dreaded ORA-00600 kpofdr-long error", 287) }
  }
  else
  {
    # local $Rose::DB::Object::Debug = 1;
    # local $Rose::DB::Object::Manager::Debug = 1;
    # $DB::single = 1;
    $objs = 
      MyOracleObjectManager->get_objects_from_sql(
        db => MyOracleObject->init_db,
        object_class => 'MyOracleObject',
        prepare_cached => 1,
        sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

    ok(scalar @$objs == 19, "get_objects_from_sql 1 - $db_type");
    is($objs->[18]->id, 1, "get_objects_from_sql 2 - $db_type");
    is($objs->[18]->save_col, 5, "get_objects_from_sql 3 - $db_type");
    is($objs->[18]->name, 'John', "get_objects_from_sql 4 - $db_type");

    $iterator = 
      MyOracleObjectManager->get_objects_iterator_from_sql(
        db  => MyOracleObject->init_db,
        object_class => 'MyOracleObject',
        prepare_cached => 1,
        sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

    for(0 .. 17) { $iterator->next }

    $o = $iterator->next;
    is($o->id, 1, "get_objects_iterator_from_sql 1 - $db_type");
    is($o->save_col, 5, "get_objects_iterator_from_sql 2 - $db_type");
    is($o->name, 'John', "get_objects_iterator_from_sql 3 - $db_type");
    ok(!$iterator->next,  "get_objects_iterator_from_sql 4 - $db_type");

    $objs = MyOracleObjectManager->get_objects_from_sql(<<"EOF");
SELECT * FROM rose_db_object_test WHERE id != fk1 ORDER BY id DESC
EOF

    ok(scalar @$objs == 19, "get_objects_from_sql 5 - $db_type");
    is($objs->[18]->id, 1, "get_objects_from_sql 6 - $db_type");
    is($objs->[18]->save_col, 5, "get_objects_from_sql 7 - $db_type");
    is($objs->[18]->name, 'John', "get_objects_from_sql 8 - $db_type");

    $objs = 
      MyOracleObjectManager->get_objects_from_sql(
        args => [ 19 ],
        sql => <<"EOF");
SELECT * FROM rose_db_object_test WHERE id > ? ORDER BY id DESC
EOF

    ok(scalar @$objs == 2, "get_objects_from_sql 9 - $db_type");
    is($objs->[0]->id, 60, "get_objects_from_sql 10 - $db_type");

    my $method = 
      MyOracleObjectManager->make_manager_method_from_sql(
        get_em => <<"EOF");
SELECT r.*, save + fk1 AS extra FROM rose_db_object_test r WHERE id != fk1 ORDER BY id DESC
EOF

    $objs = MyOracleObjectManager->get_em;

    ok(scalar @$objs == 19, "make_manager_method_from_sql 1 - $db_type");
    is($objs->[17]->id, 3, "make_manager_method_from_sql 2 - $db_type");
    is($objs->[17]->extra, 7, "make_manager_method_from_sql 3 - $db_type");
    is($objs->[17]->name, 'Sue', "make_manager_method_from_sql 4 - $db_type");  

    $objs = $method->('MyOracleObjectManager');

    ok(scalar @$objs == 19, "make_manager_method_from_sql 5 - $db_type");
    is($objs->[17]->id, 3, "make_manager_method_from_sql 6 - $db_type");
    is($objs->[17]->extra, 7, "make_manager_method_from_sql 7 - $db_type");
    is($objs->[17]->name, 'Sue', "make_manager_method_from_sql 8 - $db_type");  

    $method = 
      MyOracleObjectManager->make_manager_method_from_sql(
        iterator => 1, method => 'iter_em', sql => <<"EOF");
SELECT r.*, save + fk1 AS extra FROM rose_db_object_test r WHERE id != fk1 ORDER BY id DESC
EOF

    $iterator = MyOracleObjectManager->iter_em;

    for(0 .. 16) { $iterator->next }

    $o = $iterator->next;
    is($objs->[17]->id, 3, "make_manager_method_from_sql iterator 1 - $db_type");
    is($objs->[17]->extra, 7, "make_manager_method_from_sql iterator 2 - $db_type");
    is($objs->[17]->name, 'Sue', "make_manager_method_from_sql iterator 3 - $db_type");  

    $iterator = $method->('MyOracleObjectManager');

    for(0 .. 16) { $iterator->next }

    $o = $iterator->next;
    is($objs->[17]->id, 3, "make_manager_method_from_sql iterator 4 - $db_type");
    is($objs->[17]->extra, 7, "make_manager_method_from_sql iterator 5 - $db_type");
    is($objs->[17]->name, 'Sue', "make_manager_method_from_sql iterator 6 - $db_type");  

    $method = 
      MyOracleObjectManager->make_manager_method_from_sql(
        get_more => <<"EOF");
SELECT r.*, save + fk1 AS extra FROM rose_db_object_test r WHERE id > ? ORDER BY id DESC
EOF

    $objs = MyOracleObjectManager->get_more(18);
    ok(scalar @$objs == 3, "make_manager_method_from_sql 9 - $db_type");
    is($objs->[2]->id, 19, "make_manager_method_from_sql 10 - $db_type");

    $method = 
      MyOracleObjectManager->make_manager_method_from_sql(
        method => 'get_more_np',
        params => [ qw(id name) ],
        sql    => <<"EOF");
SELECT r.*, save + fk1 AS extra FROM rose_db_object_test r WHERE 
id > ? AND name != ? ORDER BY id DESC
EOF

    $objs = MyOracleObjectManager->get_more_np(name => 'Nonesuch', id => 18);
    ok(scalar @$objs == 3, "make_manager_method_from_sql 11 - $db_type");
    is($objs->[2]->id, 19, "make_manager_method_from_sql 12 - $db_type");

    # End get_objects_from_sql tests

    # Start tough order tests

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyOracleObject',
        require_objects => [ 'nicks' ],
        nonlazy         => 1);

    ok(@$objs == 5, "tough order 1 - $db_type");
    is($objs->[0]->id, 2, "tough order 2 - $db_type");
    is($objs->[1]->id, 5, "tough order 3 - $db_type");
    is($objs->[2]->id, 10, "tough order 4 - $db_type");
    is($objs->[3]->id, 11, "tough order 5 - $db_type");
    is($objs->[4]->id, 12, "tough order 6 - $db_type");

    is($objs->[0]{'nicks'}[0]{'nick'}, 'ntwo', "tough order 7 - $db_type");
    is($objs->[0]{'nicks'}[1]{'nick'}, 'nfour', "tough order 8 - $db_type");

    is($objs->[1]{'nicks'}[0]{'nick'}, 'nthree', "tough order 9 - $db_type");
    is($objs->[1]{'nicks'}[1]{'nick'}, 'nsix', "tough order 10 - $db_type");
    is($objs->[1]{'nicks'}[2]{'nick'}, 'none', "tough order 11 - $db_type");
    is($objs->[1]{'nicks'}[3]{'nick'}, 'nfive', "tough order 12 - $db_type");

    is($objs->[2]{'nicks'}[0]{'nick'}, 'nseven', "tough order 13 - $db_type");

    is($objs->[3]{'nicks'}[0]{'nick'}, 'neight', "tough order 14 - $db_type");

    is($objs->[4]{'nicks'}[0]{'nick'}, 'nnine', "tough order 15 - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class    => 'MyOracleObject',
        require_objects => [ 'nicks' ],
        nonlazy         => 1,
        sort_by         => 'name');

    ok(@$objs == 5, "tough order 16 - $db_type");
    is($objs->[0]->id, 5, "tough order 17 - $db_type");
    is($objs->[1]->id, 10, "tough order 18 - $db_type");
    is($objs->[2]->id, 11, "tough order 19 - $db_type");
    is($objs->[3]->id, 12, "tough order 20 - $db_type");
    is($objs->[4]->id, 2, "tough order 21 - $db_type");

    is($objs->[0]{'nicks'}[0]{'nick'}, 'nthree', "tough order 22 - $db_type");
    is($objs->[0]{'nicks'}[1]{'nick'}, 'nsix', "tough order 23 - $db_type");
    is($objs->[0]{'nicks'}[2]{'nick'}, 'none', "tough order 24 - $db_type");
    is($objs->[0]{'nicks'}[3]{'nick'}, 'nfive', "tough order 25 - $db_type");
    is(scalar @{$objs->[0]{'nicks'}}, 4, "tough order 26 - $db_type");

    is($objs->[1]{'nicks'}[0]{'nick'}, 'nseven', "tough order 27 - $db_type");
    is(scalar @{$objs->[1]{'nicks'}}, 1, "tough order 28 - $db_type");

    is($objs->[2]{'nicks'}[0]{'nick'}, 'neight', "tough order 29 - $db_type");
    is(scalar @{$objs->[2]{'nicks'}}, 1, "tough order 30 - $db_type");

    is($objs->[3]{'nicks'}[0]{'nick'}, 'nnine', "tough order 31 - $db_type");
    is(scalar @{$objs->[3]{'nicks'}}, 1, "tough order 32 - $db_type");

    is($objs->[4]{'nicks'}[0]{'nick'}, 'ntwo', "tough order 33 - $db_type");
    is($objs->[4]{'nicks'}[1]{'nick'}, 'nfour', "tough order 34 - $db_type");
    is(scalar @{$objs->[4]{'nicks'}}, 2, "tough order 35 - $db_type");

    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MyOracleObject',
        require_objects => [ 'nicks' ],
        nonlazy         => 1,
        sort_by         => 'name');

    $o = $iterator->next;
    is($o->{'nicks'}[0]{'nick'}, 'nthree', "tough order 36 - $db_type");
    is($o->{'nicks'}[1]{'nick'}, 'nsix', "tough order 37 - $db_type");
    is($o->{'nicks'}[2]{'nick'}, 'none', "tough order 38 - $db_type");
    is($o->{'nicks'}[3]{'nick'}, 'nfive', "tough order 39 - $db_type");
    is(scalar @{$o->{'nicks'}}, 4, "tough order 40 - $db_type");

    $o = $iterator->next;
    is($o->{'nicks'}[0]{'nick'}, 'nseven', "tough order 41 - $db_type");
    is(scalar @{$o->{'nicks'}}, 1, "tough order 42 - $db_type");

    $o = $iterator->next;
    is($o->{'nicks'}[0]{'nick'}, 'neight', "tough order 43 - $db_type");
    is(scalar @{$o->{'nicks'}}, 1, "tough order 44 - $db_type");

    $o = $iterator->next;
    is($o->{'nicks'}[0]{'nick'}, 'nnine', "tough order 45 - $db_type");
    is(scalar @{$o->{'nicks'}}, 1, "tough order 46 - $db_type");

    $o = $iterator->next;
    is($o->{'nicks'}[0]{'nick'}, 'ntwo', "tough order 47 - $db_type");
    is($o->{'nicks'}[1]{'nick'}, 'nfour', "tough order 48 - $db_type");
    is(scalar @{$o->{'nicks'}}, 2, "tough order 49 - $db_type");

    ok(!$iterator->next, "tough order 50 - $db_type");
    is($iterator->total, 5, "tough order 51 - $db_type");

    # End tough order tests

    # Start deep join tests

    eval 
    { 
      Rose::DB::Object::Manager->get_objects(
        object_class => 'MyOracleObject',
        require_objects => [ 'nicks.type' ],
        with_objects    => [ 'nicks.type' ]);
    };

    ok($@, "deep join conflict 1 - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class => 'MyOracleObject',
        require_objects => [ 'nicks.type', 'nicks.type', 'nicks' ],
        with_objects    => [ 'nicks.type.t2', 'nicks.alts' ],
        multi_many_ok   => 1,
        query        => [ 'id' => [ 2, 5 ] ],
        sort_by      => 'type.name');

    ok(@$objs == 2, "deep join 1 - $db_type");
    is($objs->[0]->id, 2, "deep join 2 - $db_type");
    is($objs->[1]->id, 5, "deep join 3 - $db_type");

    is($objs->[0]{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join 4 - $db_type");
    is($objs->[0]{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join 5 - $db_type");
    is(scalar @{$objs->[0]{'nicks'}}, 2, "deep join 6 - $db_type");

    is($objs->[1]{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join 7 - $db_type");
    is($objs->[1]{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join 8 - $db_type");
    is($objs->[1]{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join 9 - $db_type");
    is($objs->[1]{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join 10 - $db_type");
    is(scalar @{$objs->[1]{'nicks'}}, 4, "deep join 11 - $db_type");

    is($objs->[0]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join 12 - $db_type");
    is($objs->[0]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join 13 - $db_type");

    is($objs->[0]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join 14 - $db_type");

    $objs->[1]{'nicks'}[1]{'alts'} = 
      [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[1]{'nicks'}[1]{'alts'}} ];
    is($objs->[1]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join 15 - $db_type");
    is($objs->[1]{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join 16 - $db_type");
    is($objs->[1]{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join 17 - $db_type");
    is(scalar @{$objs->[1]{'nicks'}[1]{'alts'}}, 3, "deep join 18 - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class => 'MyOracleObject',
        with_objects => [ 'nicks.type' ],
        nonlazy      => 1,
        sort_by      => 'type.name');

    ok(@$objs == 21, "deep join with 1 - $db_type");
    is($objs->[0]->id, 1, "deep join with 2 - $db_type");
    is($objs->[1]->id, 2, "deep join with 3 - $db_type");
    is($objs->[2]->id, 3, "deep join with 4 - $db_type");
    is($objs->[16]->id, 17, "deep join with 5 - $db_type");

    #SORT:
    #{
    #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
    #}

    is($objs->[1]{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join with 6 - $db_type");
    is($objs->[1]{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join with 7 - $db_type");
    is(scalar @{$objs->[1]{'nicks'}}, 2, "deep join with 8 - $db_type");

    #SORT:
    #{
    #  $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
    #}

    is($objs->[4]{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join with 9 - $db_type");
    is($objs->[4]{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join with 10 - $db_type");
    is($objs->[4]{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join with 11 - $db_type");
    is($objs->[4]{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join with 12 - $db_type");
    is(scalar @{$objs->[4]{'nicks'}}, 4, "deep join with 13 - $db_type");

    is(scalar @{$objs->[0]{'nicks'} ||= []}, 0, "deep join with 14 - $db_type");

    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class    => 'MyOracleObject',
        require_objects => [ 'nicks.type', 'nicks.type', 'nicks' ],
        with_objects    => [ 'nicks.type.t2', 'nicks.alts' ],
        multi_many_ok   => 1,
        query           => [ 'id' => [ 2, 5 ] ],
        sort_by         => 'type.name');

    $o = $iterator->next;
    is($o->{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join iterator 1 - $db_type");
    is($o->{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join iterator 2 - $db_type");
    is(scalar @{$o->{'nicks'}}, 2, "deep join iterator 3 - $db_type");

    is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join 3.1 - $db_type");

    is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator 3.1 - $db_type");
    is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator 3.2 - $db_type");

    $o = $iterator->next;
    is($o->{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join iterator 4 - $db_type");
    is($o->{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join iterator 5 - $db_type");
    is($o->{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join iterator 6 - $db_type");
    is($o->{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join iterator 7 - $db_type");
    is(scalar @{$o->{'nicks'}}, 4, "deep join iterator 8 - $db_type");

    $o->{'nicks'}[1]{'alts'} = 
      [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
    is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt one 1', "deep join iterator 9 - $db_type");
    is($o->{'nicks'}[1]{'alts'}[1]{'alt'}, 'alt one 2', "deep join iterator 10 - $db_type");
    is($o->{'nicks'}[1]{'alts'}[2]{'alt'}, 'alt one 3', "deep join iterator 11 - $db_type");
    is(scalar @{$o->{'nicks'}[1]{'alts'}}, 3, "deep join iterator 12 - $db_type");

    ok(!$iterator->next, "deep join iterator 13 - $db_type");
    is($iterator->total, 2, "deep join iterator 14 - $db_type");

    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class => 'MyOracleObject',
        with_objects => [ 'nicks.type' ],
        nonlazy      => 1,
        sort_by      => 'type.name');

    $o = $iterator->next;
    is($o->id, 1, "deep join with with iterator 1 - $db_type");

    $o = $iterator->next;

    #SORT:
    #{
    #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
    #}

    is($o->{'nicks'}[0]{'type'}{'name'}, 'nt four', "deep join with with iterator 1 - $db_type");
    is($o->{'nicks'}[1]{'type'}{'name'}, 'nt two', "deep join with iterator 2 - $db_type");
    is(scalar @{$o->{'nicks'}}, 2, "deep join with iterator 3 - $db_type");

    $o = $iterator->next;
    $o = $iterator->next;

    $o = $iterator->next;

    #SORT:
    #{
    #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
    #}

    is($o->{'nicks'}[0]{'type'}{'name'}, 'nt five', "deep join with iterator 4 - $db_type");
    is($o->{'nicks'}[1]{'type'}{'name'}, 'nt one', "deep join with iterator 5 - $db_type");
    is($o->{'nicks'}[2]{'type'}{'name'}, 'nt six', "deep join with iterator 6 - $db_type");
    is($o->{'nicks'}[3]{'type'}{'name'}, 'nt three', "deep join with iterator 7 - $db_type");
    is(scalar @{$o->{'nicks'}}, 4, "deep join with iterator 8 - $db_type");

    while($iterator->next) { }
    is($iterator->total, 21, "deep join iterator 9 - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class => 'MyOracleObject',
        require_objects => [ 'nicks.type.t2' ],
        query        => [ 'id' => [ 2, 5 ] ],
        nonlazy      => 1,
        sort_by      => 'type.name');

    ok(@$objs == 2, "deep join three-level 1 - $db_type");
    is($objs->[0]->id, 2, "deep join three-level 2 - $db_type");
    is($objs->[1]->id, 5, "deep join three-level 3 - $db_type");

    #SORT:
    #{
    #  $objs->[0]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[0]{'nicks'}} ];
    #}

    is($objs->[0]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join three-level 4 - $db_type");
    is($objs->[0]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join three-level 5 - $db_type");
    is(scalar @{$objs->[0]{'nicks'}}, 2, "deep join three-level 6 - $db_type");

    #SORT:
    #{
    #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
    #}

    is($objs->[1]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join three-level 7 - $db_type");
    is($objs->[1]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join three-level 8 - $db_type");
    is($objs->[1]{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join three-level 9 - $db_type");
    is($objs->[1]{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join three-level 10 - $db_type");
    is(scalar @{$objs->[1]{'nicks'}}, 4, "deep join three-level 11 - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class => 'MyOracleObject',
        with_objects => [ 'nicks.type.t2' ],
        nonlazy      => 1,
        sort_by      => 'type.name');

    ok(@$objs == 21, "deep join three-level 1 - $db_type");
    is($objs->[0]->id, 1, "deep join three-level 2 - $db_type");
    is($objs->[1]->id, 2, "deep join three-level 3 - $db_type");
    is($objs->[4]->id, 5, "deep join three-level 4 - $db_type");
    is($objs->[20]->id, 60, "deep join three-level 5 - $db_type");

    #SORT:
    #{
    #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
    #}

    is($objs->[1]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join three-level 6 - $db_type");
    is($objs->[1]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join three-level 7 - $db_type");
    is(scalar @{$objs->[1]{'nicks'}}, 2, "deep join three-level 8 - $db_type");

    #SORT:
    #{
    #  $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
    #}

    is($objs->[4]{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join three-level 9 - $db_type");
    is($objs->[4]{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join three-level 10 - $db_type");
    is($objs->[4]{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join three-level 11 - $db_type");
    is($objs->[4]{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join three-level 12 - $db_type");
    is(scalar @{$objs->[4]{'nicks'}}, 4, "deep join three-level 13 - $db_type");

    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class => 'MyOracleObject',
        require_objects => [ 'nicks.type.t2' ],
        query        => [ 'id' => [ 2, 5 ] ],
        sort_by      => 'type.name');

    $o = $iterator->next;
    is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator 1 - $db_type");
    is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator 2 - $db_type");
    is(scalar @{$o->{'nicks'}}, 2, "deep join iterator 3 - $db_type");

    $o = $iterator->next;
    is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join iterator 4 - $db_type");
    is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join iterator 5 - $db_type");
    is($o->{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join iterator 6 - $db_type");
    is($o->{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join iterator 7 - $db_type");
    is(scalar @{$o->{'nicks'}}, 4, "deep join iterator 8 - $db_type");

    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class => 'MyOracleObject',
        with_objects => [ 'nicks.type.t2' ],
        nonlazy      => 1,
        sort_by      => 'type.name');

    $o = $iterator->next;
    $o = $iterator->next;

    #SORT:
    #{
    #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
    #}

    is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 four', "deep join iterator with 1 - $db_type");
    is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 two', "deep join iterator with 2 - $db_type");
    is(scalar @{$o->{'nicks'}}, 2, "deep join iterator with 3 - $db_type");

    $o = $iterator->next;
    $o = $iterator->next;

    $o = $iterator->next;

    #SORT:
    #{
    #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
    #}

    is($o->{'nicks'}[0]{'type'}{'t2'}{'name'}, 'nt2 five', "deep join iterator with 4 - $db_type");
    is($o->{'nicks'}[1]{'type'}{'t2'}{'name'}, 'nt2 one', "deep join iterator with 5 - $db_type");
    is($o->{'nicks'}[2]{'type'}{'t2'}{'name'}, 'nt2 six', "deep join iterator with 6 - $db_type");
    is($o->{'nicks'}[3]{'type'}{'t2'}{'name'}, 'nt2 three', "deep join iterator with 7 - $db_type");
    is(scalar @{$o->{'nicks'}}, 4, "deep join iterator with 8 - $db_type");

    while($iterator->next) { }
    is($iterator->total, 21, "deep join iterator with 9 - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class => 'MyOracleObject',
        require_objects => [ 'nicks.alts' ],
        multi_many_ok => 1,
        query        => [ 'id' => [ 2, 5 ] ],
        sort_by      => 'alts.alt');

    ok(@$objs == 2, "deep join multi 1 - $db_type");
    is($objs->[0]->id, 2, "deep join multi 2 - $db_type");
    is($objs->[1]->id, 5, "deep join multi 3 - $db_type");

    is($objs->[0]{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi 4 - $db_type");
    is(scalar @{$objs->[0]{'nicks'}[0]{'alts'}}, 1, "deep join multi 5 - $db_type");

    is($objs->[1]{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi 6 - $db_type");
    is($objs->[1]{'nicks'}[0]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi 7 - $db_type");
    is($objs->[1]{'nicks'}[0]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi 8 - $db_type");
    is(scalar @{$objs->[1]{'nicks'}[0]{'alts'}}, 3, "deep join multi 11 - $db_type");

    $objs = 
      Rose::DB::Object::Manager->get_objects(
        object_class  => 'MyOracleObject',
        with_objects  => [ 'nicks.alts' ],
        multi_many_ok => 1,
        nonlazy       => 1,
        sort_by       => 'alts.alt DESC');

    ok(@$objs == 21, "deep join multi with 1 - $db_type");
    is($objs->[1]->id, 2, "deep join multi with 2 - $db_type");
    is($objs->[4]->id, 5, "deep join multi with 3 - $db_type");

    #SORT:
    #{
    #  $objs->[1]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[1]{'nicks'}} ];
    #  $objs->[1]{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[1]{'nicks'}[1]{'alts'}} ];
    #}

    is($objs->[1]{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi with with 4 - $db_type");
    is(scalar @{$objs->[1]{'nicks'}[1]{'alts'}}, 1, "deep join multi with 5 - $db_type");

    #SORT:
    #{
    #  $objs->[4]{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$objs->[4]{'nicks'}} ];
    #  $objs->[4]{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$objs->[4]{'nicks'}[3]{'alts'}} ];
    #}

    is($objs->[4]{'nicks'}[3]{'alts'}[0]{'alt'}, 'alt one 3', "deep join multi with 6 - $db_type");
    is($objs->[4]{'nicks'}[3]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi with 7 - $db_type");
    is($objs->[4]{'nicks'}[3]{'alts'}[2]{'alt'}, 'alt one 1', "deep join multi with 8 - $db_type");
    is(scalar @{$objs->[4]{'nicks'}[3]{'alts'}}, 3, "deep join multi with 11 - $db_type");

    is(scalar @{$objs->[0]{'nicks'} || []}, 0, "deep join multi with 12 - $db_type");

    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class => 'MyOracleObject',
        require_objects => [ 'nicks.alts' ],
        multi_many_ok => 1,
        query        => [ 'id' => [ 2, 5 ] ],
        sort_by      => 'alts.alt');

    $o = $iterator->next;
    is($o->id, 2, "deep join multi iter 1 - $db_type");
    is($o->{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi iter 2 - $db_type");
    is(scalar @{$o->{'nicks'}[0]{'alts'}}, 1, "deep join multi iter 3 - $db_type");

    $o = $iterator->next;
    is($o->{'nicks'}[0]{'alts'}[0]{'alt'}, 'alt one 1', "deep join multi iter 4 - $db_type");
    is($o->{'nicks'}[0]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi iter 5 - $db_type");
    is($o->{'nicks'}[0]{'alts'}[2]{'alt'}, 'alt one 3', "deep join multi iter 6 - $db_type");
    is(scalar @{$o->{'nicks'}[0]{'alts'}}, 3, "deep join multi iter 7 - $db_type");

    ok(!$iterator->next, "deep join multi iter 8 - $db_type");
    is($iterator->total, 2, "deep join multi iter 9 - $db_type");

    $iterator = 
      Rose::DB::Object::Manager->get_objects_iterator(
        object_class  => 'MyOracleObject',
        with_objects  => [ 'nicks.alts' ],
        multi_many_ok => 1,
        nonlazy       => 1,
        #query => [ id => 2 ],
        sort_by       => 'alts.alt DESC');

    $o = $iterator->next;
    is(scalar @{$o->{'nicks'} ||= []}, 0, "deep join multi iter with 1 - $db_type");

    $o = $iterator->next;

    #SORT:
    #{
    #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
    #  $o->{'nicks'}[1]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[1]{'alts'}} ];
    #}

    is($o->id, 2, "deep join multi iter with 2 - $db_type");
    is($o->{'nicks'}[1]{'alts'}[0]{'alt'}, 'alt two 1', "deep join multi iter with 3 - $db_type");
    is(scalar @{$o->{'nicks'}[1]{'alts'}}, 1, "deep join multi iter with 4 - $db_type");

    $o = $iterator->next;
    $o = $iterator->next;

    $o = $iterator->next;

    #SORT:
    #{
    #  $o->{'nicks'} = [ sort { $a->{'nick'} cmp $b->{'nick'} } @{$o->{'nicks'}} ];
    #  $o->{'nicks'}[3]{'alts'} = [ sort { $a->{'alt'} cmp $b->{'alt'} } @{$o->{'nicks'}[3]{'alts'}} ];
    #}

    is($o->{'nicks'}[3]{'alts'}[0]{'alt'}, 'alt one 3', "deep join multi iter with 5 - $db_type");
    is($o->{'nicks'}[3]{'alts'}[1]{'alt'}, 'alt one 2', "deep join multi iter with 6 - $db_type");
    is($o->{'nicks'}[3]{'alts'}[2]{'alt'}, 'alt one 1', "deep join multi iter with 7 - $db_type");
    is(scalar @{$o->{'nicks'}[3]{'alts'}}, 3, "deep join multi iter with 8 - $db_type");

    while($iterator->next) { }
    is($iterator->total, 21, "deep join multi iter with 9 - $db_type");

    # End deep join tests

    # Start custom select tests

    my @selects =
    (
      't2.nick, id, t2.id, name, UPPER(name) AS derived, fk1',
      't1.id, t2.nick, t2.id, t1.name, UPPER(name) AS derived, t1.fk1',
      'rose_db_object_nicks.id, rose_db_object_test.id, rose_db_object_nicks.nick, rose_db_object_test.name, UPPER(name) AS derived',
      [ \q(t1.id + 0 AS id), qw(name t2.nick nicks.id), \q(UPPER(name) AS derived) ],
      [ qw(t2.nick t2.id t1.id t1.name), 'UPPER(name) AS derived' ],
      [ \q(UPPER(name) AS derived), qw(t2.id rose_db_object_nicks.nick rose_db_object_test.id rose_db_object_test.name) ],
      [ qw(rose_db_object_test.id rose_db_object_nicks.nick rose_db_object_test.name rose_db_object_nicks.id), 'UPPER(name) AS derived' ],
      [ qw(rose_db_object_test.id rose_db_object_test.name rose_db_object_nicks.nick t2.id), 'UPPER(name) AS derived' ],
    );

    $i = 0;

    #local $Rose::DB::Object::Manager::Debug = 1;

    foreach my $select (@selects)
    {
      $iterator = 
        Rose::DB::Object::Manager->get_objects_iterator(
          object_class    => 'MyOracleObject',
          select          => $select,
          require_objects => [ 'nicks' ],
          query           => [ id => { gt => 2 } ],
          sort_by         => 'id',
          limit           => 2);

      $i++;

      $o = $iterator->next;

      ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
         !defined $o->nicks->[0]->type_id && !defined $o->flag2 &&
         $o->derived eq 'DERIVED: ' . uc($o->name),
         "custom select $i - $db_type");

      $i++;

      $o = $iterator->next;
      ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
         !defined $o->nicks->[0]->type_id && !defined $o->flag2 &&
         $o->derived eq 'DERIVED: ' . uc($o->name),
         "custom select $i - $db_type");

      $i++;
      ok(!$iterator->next, "custom select $i - $db_type");

      $objs = 
        Rose::DB::Object::Manager->get_objects(
          object_class    => 'MyOracleObject',
          select          => $select,
          require_objects => [ 'nicks' ],
          query           => [ id => { gt => 2 } ],
          sort_by         => 'id',
          limit           => 2);

      $i++;

      ok($objs->[0]->id > 2 && defined $objs->[0]->name && defined $objs->[0]->nicks->[0]->nick &&
         !defined $objs->[0]->nicks->[0]->type_id && !defined $objs->[0]->flag2 &&
         $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
         "custom select $i - $db_type");

      $i++;

      ok($objs->[1]->id > 2 && defined $objs->[1]->name && defined $objs->[1]->nicks->[0]->nick &&
         !defined $objs->[1]->nicks->[0]->type_id && !defined $objs->[1]->flag2 &&
         $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
         "custom select $i - $db_type");

      $i++;
      is(scalar @$objs, 2, "custom select $i - $db_type");
    }

    @selects =
    (
      #'t2.nick, t1.*, t2.id, t1.name, UPPER(t1.name) AS derived',
      [ qw(t2.nick t2.id t1.*), 'UPPER(t1.name) AS derived' ],
    );

    #local $Rose::DB::Object::Manager::Debug = 1;

    foreach my $select (@selects)
    {
      $iterator = 
        Rose::DB::Object::Manager->get_objects_iterator(
          object_class    => 'MyOracleObject',
          select          => $select,
          require_objects => [ 'nicks' ],
          query           => [ id => { gt => 2 } ],
          sort_by         => 't1.id',
          limit           => 2);

      $i++;

      $o = $iterator->next;

      ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
         !defined $o->nicks->[0]->type_id && defined $o->flag2 &&
         $o->derived eq 'DERIVED: ' . uc($o->name),
         "custom select $i - $db_type");

      $i++;

      $o = $iterator->next;
      ok($o->id > 2 && defined $o->name && defined $o->nicks->[0]->nick &&
         !defined $o->nicks->[0]->type_id && defined $o->flag2 &&
         $o->derived eq 'DERIVED: ' . uc($o->name),
         "custom select $i - $db_type");

      $i++;
      ok(!$iterator->next, "custom select $i - $db_type");

      $objs = 
        Rose::DB::Object::Manager->get_objects(
          object_class    => 'MyOracleObject',
          select          => $select,
          require_objects => [ 'nicks' ],
          query           => [ id => { gt => 2 } ],
          sort_by         => 't1.id',
          limit           => 2);

      $i++;

      ok($objs->[0]->id > 2 && defined $objs->[0]->name && defined $objs->[0]->nicks->[0]->nick &&
         !defined $objs->[0]->nicks->[0]->type_id && defined $objs->[0]->flag2 &&
         $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
         "custom select $i - $db_type");

      $i++;

      ok($objs->[1]->id > 2 && defined $objs->[1]->name && defined $objs->[1]->nicks->[0]->nick &&
         !defined $objs->[1]->nicks->[0]->type_id && defined $objs->[1]->flag2 &&
         $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
         "custom select $i - $db_type");

      $i++;
      is(scalar @$objs, 2, "custom select $i - $db_type");
    }

    @selects =
    (
      '*, UPPER(t1.name) AS derived',
      [ '*', 'UPPER(t1.name) AS derived' ],
    );

    #local $Rose::DB::Object::Manager::Debug = 1;

    foreach my $select (@selects)
    {
      $iterator = 
        Rose::DB::Object::Manager->get_objects_iterator(
          object_class    => 'MyOracleObject',
          select          => $select,
          query           => [ id => { gt => 2 } ],
          sort_by         => 't1.id',
          limit           => 2);

      $i++;

      $o = $iterator->next;

      ok($o->id > 2 && defined $o->name && defined $o->flag2 && 
         $o->derived eq 'DERIVED: ' . uc($o->name),
         "custom select $i - $db_type");

      $i++;

      $o = $iterator->next;
      ok($o->id > 2 && defined $o->name && defined $o->flag2 &&
         $o->derived eq 'DERIVED: ' . uc($o->name),
         "custom select $i - $db_type");

      $i++;
      ok(!$iterator->next, "custom select $i - $db_type");

      $objs = 
        Rose::DB::Object::Manager->get_objects(
          object_class    => 'MyOracleObject',
          select          => $select,
          query           => [ id => { gt => 2 } ],
          sort_by         => 't1.id',
          limit           => 2);

      $i++;

      ok($objs->[0]->id > 2 && defined $objs->[0]->name && 
         defined $objs->[0]->flag2 && $objs->[0]->derived eq 'DERIVED: ' . uc($objs->[0]->name),
         "custom select $i - $db_type");

      $i++;

      ok($objs->[1]->id > 2 && defined $objs->[1]->name && 
         defined $objs->[1]->flag2 && $objs->[1]->derived eq 'DERIVED: ' . uc($objs->[1]->name),
         "custom select $i - $db_type");

      $i++;
      is(scalar @$objs, 2, "custom select $i - $db_type");
    }
  }

  # End custom select tests
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

    Rose::DB->default_type('pg');

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_color_map CASCADE');
      $dbh->do('DROP TABLE rose_db_object_colors CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nicks CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_types2 CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_types CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nicks2 CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_alts CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_opts CASCADE');
      $dbh->do('DROP TABLE rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE rose_db_object_other CASCADE');
      $dbh->do('DROP TABLE rose_db_object_bb CASCADE');
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
CREATE TABLE rose_db_object_bb
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(32)
)
EOF

    # Create test foreign subclasses

    package MyPgOtherObject;

    our @ISA = qw(Rose::DB::Object);

    MyPgOtherObject->meta->table('rose_db_object_other');

    MyPgOtherObject->meta->columns
    (
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int' },
      k3   => { type => 'int' },
    );

    MyPgOtherObject->meta->primary_key_columns(qw(k1 k2 k3));

    MyPgOtherObject->meta->initialize;

    package MyPgBB;

    our @ISA = qw(Rose::DB::Object);

    MyPgBB->meta->table('rose_db_object_bb');

    MyPgBB->meta->columns
    (
      id   => { type => 'int', primary_key => 1 },
      name => { type => 'varchar'},
    );

    MyPgBB->meta->initialize;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INT NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           BIT(5) NOT NULL DEFAULT B'00101',
  fixed          CHAR(16) DEFAULT 'needed',
  start          DATE,
  save           INT,
  nums           INT[],
  fk1            INT,
  fk2            INT,
  fk3            INT,
  b1             INT REFERENCES rose_db_object_bb (id),
  b2             INT REFERENCES rose_db_object_bb (id),
  data           BYTEA,
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_types2
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL UNIQUE
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_types
(
  id     SERIAL NOT NULL PRIMARY KEY,
  name   VARCHAR(32) NOT NULL UNIQUE,
  t2_id  INT REFERENCES rose_db_object_nick_types2 (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nicks
(
  id    SERIAL NOT NULL PRIMARY KEY,
  o_id  INT NOT NULL REFERENCES rose_db_object_test (id),
  nick  VARCHAR(32),
  type_id INT REFERENCES rose_db_object_nick_types (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_alts
(
  id       SERIAL NOT NULL PRIMARY KEY,
  nick_id  INT NOT NULL REFERENCES rose_db_object_nicks (id),
  alt      VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_opts
(
  id       SERIAL NOT NULL PRIMARY KEY,
  nick_id  INT NOT NULL REFERENCES rose_db_object_nicks (id),
  opt      VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nicks2
(
  id     SERIAL NOT NULL PRIMARY KEY,
  o_id   INT NOT NULL REFERENCES rose_db_object_test (id),
  nick2  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors
(
  id     SERIAL NOT NULL PRIMARY KEY,
  name   VARCHAR(32) NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_color_map
(
  id         SERIAL NOT NULL PRIMARY KEY,
  object_id  INT NOT NULL REFERENCES rose_db_object_test (id),
  color_id   INT NOT NULL REFERENCES rose_db_object_colors (id)
)
EOF

    $dbh->disconnect;

    package MyPgNickType2;

    our @ISA = qw(Rose::DB::Object);

    MyPgNickType2->meta->table('rose_db_object_nick_types2');

    MyPgNickType2->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      name    => { type => 'varchar', length => 32 },
    );

    MyPgNickType2->meta->add_unique_key('name');
    MyPgNickType2->meta->initialize;

    package MyPgNickType;

    our @ISA = qw(Rose::DB::Object);

    MyPgNickType->meta->table('rose_db_object_nick_types');

    MyPgNickType->meta->columns
    (
      id    => { type => 'serial', primary_key => 1 },
      name  => { type => 'varchar', length => 32 },
      t2_id => { type => 'int' },
    );

    MyPgNickType->meta->add_unique_key('name');

    MyPgNickType->meta->foreign_keys
    (
      t2 =>
      {
        class => 'MyPgNickType2',
        key_columns => { t2_id => 'id' },
      }
    );

    MyPgNickType->meta->initialize;

    package MyPgNick;

    our @ISA = qw(Rose::DB::Object);

    MyPgNick->meta->table('rose_db_object_nicks');

    MyPgNick->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      o_id => { type => 'int' },
      nick => { type => 'varchar', lazy => 1 },
      type_id => { type => 'int' },
    );

    MyPgNick->meta->foreign_keys
    (
      obj =>
      {
        class => 'MyPgObject',
        key_columns => { o_id => 'id' },
      },

      type =>
      {
        class => 'MyPgNickType',
        key_columns => { type_id => 'id' },
      },
    );

    MyPgNick->meta->relationships
    (
      alts =>
      {
        type  => 'one to many',
        class => 'MyPgNickAlt',
        key_columns => { id => 'nick_id' },
      },

      opts =>
      {
        type  => 'one to many',
        class => 'MyPgNickOpt',
        key_columns => { id => 'nick_id' },
      },
    );

    MyPgNick->meta->initialize;

    package MyPgNick2;

    our @ISA = qw(Rose::DB::Object);

    MyPgNick2->meta->table('rose_db_object_nicks2');

    MyPgNick2->meta->columns
    (
      id    => { type => 'serial', primary_key => 1 },
      o_id  => { type => 'int' },
      nick2 => { type => 'varchar'},
    );

    MyPgNick2->meta->foreign_keys
    (
      obj =>
      {
        class => 'MyPgObject',
        key_columns => { o_id => 'id' },
      },
    );

    MyPgNick2->meta->initialize;

    package MyPgNickAlt;

    our @ISA = qw(Rose::DB::Object);

    MyPgNickAlt->meta->table('rose_db_object_nick_alts');

    MyPgNickAlt->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      nick_id => { type => 'int' },
      alt     => { type => 'varchar' },
    );

    MyPgNickAlt->meta->foreign_keys
    (
      type =>
      {
        class => 'MyPgNick',
        key_columns => { nick_id => 'id' },
      },
    );

    MyPgNickAlt->meta->initialize;

    package MyPgNickOpt;

    our @ISA = qw(Rose::DB::Object);

    MyPgNickOpt->meta->table('rose_db_object_nick_opts');

    MyPgNickOpt->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      nick_id => { type => 'int' },
      opt     => { type => 'varchar' },
    );

    MyPgNickOpt->meta->foreign_keys
    (
      type =>
      {
        class => 'MyPgNick',
        key_columns => { nick_id => 'id' },
      },
    );

    MyPgNickOpt->meta->initialize;

    package MyPgColor;

    our @ISA = qw(Rose::DB::Object);

    MyPgColor->meta->table('rose_db_object_colors');

    MyPgColor->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', not_null => 1 },
    );

    MyPgColor->meta->relationships
    (
      objects =>
      {
        type      => 'many to many',
        map_class => 'MyPgColorMap',
      },
    );

    MyPgColor->meta->initialize;

    package MyPgColorMap;

    our @ISA = qw(Rose::DB::Object);

    MyPgColorMap->meta->table('rose_db_object_color_map');

    MyPgColorMap->meta->columns
    (
      id        => { type => 'serial', primary_key => 1 },
      object_id => { type => 'int', not_null => 1 },
      color_id  => { type => 'int', not_null => 1 },
    );

    MyPgColorMap->meta->foreign_keys
    (
      color =>
      {
        class => 'MyPgColor',
        key_columns => { color_id => 'id' },
      },

      object =>
      {
        class => 'MyPgObject',
        key_columns => { object_id => 'id' },
      },
    );

    MyPgColorMap->meta->initialize;

    # Create test subclass

    package MyPgObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub extra { $_[0]->{'extra'} = $_[1]  if(@_ > 1); $_[0]->{'extra'} }

    MyPgObject->meta->table('rose_db_object_test');

    MyPgObject->meta->columns
    (
      'name',
      id       => { primary_key => 1 },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active', lazy => 1 },
      start    => { type => 'date', default => '12/24/1980', lazy => 1 },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      bits     => { type => 'bitfield', bits => 5, default => 101 },
      fixed    => { type => 'char', length => 16, default => 'needed' },,
      fk1      => { type => 'int' },
      fk2      => { type => 'int' },
      fk3      => { type => 'int' },
      b1       => { type => 'int' },
      b2       => { type => 'int' },
      data     => { type => 'bytea' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    sub derived 
    {
      return 'DERIVED: ' . $_[0]->{'derived'}  if(@_ == 1);
      return $_[0]->{'derived'} = $_[1] 
    }

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
        }
      },

      bb1 =>
      {
        class => 'MyPgBB',
        key_columns => { b1 => 'id' },
      },

      bb2 =>
      {
        class => 'MyPgBB',
        key_columns => { b2 => 'id' },
      },
    );

    MyPgObject->meta->relationships
    (
      nicks =>
      {
        type  => 'one to many',
        class => 'MyPgNick',
        column_map => { id => 'o_id' },
        manager_args => { sort_by => 'nick DESC' },
      },

      nicks2 =>
      {
        type  => 'one to many',
        class => 'MyPgNick2',
        column_map => { id => 'o_id' },
        manager_args => { sort_by => 'nick2 DESC' },
      },

      colors =>
      {
        type      => 'many to many',
        map_class => 'MyPgColorMap',
        manager_args => { sort_by => MyPgColor->meta->table . '.name DESC' },
      },
    );

    MyPgObject->meta->alias_column(fk1 => 'fkone');

    eval { MyPgObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method - pg');

    MyPgObject->meta->alias_column(save => 'save_col');
    MyPgObject->meta->initialize(preserve_existing => 1);

    Rose::DB::Object::Manager->make_manager_methods(base_name => 'objectz');

    eval { Rose::DB::Object::Manager->make_manager_methods('objectz') };
    Test::More::ok($@, 'make_manager_methods clash - pg');

    Test::More::is(MyPgObject->meta->perl_manager_class(class => 'MyPgObjectMgr'), 
                  <<"EOF", 'perl_manager_class - pg');
package MyPgObjectMgr;

use strict;

use Rose::DB::Object::Manager;
our \@ISA = qw(Rose::DB::Object::Manager);

sub object_class { 'MyPgObject' }

__PACKAGE__->make_manager_methods('my_pg_objects');

1;
EOF

    eval { MyPgObject->meta->perl_manager_class(class => 'MyPgObjectMgr') };
    Test::More::ok(!$@, 'make_manager_class - pg');

    package MyPgObjectManager;
    our @ISA = qw(Rose::DB::Object::Manager);

    sub object_class { 'MyPgObject' }

    MyPgObjectManager->make_manager_methods(object_class => 'MyPgObject',
                                            methods =>
                                            {
                                              objectz => [ qw(objects iterator) ],
                                              'object_count()' => 'count'
                                            });
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

    Rose::DB->default_type('mysql');

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_color_map CASCADE');
      $dbh->do('DROP TABLE rose_db_object_colors CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nicks CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_types2 CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_types CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nicks2 CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_alts CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_opts CASCADE');
      $dbh->do('DROP TABLE rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE rose_db_object_other CASCADE');
      $dbh->do('DROP TABLE rose_db_object_bb CASCADE');
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
CREATE INDEX rose_db_object_other_idx ON rose_db_object_other (name)
EOF

    $dbh->do(<<"EOF");
CREATE INDEX rose_db_object_other_idx2 ON rose_db_object_other (k1)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_bb
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(32)
)
EOF

    # Create test foreign subclasses

    package MyMySQLOtherObject;

    our @ISA = qw(Rose::DB::Object);

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

    package MyMySQLBB;

    our @ISA = qw(Rose::DB::Object);

    MyMySQLBB->meta->table('rose_db_object_bb');

    MyMySQLBB->meta->columns
    (
      id   => { type => 'int', primary_key => 1 },
      name => { type => 'varchar'},
    );

    MyMySQLBB->meta->initialize;

    # MySQL 5.0.3 or later has a completely stupid "native" BIT type
    my $bit_col = 
      ($db_version >= 5_000_003) ?
        q(bits  BIT(5) NOT NULL DEFAULT B'00101') :
        q(bits  BIT(5) NOT NULL DEFAULT '00101');

    my $set_col = 
      ($db_version >= 5_000_000) ?
        q(items  SET('a','b','c') NOT NULL DEFAULT 'a,c') :
        q(items  VARCHAR(255) NOT NULL DEFAULT 'a,c');

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  flag           TINYINT(1) NOT NULL,
  flag2          TINYINT(1),
  status         VARCHAR(32) DEFAULT 'active',
  $bit_col,
  $set_col,
  fixed          CHAR(16) DEFAULT 'needed',
  nums           VARCHAR(255),
  start          DATE,
  save           INT,
  fk1            INT,
  fk2            INT,
  fk3            INT,
  b1             INT,
  b2             INT,
  last_modified  TIMESTAMP,
  date_created   DATETIME
)
EOF

    $dbh->do(<<"EOF");
CREATE INDEX rose_db_object_test_idx ON rose_db_object_test (name)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_types2
(
  id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(32) NOT NULL UNIQUE
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_types
(
  id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name   VARCHAR(32) NOT NULL UNIQUE,
  t2_id  INT REFERENCES rose_db_object_nick_types2 (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nicks
(
  id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  o_id  INT UNSIGNED NOT NULL REFERENCES rose_db_object_test (id),
  nick  VARCHAR(32),
  type_id INT REFERENCES rose_db_object_nick_types (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE INDEX rose_db_object_nicks_idx ON rose_db_object_nicks (nick)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_alts
(
  id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nick_id  INT NOT NULL REFERENCES rose_db_object_nicks (id),
  alt      VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_opts
(
  id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nick_id  INT NOT NULL REFERENCES rose_db_object_nicks (id),
  opt      VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nicks2
(
  id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  o_id   INT UNSIGNED NOT NULL REFERENCES rose_db_object_test (id),
  nick2  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors
(
  id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name   VARCHAR(32) NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_color_map
(
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  object_id  INT UNSIGNED NOT NULL REFERENCES rose_db_object_test (id),
  color_id   INT UNSIGNED NOT NULL REFERENCES rose_db_object_colors (id)
)
EOF

    $dbh->disconnect;

    package MyMySQLNickType2;

    our @ISA = qw(Rose::DB::Object);

    MyMySQLNickType2->meta->table('rose_db_object_nick_types2');

    MyMySQLNickType2->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      name    => { type => 'varchar', length => 32 },
    );

    MyMySQLNickType2->meta->add_unique_key('name');
    MyMySQLNickType2->meta->initialize;

    package MyMySQLNickType;

    our @ISA = qw(Rose::DB::Object);

    MyMySQLNickType->meta->table('rose_db_object_nick_types');

    MyMySQLNickType->meta->columns
    (
      id    => { type => 'serial', primary_key => 1 },
      name  => { type => 'varchar', length => 32 },
      t2_id => { type => 'int' },
    );

    MyMySQLNickType->meta->add_unique_key('name');

    MyMySQLNickType->meta->foreign_keys
    (
      t2 =>
      {
        class => 'MyMySQLNickType2',
        key_columns => { t2_id => 'id' },
      }
    );

    MyMySQLNickType->meta->initialize;

    package MyMySQLNick;

    our @ISA = qw(Rose::DB::Object);

    MyMySQLNick->meta->table('rose_db_object_nicks');

    MyMySQLNick->meta->columns
    (
      id   => { type => 'int', primary_key => 1 },
      o_id => { type => 'int' },
      nick => { type => 'varchar', lazy => 1 },
      type_id => { type => 'int' },
    );

    MyMySQLNick->meta->relationships
    (
      alts =>
      {
        type  => 'one to many',
        class => 'MyMySQLNickAlt',
        key_columns => { id => 'nick_id' },
      },

      opts =>
      {
        type  => 'one to many',
        class => 'MyMySQLNickOpt',
        key_columns => { id => 'nick_id' },
      },
    );

    MyMySQLNick->meta->foreign_keys
    (
      obj =>
      {
        class => 'MyMySQLObject',
        key_columns => { o_id => 'id' },
      },

      type =>
      {
        class => 'MyMySQLNickType',
        key_columns => { type_id => 'id' },
      },
    );

    MyMySQLNick->meta->initialize;

    package MyMySQLNick2;

    our @ISA = qw(Rose::DB::Object);

    MyMySQLNick2->meta->table('rose_db_object_nicks2');

    MyMySQLNick2->meta->columns
    (
      id    => { type => 'int', primary_key => 1 },
      o_id  => { type => 'int' },
      nick2 => { type => 'varchar'},
    );

    MyMySQLNick2->meta->foreign_keys
    (
      obj =>
      {
        class => 'MyMySQLObject',
        key_columns => { o_id => 'id' },
      },
    );

    MyMySQLNick2->meta->initialize;

    package MyMySQLNickAlt;

    our @ISA = qw(Rose::DB::Object);

    MyMySQLNickAlt->meta->table('rose_db_object_nick_alts');

    MyMySQLNickAlt->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      nick_id => { type => 'int' },
      alt     => { type => 'varchar' },
    );

    MyMySQLNickAlt->meta->foreign_keys
    (
      type =>
      {
        class => 'MyMySQLNick',
        key_columns => { nick_id => 'id' },
      },
    );

    MyMySQLNickAlt->meta->initialize;

    package MyMySQLNickOpt;

    our @ISA = qw(Rose::DB::Object);

    MyMySQLNickOpt->meta->table('rose_db_object_nick_opts');

    MyMySQLNickOpt->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      nick_id => { type => 'int' },
      opt     => { type => 'varchar' },
    );

    MyMySQLNickOpt->meta->foreign_keys
    (
      type =>
      {
        class => 'MyMySQLNick',
        key_columns => { nick_id => 'id' },
      },
    );

    MyMySQLNickOpt->meta->initialize;

    package MyMySQLColor;

    our @ISA = qw(Rose::DB::Object);

    MyMySQLColor->meta->table('rose_db_object_colors');

    MyMySQLColor->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', not_null => 1 },
    );

    MyMySQLColor->meta->relationships
    (
      objects =>
      {
        type      => 'many to many',
        map_class => 'MyMySQLColorMap',
      },
    );

    MyMySQLColor->meta->initialize;

    package MyMySQLColorMap;

    our @ISA = qw(Rose::DB::Object);

    MyMySQLColorMap->meta->table('rose_db_object_color_map');

    MyMySQLColorMap->meta->columns
    (
      id        => { type => 'serial', primary_key => 1 },
      object_id => { type => 'int', not_null => 1 },
      color_id  => { type => 'int', not_null => 1 },
    );

    MyMySQLColorMap->meta->foreign_keys
    (
      color =>
      {
        class => 'MyMySQLColor',
        key_columns => { color_id => 'id' },
      },

      object =>
      {
        class => 'MyMySQLObject',
        key_columns => { object_id => 'id' },
      },
    );

    MyMySQLColorMap->meta->initialize;

    # Create test subclass

    package MyMySQLObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub extra { $_[0]->{'extra'} = $_[1]  if(@_ > 1); $_[0]->{'extra'} }

    MyMySQLObject->meta->allow_inline_column_values(1);

    MyMySQLObject->meta->table('rose_db_object_test');

    MyMySQLObject->meta->columns
    (
      'name',
      id       => { primary_key => 1 },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active', lazy => 1 },
      start    => { type => 'date', default => '12/24/1980', lazy => 1 },
      save     => { type => 'scalar' },
      bits     => { type => 'bitfield', bits => 5, default => 101 },
      items    => { type => 'set', check_in => [ qw(a b c) ], default => 'a,c' },
      fixed    => { type => 'char', length => 16, default => 'needed' },
      nums     => { type => 'array' },
      fk1      => { type => 'int' },
      fk2      => { type => 'int' },
      fk3      => { type => 'int' },
      b1       => { type => 'int' },
      b2       => { type => 'int' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'datetime' },
    );

    sub derived 
    {
      return 'DERIVED: ' . $_[0]->{'derived'}  if(@_ == 1);
      return $_[0]->{'derived'} = $_[1] 
    }

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
        method_types => [ 'get_set_now' ], # should be a no-op
      },

      bb1 =>
      {
        class => 'MyMySQLBB',
        key_columns => { b1 => 'id' },
        method_types => [ 'get_set_now' ], # should be a no-op
      },

      bb2 =>
      {
        class => 'MyMySQLBB',
        key_columns => { b2 => 'id' },
        method_types => [ 'get_set_now' ], # should be a no-op
      },
    );

    MyMySQLObject->meta->relationships
    (
      nicks =>
      {
        type  => 'one to many',
        class => 'MyMySQLNick',
        column_map => { id => 'o_id' },
        join_args    =>
        [
          't1.name' => { ne => \'t2.nick' },
          'rose_db_object_test.name' => { ne => \'rose_db_object_nicks.nick' },
          'date_created' => { gt => DateTime->now->subtract(years => 100) },
        ],
        manager_args => { sort_by => 'nick DESC' },
      },

      nicks2 =>
      {
        type  => 'one to many',
        class => 'MyMySQLNick2',
        column_map => { id => 'o_id' },
        manager_args => { sort_by => 'nick2 DESC' },
      },

      colors =>
      {
        type      => 'many to many',
        map_class => 'MyMySQLColorMap',
        manager_args => { sort_by => MyMySQLColor->meta->table . '.name DESC' },
      },
    );

    MyMySQLObject->meta->alias_column(fk1 => 'fkone');

    eval { MyMySQLObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method - mysql');

    MyMySQLObject->meta->alias_column(save => 'save_col');
    MyMySQLObject->meta->initialize(preserve_existing => 1);

    Rose::DB::Object::Manager->make_manager_methods('objectz');

    eval { Rose::DB::Object::Manager->make_manager_methods('objectz') };
    Test::More::ok($@, 'make_manager_methods clash - mysql');

    package MyMySQLObjectManager;
    our @ISA = qw(Rose::DB::Object::Manager);

    sub object_class { 'MyMySQLObject' }
    Rose::DB::Object::Manager->make_manager_methods('objectz');

    eval
    {
      Rose::DB::Object::Manager->make_manager_methods(object_class => 'MyMySQLObject',
                                                      base_name    => 'objectz',
                                                      methods      => {})
    };

    Test::More::ok($@ =~ /not both/, 'make_manager_methods params clash - mysql');
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

    Rose::DB->default_type('informix');

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_color_map CASCADE');
      $dbh->do('DROP TABLE rose_db_object_colors CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nicks CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_types2 CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_types CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nicks2 CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_alts CASCADE');
      $dbh->do('DROP TABLE rose_db_object_nick_opts CASCADE');
      $dbh->do('DROP TABLE rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE rose_db_object_other CASCADE');
      $dbh->do('DROP TABLE rose_db_object_bb CASCADE');
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
CREATE TABLE rose_db_object_bb
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(32)
)
EOF

    # Create test foreign subclasses

    package MyInformixOtherObject;

    our @ISA = qw(Rose::DB::Object);

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

    package MyInformixBB;

    our @ISA = qw(Rose::DB::Object);

    MyInformixBB->meta->table('rose_db_object_bb');

    MyInformixBB->meta->columns
    (
      id   => { type => 'int', primary_key => 1 },
      name => { type => 'varchar'},
    );

    MyInformixBB->meta->initialize;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INT NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           VARCHAR(5) DEFAULT '00101' NOT NULL,
  fixed          CHAR(16) DEFAULT 'needed',
  start          DATE,
  save           INT,
  nums           SET(INT NOT NULL),
  fk1            INT,
  fk2            INT,
  fk3            INT,
  b1             INT REFERENCES rose_db_object_bb (id),
  b2             INT REFERENCES rose_db_object_bb (id),
  last_modified  DATETIME YEAR TO FRACTION(5),
  date_created   DATETIME YEAR TO FRACTION(5),

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_types2
(
  id    SERIAL NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL UNIQUE
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_types
(
  id     SERIAL NOT NULL PRIMARY KEY,
  name   VARCHAR(32) NOT NULL UNIQUE,
  t2_id  INT REFERENCES rose_db_object_nick_types2 (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nicks
(
  id    SERIAL NOT NULL PRIMARY KEY,
  o_id  INT NOT NULL REFERENCES rose_db_object_test (id),
  nick  VARCHAR(32),
  type_id INT REFERENCES rose_db_object_nick_types (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_alts
(
  id       SERIAL NOT NULL PRIMARY KEY,
  nick_id  INT NOT NULL REFERENCES rose_db_object_nicks (id),
  alt      VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_opts
(
  id       SERIAL NOT NULL PRIMARY KEY,
  nick_id  INT NOT NULL REFERENCES rose_db_object_nicks (id),
  opt      VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nicks2
(
  id     SERIAL NOT NULL PRIMARY KEY,
  o_id   INT NOT NULL REFERENCES rose_db_object_test (id),
  nick2  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors
(
  id     SERIAL NOT NULL PRIMARY KEY,
  name   VARCHAR(32) NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_color_map
(
  id         SERIAL NOT NULL PRIMARY KEY,
  object_id  INT NOT NULL REFERENCES rose_db_object_test (id),
  color_id   INT NOT NULL REFERENCES rose_db_object_colors (id)
)
EOF

    $dbh->disconnect;

    package MyInformixNickType2;

    our @ISA = qw(Rose::DB::Object);

    MyInformixNickType2->meta->table('rose_db_object_nick_types2');

    MyInformixNickType2->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      name    => { type => 'varchar', length => 32 },
    );

    MyInformixNickType2->meta->add_unique_key('name');
    MyInformixNickType2->meta->initialize;

    package MyInformixNickType;

    our @ISA = qw(Rose::DB::Object);

    MyInformixNickType->meta->table('rose_db_object_nick_types');

    MyInformixNickType->meta->columns
    (
      id    => { type => 'serial', primary_key => 1 },
      name  => { type => 'varchar', length => 32 },
      t2_id => { type => 'int' },
    );

    MyInformixNickType->meta->add_unique_key('name');

    MyInformixNickType->meta->foreign_keys
    (
      t2 =>
      {
        class => 'MyInformixNickType2',
        key_columns => { t2_id => 'id' },
      }
    );

    MyInformixNickType->meta->initialize;

    package MyInformixNick;

    our @ISA = qw(Rose::DB::Object);

    MyInformixNick->meta->table('rose_db_object_nicks');

    MyInformixNick->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      o_id => { type => 'int' },
      nick => { type => 'varchar', lazy => 1 },
      type_id => { type => 'int' },
    );

    MyInformixNick->meta->foreign_keys
    (
      obj =>
      {
        class => 'MyInformixObject',
        key_columns => { o_id => 'id' },
      },

      type =>
      {
        class => 'MyInformixNickType',
        key_columns => { type_id => 'id' },
      },
    );

    MyInformixNick->meta->relationships
    (
      alts =>
      {
        type  => 'one to many',
        class => 'MyInformixNickAlt',
        key_columns => { id => 'nick_id' },
      },

      opts =>
      {
        type  => 'one to many',
        class => 'MyInformixNickOpt',
        key_columns => { id => 'nick_id' },
      },
    );

    MyInformixNick->meta->initialize;

    package MyInformixNick2;

    our @ISA = qw(Rose::DB::Object);

    MyInformixNick2->meta->table('rose_db_object_nicks2');

    MyInformixNick2->meta->columns
    (
      id    => { type => 'serial', primary_key => 1 },
      o_id  => { type => 'int' },
      nick2 => { type => 'varchar'},
    );

    MyInformixNick2->meta->foreign_keys
    (
      obj =>
      {
        class => 'MyInformixObject',
        key_columns => { o_id => 'id' },
      },
    );

    MyInformixNick2->meta->initialize;

    package MyInformixNickAlt;

    our @ISA = qw(Rose::DB::Object);

    MyInformixNickAlt->meta->table('rose_db_object_nick_alts');

    MyInformixNickAlt->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      nick_id => { type => 'int' },
      alt     => { type => 'varchar' },
    );

    MyInformixNickAlt->meta->foreign_keys
    (
      type =>
      {
        class => 'MyInformixNick',
        key_columns => { nick_id => 'id' },
      },
    );

    MyInformixNickAlt->meta->initialize;

    package MyInformixNickOpt;

    our @ISA = qw(Rose::DB::Object);

    MyInformixNickOpt->meta->table('rose_db_object_nick_opts');

    MyInformixNickOpt->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      nick_id => { type => 'int' },
      opt     => { type => 'varchar' },
    );

    MyInformixNickOpt->meta->foreign_keys
    (
      type =>
      {
        class => 'MyInformixNick',
        key_columns => { nick_id => 'id' },
      },
    );

    MyInformixNickOpt->meta->initialize;

    package MyInformixColor;

    our @ISA = qw(Rose::DB::Object);

    MyInformixColor->meta->table('rose_db_object_colors');

    MyInformixColor->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', not_null => 1 },
    );

    MyInformixColor->meta->relationships
    (
      objects =>
      {
        type      => 'many to many',
        map_class => 'MyInformixColorMap',
      },
    );

    MyInformixColor->meta->initialize;

    package MyInformixColorMap;

    our @ISA = qw(Rose::DB::Object);

    MyInformixColorMap->meta->table('rose_db_object_color_map');

    MyInformixColorMap->meta->columns
    (
      id        => { type => 'serial', primary_key => 1 },
      object_id => { type => 'int', not_null => 1 },
      color_id  => { type => 'int', not_null => 1 },
    );

    MyInformixColorMap->meta->foreign_keys
    (
      color =>
      {
        class => 'MyInformixColor',
        key_columns => { color_id => 'id' },
      },

      object =>
      {
        class => 'MyInformixObject',
        key_columns => { object_id => 'id' },
      },
    );

    MyInformixColorMap->meta->initialize;

    # Create test subclass

    package MyInformixObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub extra { $_[0]->{'extra'} = $_[1]  if(@_ > 1); $_[0]->{'extra'} }

    MyInformixObject->meta->table('rose_db_object_test');

    MyInformixObject->meta->columns
    (
      'name',
      id       => { primary_key => 1 },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active', lazy => 1 },
      start    => { type => 'date', default => '12/24/1980', lazy => 1 },
      save     => { type => 'scalar' },
      nums     => { type => 'set' },
      bits     => { type => 'bitfield', bits => 5, default => 101 },
      fixed    => { type => 'char', length => 16, default => 'needed' },,
      fk1      => { type => 'int' },
      fk2      => { type => 'int' },
      fk3      => { type => 'int' },
      b1       => { type => 'int' },
      b2       => { type => 'int' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    sub derived 
    {
      return 'DERIVED: ' . $_[0]->{'derived'}  if(@_ == 1);
      return $_[0]->{'derived'} = $_[1] 
    }

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

      bb1 =>
      {
        class => 'MyInformixBB',
        key_columns => { b1 => 'id' },
      },

      bb2 =>
      {
        class => 'MyInformixBB',
        key_columns => { b2 => 'id' },
      },
    );

    MyInformixObject->meta->relationships
    (
      nicks =>
      {
        type  => 'one to many',
        class => 'MyInformixNick',
        column_map => { id => 'o_id' },
        manager_args => { sort_by => 'nick DESC' },
      },

      nicks2 =>
      {
        type  => 'one to many',
        class => 'MyInformixNick2',
        column_map => { id => 'o_id' },
        manager_args => { sort_by => 'nick2 DESC' },
      },

      colors =>
      {
        type      => 'many to many',
        map_class => 'MyInformixColorMap',
        manager_args => { sort_by => MyInformixColor->meta->table . '.name DESC' },
      },
    );

    MyInformixObject->meta->alias_column(fk1 => 'fkone');

    eval { MyInformixObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method - informix');

    MyInformixObject->meta->alias_column(save => 'save_col');
    MyInformixObject->meta->initialize(preserve_existing => 1);

    Rose::DB::Object::Manager->make_manager_methods('objectz');

    eval { Rose::DB::Object::Manager->make_manager_methods('objectz') };
    Test::More::ok($@, 'make_manager_methods clash - informix');

    package MyInformixObjectManager;
    our @ISA = qw(Rose::DB::Object::Manager);

    sub object_class { 'MyInformixObject' }

    Rose::DB::Object::Manager->make_manager_methods(object_class => 'MyInformixObject',
                                                    base_name    => 'objectz');

    MyInformixObject->meta->clear_all_dbs;
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

    Rose::DB->default_type('sqlite');

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_color_map');
      $dbh->do('DROP TABLE rose_db_object_colors');
      $dbh->do('DROP TABLE rose_db_object_nicks');
      $dbh->do('DROP TABLE rose_db_object_nick_types2');
      $dbh->do('DROP TABLE rose_db_object_nick_types');
      $dbh->do('DROP TABLE rose_db_object_nicks2');
      $dbh->do('DROP TABLE rose_db_object_nick_alts');
      $dbh->do('DROP TABLE rose_db_object_nick_opts');
      $dbh->do('DROP TABLE rose_db_object_test');
      $dbh->do('DROP TABLE rose_db_object_other');
      $dbh->do('DROP TABLE rose_db_object_bb');
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
CREATE TABLE rose_db_object_bb
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(32),
  z varchar(32)
)
EOF

    # Create test foreign subclasses

    package MySQLiteOtherObject;

    our @ISA = qw(Rose::DB::Object);

    MySQLiteOtherObject->meta->table('rose_db_object_other');

    MySQLiteOtherObject->meta->columns
    (
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int', alias => 'ktwo' },
      k3   => { type => 'int' },
    );

    sub k2 { shift->ktwo(@_) }

    MySQLiteOtherObject->meta->primary_key_columns([ qw(k1 k2 k3) ]);

    MySQLiteOtherObject->meta->initialize;

    package MySQLiteBB;

    our @ISA = qw(Rose::DB::Object);

    MySQLiteBB->meta->table('rose_db_object_bb');

    MySQLiteBB->meta->columns
    (
      id   => { type => 'int', primary_key => 1 },
      name => { type => 'varchar' },
      z => { type => 'varchar', alias => 'x' },
    );

    MySQLiteBB->meta->initialize;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INT NOT NULL PRIMARY KEY,
  f              VARCHAR(10),
  name           VARCHAR(32) NOT NULL,
  flag           BOOLEAN NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'active',
  bits           VARCHAR(5) DEFAULT '00101' NOT NULL,
  fixed          CHAR(16) DEFAULT 'needed',
  start          DATE,
  save           INT,
  nums           VACHAR(255),
  fk1            INT,
  fk2            INT,
  fk3            INT,
  b1             INT REFERENCES rose_db_object_bb (id),
  b2             INT REFERENCES rose_db_object_bb (id),
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_types2
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR(32) NOT NULL UNIQUE
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_types
(
  id     INTEGER PRIMARY KEY AUTOINCREMENT,
  name   VARCHAR(32) NOT NULL UNIQUE,
  t2_id  INT REFERENCES rose_db_object_nick_types2 (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nicks
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  o_id  INT NOT NULL REFERENCES rose_db_object_test (id),
  nick  VARCHAR(32),
  type_id INT REFERENCES rose_db_object_nick_types (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_alts
(
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  nick_id  INT NOT NULL REFERENCES rose_db_object_nicks (id),
  alt      VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_opts
(
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  nick_id  INT NOT NULL REFERENCES rose_db_object_nicks (id),
  opt      VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nicks2
(
  id     INTEGER PRIMARY KEY AUTOINCREMENT,
  o_id   INT NOT NULL REFERENCES rose_db_object_test (id),
  nick2  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors
(
  id     INTEGER PRIMARY KEY AUTOINCREMENT,
  name   VARCHAR(32) NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_color_map
(
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  object_id  INT NOT NULL REFERENCES rose_db_object_test (id),
  color_id   INT NOT NULL REFERENCES rose_db_object_colors (id)
)
EOF

    $dbh->disconnect;

    package MySQLiteNickType2;

    our @ISA = qw(Rose::DB::Object);

    MySQLiteNickType2->meta->table('rose_db_object_nick_types2');

    MySQLiteNickType2->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      name    => { type => 'varchar', length => 32 },
    );

    MySQLiteNickType2->meta->add_unique_key('name');
    MySQLiteNickType2->meta->initialize;

    package MySQLiteNickType;

    our @ISA = qw(Rose::DB::Object);

    MySQLiteNickType->meta->table('rose_db_object_nick_types');

    MySQLiteNickType->meta->columns
    (
      id    => { type => 'serial', primary_key => 1 },
      name  => { type => 'varchar', length => 32 },
      t2_id => { type => 'int' },
    );

    MySQLiteNickType->meta->add_unique_key('name');

    MySQLiteNickType->meta->foreign_keys
    (
      t2 =>
      {
        class => 'MySQLiteNickType2',
        key_columns => { t2_id => 'id' },
      }
    );

    MySQLiteNickType->meta->initialize;

    package MySQLiteNick;

    our @ISA = qw(Rose::DB::Object);

    MySQLiteNick->meta->table('rose_db_object_nicks');

    MySQLiteNick->meta->columns
    (
      id   => { type => 'serial', alias => 'eyedee', primary_key => 1 },
      o_id => { type => 'int' },
      nick => { type => 'varchar', lazy => 1 },
      type_id => { type => 'int' },
    );

    MySQLiteNick->meta->relationships
    (
      alts =>
      {
        type  => 'one to many',
        class => 'MySQLiteNickAlt',
        key_columns => { id => 'nick_id' },
      },

      opts =>
      {
        type  => 'one to many',
        class => 'MySQLiteNickOpt',
        key_columns => { id => 'nick_id' },
      },
    );

    MySQLiteNick->meta->foreign_keys
    (
      obj =>
      {
        class => 'MySQLiteObject',
        key_columns => { o_id => 'id' },
      },

      type =>
      {
        class => 'MySQLiteNickType',
        key_columns => { type_id => 'id' },
      },
    );

    MySQLiteNick->meta->initialize;

    package MySQLiteNick2;

    our @ISA = qw(Rose::DB::Object);

    MySQLiteNick2->meta->table('rose_db_object_nicks2');

    MySQLiteNick2->meta->columns
    (
      id    => { type => 'serial', primary_key => 1 },
      o_id  => { type => 'int' },
      nick2 => { type => 'varchar'},
    );

    MySQLiteNick2->meta->foreign_keys
    (
      obj =>
      {
        class => 'MySQLiteObject',
        key_columns => { o_id => 'id' },
      },
    );

    MySQLiteNick2->meta->initialize;

    package MySQLiteNickAlt;

    our @ISA = qw(Rose::DB::Object);

    MySQLiteNickAlt->meta->table('rose_db_object_nick_alts');

    MySQLiteNickAlt->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      nick_id => { type => 'int' },
      alt     => { type => 'varchar' },
    );

    MySQLiteNickAlt->meta->foreign_keys
    (
      type =>
      {
        class => 'MySQLiteNick',
        key_columns => { nick_id => 'id' },
      },
    );

    MySQLiteNickAlt->meta->initialize;

    package MySQLiteNickOpt;

    our @ISA = qw(Rose::DB::Object);

    MySQLiteNickOpt->meta->table('rose_db_object_nick_opts');

    MySQLiteNickOpt->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      nick_id => { type => 'int' },
      opt     => { type => 'varchar' },
    );

    MySQLiteNickOpt->meta->foreign_keys
    (
      type =>
      {
        class => 'MySQLiteNick',
        key_columns => { nick_id => 'id' },
      },
    );

    MySQLiteNickOpt->meta->initialize;

    package MySQLiteColor;

    our @ISA = qw(Rose::DB::Object);

    MySQLiteColor->meta->table('rose_db_object_colors');

    MySQLiteColor->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', not_null => 1 },
    );

    MySQLiteColor->meta->relationships
    (
      objects =>
      {
        type      => 'many to many',
        map_class => 'MySQLiteColorMap',
      },
    );

    MySQLiteColor->meta->initialize;

    package MySQLiteColorMap;

    our @ISA = qw(Rose::DB::Object);

    MySQLiteColorMap->meta->table('rose_db_object_color_map');

    MySQLiteColorMap->meta->columns
    (
      id        => { type => 'serial', primary_key => 1 },
      object_id => { type => 'int', not_null => 1 },
      color_id  => { type => 'int', not_null => 1 },
    );

    MySQLiteColorMap->meta->foreign_keys
    (
      color =>
      {
        class => 'MySQLiteColor',
        key_columns => { color_id => 'id' },
      },

      object =>
      {
        class => 'MySQLiteObject',
        key_columns => { object_id => 'id' },
      },
    );

    MySQLiteColorMap->meta->initialize;

    # Create test subclass

    package MySQLiteObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub extra { $_[0]->{'extra'} = $_[1]  if(@_ > 1); $_[0]->{'extra'} }

    MySQLiteObject->meta->table('rose_db_object_test');

    MySQLiteObject->meta->columns
    (
      'name',
      'f'      => { type => 'varchar', length => 10, alias => 'foo' },
      id       => { primary_key => 1 },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active', lazy => 1 },
      start    => { type => 'date', default => '1980-12-24', lazy => 1 },
      save     => { type => 'scalar' },
      nums     => { type => 'array' },
      bits     => { type => 'bitfield', bits => 5, default => 101 },
      fixed    => { type => 'char', length => 16, default => 'needed' },
      fk1      => { type => 'int' },
      fk2      => { type => 'int' },
      fk3      => { type => 'int' },
      b1       => { type => 'int' },
      b2       => { type => 'int' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    sub derived 
    {
      return 'DERIVED: ' . $_[0]->{'derived'}  if(@_ == 1);
      return $_[0]->{'derived'} = $_[1] 
    }

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

      bb1 =>
      {
        class => 'MySQLiteBB',
        key_columns => { b1 => 'id' },
      },

      bb2 =>
      {
        class => 'MySQLiteBB',
        key_columns => { b2 => 'id' },
      },
    );

    MySQLiteObject->meta->relationships
    (
      nicks =>
      {
        type  => 'one to many',
        class => 'MySQLiteNick',
        column_map => { id => 'o_id' },
        manager_args => { sort_by => 'nick DESC' },
      },

      nicks2 =>
      {
        type  => 'one to many',
        class => 'MySQLiteNick2',
        column_map => { id => 'o_id' },
        manager_args => { sort_by => 'nick2 DESC' },
      },

      colors =>
      {
        type      => 'many to many',
        map_class => 'MySQLiteColorMap',
        manager_args => { sort_by => MySQLiteColor->meta->table . '.name DESC' },
      },
    );

    MySQLiteObject->meta->alias_column(fk1 => 'fkone');

    eval { MySQLiteObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method - sqlite');

    MySQLiteObject->meta->alias_column(save => 'save_col');
    MySQLiteObject->meta->initialize(preserve_existing => 1);

    Rose::DB::Object::Manager->make_manager_methods('objectz');

    eval { Rose::DB::Object::Manager->make_manager_methods('objectz') };
    Test::More::ok($@, 'make_manager_methods clash - sqlite');

    package MySQLiteObjectManager;
    our @ISA = qw(Rose::DB::Object::Manager);

    sub object_class { 'MySQLiteObject' }

    Rose::DB::Object::Manager->make_manager_methods(object_class => 'MySQLiteObject',
                                                    methods =>
                                                    {
                                                      objectz => [ qw(objects iterator) ],
                                                      'object_count()' => 'count'
                                                    });
  }

  #
  # Oracle
  #

  eval 
  {
    $dbh = Rose::DB->new('oracle_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_ORACLE = 1;

    Rose::DB->default_type('oracle');

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_color_map CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rose_db_object_colors CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rose_db_object_nicks CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rose_db_object_nick_types2 CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rose_db_object_nick_types CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rose_db_object_nicks2 CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rose_db_object_nick_alts CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rose_db_object_nick_opts CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rose_db_object_test CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rose_db_object_other CASCADE CONSTRAINTS');
      $dbh->do('DROP TABLE rose_db_object_bb CASCADE CONSTRAINTS');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_other
(
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  k3    INT NOT NULL,
  name  VARCHAR(32),

  PRIMARY KEY (k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_bb
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(32)
)
EOF

    # Create test foreign subclasses

    package MyOracleOtherObject;

    our @ISA = qw(Rose::DB::Object);

    MyOracleOtherObject->meta->table('rose_db_object_other');

    MyOracleOtherObject->meta->columns
    (
      name => { type => 'varchar'},
      k1   => { type => 'int' },
      k2   => { type => 'int' },
      k3   => { type => 'int' },
    );

    MyOracleOtherObject->meta->primary_key_columns(qw(k1 k2 k3));

    MyOracleOtherObject->meta->initialize;

    package MyOracleBB;

    our @ISA = qw(Rose::DB::Object);

    MyOracleBB->meta->table('rose_db_object_bb');

    MyOracleBB->meta->columns
    (
      id   => { type => 'int', primary_key => 1 },
      name => { type => 'varchar'},
    );

    MyOracleBB->meta->initialize;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INT NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  flag           CHAR(1) NOT NULL CHECK(flag IN ('t', 'f')),
  flag2          CHAR(1) CHECK(flag2 IN ('t', 'f')),
  status         VARCHAR(32) DEFAULT 'active',
  bits           VARCHAR(5) DEFAULT '00101' NOT NULL,
  fixed          CHAR(16) DEFAULT 'needed',
  start_date     DATE,
  save           INT,
  fk1            INT,
  fk2            INT,
  fk3            INT,
  b1             INT REFERENCES rose_db_object_bb (id),
  b2             INT REFERENCES rose_db_object_bb (id),
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  FOREIGN KEY (fk1, fk2, fk3) REFERENCES rose_db_object_other (k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_types2
(
  id    INT NOT NULL PRIMARY KEY,
  name  VARCHAR(32) NOT NULL UNIQUE
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_types
(
  id     INT NOT NULL PRIMARY KEY,
  name   VARCHAR(32) NOT NULL UNIQUE,
  t2_id  INT REFERENCES rose_db_object_nick_types2 (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nicks
(
  id    INT NOT NULL PRIMARY KEY,
  o_id  INT NOT NULL REFERENCES rose_db_object_test (id),
  nick  VARCHAR(32),
  type_id INT REFERENCES rose_db_object_nick_types (id)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_alts
(
  id       INT NOT NULL PRIMARY KEY,
  nick_id  INT NOT NULL REFERENCES rose_db_object_nicks (id),
  alt      VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nick_opts
(
  id       INT NOT NULL PRIMARY KEY,
  nick_id  INT NOT NULL REFERENCES rose_db_object_nicks (id),
  opt      VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_nicks2
(
  id     INT NOT NULL PRIMARY KEY,
  o_id   INT NOT NULL REFERENCES rose_db_object_test (id),
  nick2  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_colors
(
  id     INT NOT NULL PRIMARY KEY,
  name   VARCHAR(32) NOT NULL
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_color_map
(
  id         INT NOT NULL PRIMARY KEY,
  object_id  INT NOT NULL REFERENCES rose_db_object_test (id),
  color_id   INT NOT NULL REFERENCES rose_db_object_colors (id)
)
EOF

    $dbh->disconnect;

    my $DB;

    package MyOracleNickType2;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { $DB ||= Rose::DB->new }

    MyOracleNickType2->meta->table('rose_db_object_nick_types2');

    MyOracleNickType2->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      name    => { type => 'varchar', length => 32 },
    );

    MyOracleNickType2->meta->add_unique_key('name');
    MyOracleNickType2->meta->initialize;

    package MyOracleNickType;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { $DB ||= Rose::DB->new }

    MyOracleNickType->meta->table('rose_db_object_nick_types');

    MyOracleNickType->meta->columns
    (
      id    => { type => 'serial', primary_key => 1 },
      name  => { type => 'varchar', length => 32 },
      t2_id => { type => 'int' },
    );

    MyOracleNickType->meta->add_unique_key('name');

    MyOracleNickType->meta->foreign_keys
    (
      t2 =>
      {
        class => 'MyOracleNickType2',
        key_columns => { t2_id => 'id' },
      }
    );

    MyOracleNickType->meta->initialize;

    package MyOracleNick;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { $DB ||= Rose::DB->new }

    MyOracleNick->meta->table('rose_db_object_nicks');

    MyOracleNick->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      o_id => { type => 'int' },
      nick => { type => 'varchar', lazy => 1 },
      type_id => { type => 'int' },
    );

    MyOracleNick->meta->foreign_keys
    (
      obj =>
      {
        class => 'MyOracleObject',
        key_columns => { o_id => 'id' },
      },

      type =>
      {
        class => 'MyOracleNickType',
        key_columns => { type_id => 'id' },
      },
    );

    MyOracleNick->meta->relationships
    (
      alts =>
      {
        type  => 'one to many',
        class => 'MyOracleNickAlt',
        key_columns => { id => 'nick_id' },
      },

      opts =>
      {
        type  => 'one to many',
        class => 'MyOracleNickOpt',
        key_columns => { id => 'nick_id' },
      },
    );

    MyOracleNick->meta->initialize;

    package MyOracleNick2;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { $DB ||= Rose::DB->new }

    MyOracleNick2->meta->table('rose_db_object_nicks2');

    MyOracleNick2->meta->columns
    (
      id    => { type => 'serial', primary_key => 1 },
      o_id  => { type => 'int' },
      nick2 => { type => 'varchar'},
    );

    MyOracleNick2->meta->foreign_keys
    (
      obj =>
      {
        class => 'MyOracleObject',
        key_columns => { o_id => 'id' },
      },
    );

    MyOracleNick2->meta->initialize;

    package MyOracleNickAlt;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { $DB ||= Rose::DB->new }

    MyOracleNickAlt->meta->table('rose_db_object_nick_alts');

    MyOracleNickAlt->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      nick_id => { type => 'int' },
      alt     => { type => 'varchar' },
    );

    MyOracleNickAlt->meta->foreign_keys
    (
      type =>
      {
        class => 'MyOracleNick',
        key_columns => { nick_id => 'id' },
      },
    );

    MyOracleNickAlt->meta->initialize;

    package MyOracleNickOpt;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { $DB ||= Rose::DB->new }

    MyOracleNickOpt->meta->table('rose_db_object_nick_opts');

    MyOracleNickOpt->meta->columns
    (
      id      => { type => 'serial', primary_key => 1 },
      nick_id => { type => 'int' },
      opt     => { type => 'varchar' },
    );

    MyOracleNickOpt->meta->foreign_keys
    (
      type =>
      {
        class => 'MyOracleNick',
        key_columns => { nick_id => 'id' },
      },
    );

    MyOracleNickOpt->meta->initialize;

    package MyOracleColor;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { $DB ||= Rose::DB->new }

    MyOracleColor->meta->table('rose_db_object_colors');

    MyOracleColor->meta->columns
    (
      id   => { type => 'serial', primary_key => 1 },
      name => { type => 'varchar', not_null => 1 },
    );

    MyOracleColor->meta->relationships
    (
      objects =>
      {
        type      => 'many to many',
        map_class => 'MyOracleColorMap',
      },
    );

    MyOracleColor->meta->initialize;

    package MyOracleColorMap;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { $DB ||= Rose::DB->new }

    MyOracleColorMap->meta->table('rose_db_object_color_map');

    MyOracleColorMap->meta->columns
    (
      id        => { type => 'serial', primary_key => 1 },
      object_id => { type => 'int', not_null => 1 },
      color_id  => { type => 'int', not_null => 1 },
    );

    MyOracleColorMap->meta->foreign_keys
    (
      color =>
      {
        class => 'MyOracleColor',
        key_columns => { color_id => 'id' },
      },

      object =>
      {
        class => 'MyOracleObject',
        key_columns => { object_id => 'id' },
      },
    );

    MyOracleColorMap->meta->initialize;

    # Create test subclass

    package MyOracleObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { $DB ||= Rose::DB->new }

    sub extra { $_[0]->{'extra'} = $_[1]  if(@_ > 1); $_[0]->{'extra'} }

    MyOracleObject->meta->table('rose_db_object_test');

    MyOracleObject->meta->columns
    (
      'name',
      id         => { primary_key => 1 },
      flag       => { type => 'boolean', default => 1 },
      flag2      => { type => 'boolean' },
      status     => { default => 'active', lazy => 1 },
      start_date => { type => 'date', default => '12/24/1980', lazy => 1 },
      save       => { type => 'scalar' },
      bits       => { type => 'bitfield', bits => 5, default => 101 },
      fixed      => { type => 'char', length => 16, default => 'needed' },,
      fk1        => { type => 'int' },
      fk2        => { type => 'int' },
      fk3        => { type => 'int' },
      b1         => { type => 'int' },
      b2         => { type => 'int' },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'timestamp' },
    );

    sub derived 
    {
      return 'DERIVED: ' . $_[0]->{'derived'}  if(@_ == 1);
      return $_[0]->{'derived'} = $_[1] 
    }

    MyOracleObject->meta->foreign_keys
    (
      other_obj =>
      {
        class => 'MyOracleOtherObject',
        key_columns =>
        {
          fk1 => 'k1',
          fk2 => 'k2',
          fk3 => 'k3',
        }
      },

      bb1 =>
      {
        class => 'MyOracleBB',
        key_columns => { b1 => 'id' },
      },

      bb2 =>
      {
        class => 'MyOracleBB',
        key_columns => { b2 => 'id' },
      },
    );

    MyOracleObject->meta->relationships
    (
      nicks =>
      {
        type  => 'one to many',
        class => 'MyOracleNick',
        column_map => { id => 'o_id' },
        manager_args => { sort_by => 'nick DESC' },
      },

      nicks2 =>
      {
        type  => 'one to many',
        class => 'MyOracleNick2',
        column_map => { id => 'o_id' },
        manager_args => { sort_by => 'nick2 DESC' },
      },

      colors =>
      {
        type      => 'many to many',
        map_class => 'MyOracleColorMap',
        manager_args => { sort_by => MyOracleColor->meta->table . '.name DESC' },
      },
    );

    MyOracleObject->meta->alias_column(fk1 => 'fkone');

    eval { MyOracleObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method - oracle');

    MyOracleObject->meta->alias_column(save => 'save_col');
    MyOracleObject->meta->initialize(preserve_existing => 1);

    Rose::DB::Object::Manager->make_manager_methods('objectz');

    eval { Rose::DB::Object::Manager->make_manager_methods('objectz') };
    Test::More::ok($@, 'make_manager_methods clash - oracle');

    package MyOracleObjectManager;
    our @ISA = qw(Rose::DB::Object::Manager);

    sub object_class { 'MyOracleObject' }

    Rose::DB::Object::Manager->make_manager_methods(object_class => 'MyOracleObject',
                                                    base_name    => 'objectz');

    MyOracleObject->meta->clear_all_dbs;
  }
}

END
{
  # Delete test tables

  if($HAVE_PG)
  {
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_color_map CASCADE');
    $dbh->do('DROP TABLE rose_db_object_colors CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nicks CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_types2 CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_types CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nicks2 CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_alts CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_opts CASCADE');
    $dbh->do('DROP TABLE rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE rose_db_object_other CASCADE');
    $dbh->do('DROP TABLE rose_db_object_bb CASCADE');

    $dbh->disconnect;
  }

  if($HAVE_MYSQL)
  {
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_color_map CASCADE');
    $dbh->do('DROP TABLE rose_db_object_colors CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nicks CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_types2 CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_types CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nicks2 CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_alts CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_opts CASCADE');
    $dbh->do('DROP TABLE rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE rose_db_object_other CASCADE');
    $dbh->do('DROP TABLE rose_db_object_bb CASCADE');

    $dbh->disconnect;
  }

  if($HAVE_INFORMIX)
  {
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_color_map CASCADE');
    $dbh->do('DROP TABLE rose_db_object_colors CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nicks CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_types2 CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_types CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nicks2 CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_alts CASCADE');
    $dbh->do('DROP TABLE rose_db_object_nick_opts CASCADE');
    $dbh->do('DROP TABLE rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE rose_db_object_other CASCADE');
    $dbh->do('DROP TABLE rose_db_object_bb CASCADE');

    $dbh->disconnect;
  }

  if($HAVE_SQLITE)
  {
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_color_map');
    $dbh->do('DROP TABLE rose_db_object_colors');
    $dbh->do('DROP TABLE rose_db_object_nicks');
    $dbh->do('DROP TABLE rose_db_object_nick_types2');
    $dbh->do('DROP TABLE rose_db_object_nick_types');
    $dbh->do('DROP TABLE rose_db_object_nicks2');
    $dbh->do('DROP TABLE rose_db_object_nick_alts');
    $dbh->do('DROP TABLE rose_db_object_nick_opts');
    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->do('DROP TABLE rose_db_object_other');
    $dbh->do('DROP TABLE rose_db_object_bb');

    $dbh->disconnect;
  }

  if($HAVE_ORACLE)
  {
    my $dbh = Rose::DB->new('oracle_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_color_map CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rose_db_object_colors CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rose_db_object_nicks CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rose_db_object_nick_types2 CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rose_db_object_nick_types CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rose_db_object_nicks2 CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rose_db_object_nick_alts CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rose_db_object_nick_opts CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rose_db_object_test CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rose_db_object_other CASCADE CONSTRAINTS');
    $dbh->do('DROP TABLE rose_db_object_bb CASCADE CONSTRAINTS');

    $dbh->disconnect;
  }
}
