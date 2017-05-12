#!/usr/bin/perl -w

use strict;

use Test::More tests => 1 + (2 * 13);

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object::Loader');
}

our %Have;

#
# Tests
#

#$Rose::DB::Object::Manager::Debug = 1;

foreach my $db_type (qw(pg mysql))
{
  SKIP:
  {
    skip("$db_type tests", 13)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  my $class_prefix =  ucfirst($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix);

  my @classes = $loader->make_classes(include_tables => '^rose_db_object_test$');

  my $object_class  = $class_prefix . '::RoseDbObjectTest';
  my $manager_class = $object_class . '::Manager';

  my $data = "\000\001\002\003\004\005" x 10;

  # Standard save

  my $o = $object_class->new(num => 123, data => $data);
  $o->save;

  $o = $object_class->new(id => $o->id)->load;
  is($o->data, $data, "save 1 - $db_type");

  $o->save;

  $o = $object_class->new(id => $o->id)->load;
  is($o->data, $data, "save 2 - $db_type");  

  # Changes only

  my $short_data = "\000\001\002\003\004\005";

  $o->data($short_data);
  $o->save(changes_only => 1);

  $o = $object_class->new(id => $o->id)->load;
  is($o->data, $short_data, "update changes only - $db_type");  

  $o = $object_class->new(data => $short_data);
  $o->save(changes_only => 1);

  $o = $object_class->new(id => $o->id)->load;
  is($o->data, $short_data, "insert changes only - $db_type");

  # On duplicate key update

  if($o->db->supports_on_duplicate_key_update)
  {
    # Force the bind_param code to be triggered (should be harmless)
    local $object_class->meta->{'dbi_requires_bind_param'}{$o->db->{'id'}} = 1;

    my $data = "\000\001\002";

    $o->data($data);
    $o->insert(on_duplicate_key_update => 1);

    $o = $object_class->new(id => $o->id)->load;
    is($o->data, $data, "on duplicate key update - $db_type");
  }
  else
  {
    ok(1, "on duplicate key update not supported - $db_type");
  }

  #
  # Allow inline column values
  #

  $object_class->meta->allow_inline_column_values(1);
  $manager_class->delete_rose_db_object_test(all => 1);

  $data = "\000\001\002\003\004\005" x 10;

  # Standard save

  $o = $object_class->new(num => 123, data => $data);

  $o->save;

  $o = $object_class->new(id => $o->id)->load;
  is($o->data, $data, "inline - save 1 - $db_type");

  $o->save;

  $o = $object_class->new(id => $o->id)->load;
  is($o->data, $data, "inline - save 2 - $db_type");  

  # Changes only

  $short_data = "\000\001\002\003\004\005";

  $o->data($short_data);
  $o->save(changes_only => 1);

  $o = $object_class->new(id => $o->id)->load;
  is($o->data, $short_data, "inline - update changes only - $db_type");  

  $o = $object_class->new(data => $short_data);
  $o->save(changes_only => 1);

  $o = $object_class->new(id => $o->id)->load;
  is($o->data, $short_data, "inline - insert changes only - $db_type");

  # On duplicate key update

  if($o->db->supports_on_duplicate_key_update)
  {
    # Force the bind_param code to be triggered (should be harmless)
    local $object_class->meta->{'dbi_requires_bind_param'}{$o->db->{'id'}} = 1;

    my $data = "\000\001\002";

    $o->data($data);
    $o->insert(on_duplicate_key_update => 1);

    $o = $object_class->new(id => $o->id)->load;
    is($o->data, $data, "inline - on duplicate key update - $db_type");
  }
  else
  {
    ok(1, "inline - on duplicate key update not supported - $db_type");
  }

  #
  # Manager
  #

  my $os =
    $manager_class->get_rose_db_object_test(
      query => [ data => $o->data, id => $o->id ]);

  ok($os && @$os == 1 && $os->[0]->id == $o->id, "manager 1 - $db_type");

  $os =
    $manager_class->get_rose_db_object_test(
      query =>
      [
        data => [ "\000\001", $o->data ], 
        or =>
        [
          data => [ "\000\002", $o->data ],
          id   => { ne => [ 123, 456 ] },
        ],
        id => $o->id ]);

  ok($os && @$os == 1 && $os->[0]->id == $o->id, "manager 2 - $db_type");

  #local $Rose::DB::Object::Manager::Debug = 1;
  $os =
    $manager_class->get_rose_db_object_test(
      query =>
      [
        data => [ "\000\001", $o->data ],
        num  => undef,
        or =>
        [
          data => [ "\000\002", $o->data ],
          id   => { ne => [ 123, 456 ] },
          or =>
          [
            data => [ "\001\003", $o->data ],
            data => { ne => "\000" },
            id   => { ne => undef },
            num  => undef,
            '!data' => "\002\003",
            data => $o->data,
          ]
        ],
        id => $o->id ]);

  ok($os && @$os == 1 && $os->[0]->id == $o->id, "manager 3 - $db_type");
}

BEGIN
{
  our %Have;

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
    $Have{'pg'} = 1;
    $Have{'pg_with_schema'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test 
(
  id    SERIAL PRIMARY KEY,
  num   INT,
  data  BYTEA
)
EOF

    $dbh->disconnect;
  }

  #
  # MySQL
  #

  eval 
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test 
(
  id    INT AUTO_INCREMENT PRIMARY KEY,
  num   INT,
  data  BLOB
)
EOF
  }
}

END
{
  # Delete test table

  if($Have{'pg'})
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');
    $dbh->disconnect;
  }
}
