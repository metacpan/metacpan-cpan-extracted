#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
}

our %Have;

#
# Tests
#

foreach my $db_type (qw(mysql))
{
  SKIP:
  {
    skip("$db_type tests", 3)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  my $class = ucfirst($db_type) . 'Foo';

  my $o =
    $class->new(name => 'f1: ' . localtime(),
                children =>
                [
                  { name => 'c1: ' . localtime() },
                  { name => 'c2: ' . localtime() },
                ]);

  $o->save;

  my $p = $class->new(id => $o->id);
  ok($p->load, "parent - $db_type");

  my $c1 = $class->new(id => $o->children->[0]->id);
  ok($c1->load, "child 1 - $db_type");

  my $c2 = $class->new(id => $o->children->[1]->id);
  ok($c2->load, "child 2 - $db_type");
}

BEGIN
{
  our %Have;

  #
  # MySQL
  #

  my $dbh;

  eval
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test_foo');
      $dbh->do('DROP TABLE rose_db_object_test_foo_parent');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test_foo
(
  id    INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test_foo_parent
(
  parent_id INT UNSIGNED NOT NULL REFERENCES rose_db_object_test_foo (id),
  child_id  INT UNSIGNED NOT NULL REFERENCES rose_db_object_test_foo (id),

  PRIMARY KEY(parent_id, child_id)
)
EOF

    $dbh->disconnect;

    Rose::DB->default_type('mysql');

    package MysqlFoo;
    our @ISA = qw(Rose::DB::Object);

    MysqlFoo->meta->table('rose_db_object_test_foo');
    MysqlFoo->meta->columns(qw(id name));
    MysqlFoo->meta->primary_key_columns('id');
    MysqlFoo->meta->add_unique_key('name');
    MysqlFoo->meta->relationships
    (
      parents => 
      { 
        type      => 'many to many',
        map_class => 'MysqlFooParent',
        map_from  => 'child',
        map_to    => 'parent',
      },

      children =>
      {
        type      => 'many to many',
        map_class => 'MysqlFooParent',
        map_from  => 'parent',
        map_to    => 'child',
      },
    );

    MysqlFoo->meta->initialize;

    package MysqlFooParent;
    our @ISA = qw(Rose::DB::Object);

    MysqlFooParent->meta->table('rose_db_object_test_foo_parent');
    MysqlFooParent->meta->columns(qw(parent_id child_id));
    MysqlFooParent->meta->primary_key_columns(qw(parent_id child_id));

    MysqlFooParent->meta->foreign_keys
    (
      parent => { class => 'MysqlFoo', key_columns => { parent_id => 'id' } },
      child  => { class => 'MysqlFoo', key_columns => { child_id  => 'id' } },
    );

    MysqlFooParent->meta->initialize;
  }
}

END
{
  # Delete test tables

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test_foo');
    $dbh->do('DROP TABLE rose_db_object_test_foo_parent');
    $dbh->disconnect;
  }
}
