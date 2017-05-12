#!/usr/bin/perl -w

use strict;

use Test::More tests => 2 + (2 * 24);

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Loader');
}

our(%HAVE, $DID_SETUP);

$DID_SETUP = 0; # dumb

#
# Tests
#

#$Rose::DB::Object::Manager::Debug = 1;

my $i = 1;

foreach my $db_type (qw(pg pg_with_schema))
{
  SKIP:
  {
    skip("$db_type tests", 24)  unless($HAVE{$db_type});
  }

  next  unless($HAVE{$db_type});

  $i++;

  Rose::DB->default_type($db_type);
  Rose::DB::Object::Metadata->unregister_all_classes;

  my $class_prefix = ucfirst($db_type eq 'pg_with_schema' ? 'pgws' : $db_type);

  #$Rose::DB::Object::Metadata::Debug = 1;

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix);

  my @classes = $loader->make_classes(include_tables => '(?i)Rose_db_object_test2?');

  my $object_class = $class_prefix . '::RoseDbObjectTest';

  ##
  ## Run tests
  ##

  if($db_type eq 'pg')
  {
    is_deeply(scalar $object_class->meta->primary_key->sequence_names, 
      [ 'rose_db_object_test_id1_seq', 'rdbo_seq2' ], "pk sequence names 1 - $db_type");
  }
  elsif($db_type eq 'pg_with_schema')
  {
    is_deeply(scalar $object_class->meta->primary_key->sequence_names, 
      [ 'rose_db_object_private.rose_db_object_test_id1_seq', 
        'rose_db_object_private.rdbo_seq2' ], 
      "pk sequence names 1 - $db_type");
  }
  else
  {
    SKIP { skip("non-pg tests", 1); }
  }

  my $o = $object_class->new(name => "Sled $i");
  $o->save;

  is($o->id1, 1, "pk 1 - $db_type");
  is($o->id2, 1, "pk 2 - $db_type");

  $o = $object_class->new(name => "Kite $i");
  $o->save;

  is($o->id1, 2, "pk 3 - $db_type");
  is($o->id2, 2, "pk 4 - $db_type");

  my @seqs = $o->meta->primary_key->sequence_names;
  is(scalar @seqs, 2, "sequences 1 - $db_type");
  is($seqs[0], ($db_type eq 'pg_with_schema' ? 'rose_db_object_private.' : '') . 
               'rose_db_object_test_id1_seq', "sequences 2 - $db_type");
  is($seqs[1], ($db_type eq 'pg_with_schema' ? 'rose_db_object_private.' : '') . 
               'rdbo_seq2', "sequences 3 - $db_type");

  $object_class .= '2';

  if($db_type eq 'pg')
  {
    is_deeply(scalar $object_class->meta->primary_key->sequence_names, 
      [ undef, 'rdbo_seq2_2' ], "pk sequence names 2 - $db_type");
  }
  elsif($db_type eq 'pg_with_schema')
  {
    is_deeply(scalar $object_class->meta->primary_key->sequence_names, 
      [ undef, 'rose_db_object_private.rdbo_seq2_2' ], 
      "pk sequence names 2 - $db_type");
  }
  else
  {
    SKIP { skip("non-pg tests", 1); }
  }

  $o = $object_class->new(id1 => 10, name => "Sled $i");

  $o->save;

  is($o->id1, 10, "pk 5 - $db_type");
  is($o->id2, 1, "pk 6 - $db_type");

  $o = $object_class->new(id1 => 20, name => "Kite $i");
  $o->save;

  is($o->id1, 20, "pk 7 - $db_type");
  is($o->id2, 2, "pk 8 - $db_type");

  @seqs = $o->meta->primary_key->sequence_names;
  is(scalar @seqs, 2, "sequences 4 - $db_type");
  ok(!defined $seqs[0], "sequences 5 - $db_type");
  is($seqs[1], ($db_type eq 'pg_with_schema' ? 'rose_db_object_private.' : '') . 
               'rdbo_seq2_2', "sequences 6 - $db_type");

  if($db_type eq 'pg')
  {
    $o = MyPgObject->new(name => "Barn $i");
    $o->save;

    is($o->id1, 3, "pk 9 - $db_type");
    is($o->id2, 3, "pk 10 - $db_type");

    $o = MyPgObject2->new(id1 => 30, name => "Barn $i");
    $o->save;

    is($o->id1, 30, "pk 9 - $db_type");
    is($o->id2, 3, "pk 10 - $db_type");

    is_deeply(scalar MyPgObject->meta->primary_key->sequence_names, 
      [ 'rose_db_object_test_id1_seq', 'rdbo_seq2' ], 
      "pk sequence names 3 - $db_type");

    is_deeply(scalar MyPgObject->meta->primary_key_sequence_names(MyPgObject->init_db), 
      [ 'rose_db_object_test_id1_seq', 'rdbo_seq2' ], 
      "pk sequence names 4 - $db_type");

    is_deeply(scalar MyPgObject2->meta->primary_key->sequence_names, 
      [ undef, 'rdbo_seq2_2' ], "pk sequence names 5 - $db_type");

    is_deeply(scalar MyPgObject2->meta->primary_key_sequence_names(MyPgObject2->init_db), 
      [ undef, 'rdbo_seq2_2' ], "pk sequence names 6 - $db_type");
  }
  elsif($db_type eq 'pg_with_schema')
  {
    $o = MyPgWSObject->new(name => "Barn $i");
    $o->save;

    is($o->id1, 3, "pk 9 - $db_type");
    is($o->id2, 3, "pk 10 - $db_type");  

    $o = MyPgWSObject2->new(id1 => 30, name => "Barn $i");
    $o->save;

    is($o->id1, 30, "pk 9 - $db_type");
    is($o->id2, 3, "pk 10 - $db_type");  

    is_deeply(scalar MyPgWSObject->meta->primary_key->sequence_names, 
      [ 'Rose_db_object_private.rose_db_object_test_id1_seq', 
        'Rose_db_object_private.rdbo_seq2' ], 
      "pk sequence names 3 - $db_type");

    is_deeply(scalar MyPgWSObject->meta->primary_key_sequence_names(MyPgWSObject->init_db), 
      [ 'Rose_db_object_private.rose_db_object_test_id1_seq', 
        'Rose_db_object_private.rdbo_seq2' ], 
      "pk sequence names 4 - $db_type");

    is_deeply(scalar MyPgWSObject2->meta->primary_key->sequence_names, 
      [ undef, 'Rose_db_object_private.rdbo_seq2_2' ], 
      "pk sequence names 5 - $db_type");

    is_deeply(scalar MyPgWSObject2->meta->primary_key_sequence_names(MyPgWSObject2->init_db), 
      [ undef, 'Rose_db_object_private.rdbo_seq2_2' ], 
      "pk sequence names 6 - $db_type");
  }
  else
  {
    SKIP { skip("non-pg tests", 8); }
  }
}

BEGIN
{
  our %HAVE;

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
    $HAVE{'pg'} = 1;
    $HAVE{'pg_with_schema'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test');
      $dbh->do('DROP TABLE Rose_db_object_test2 CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test2 CASCADE');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
      $dbh->do('DROP SEQUENCE rdbo_seq2');
      $dbh->do('DROP SEQUENCE rdbo_seq2_2');
      $dbh->do('DROP SEQUENCE Rose_db_object_private.rdbo_seq2');
      $dbh->do('DROP SEQUENCE Rose_db_object_private.rdbo_seq2_2');
      $dbh->do('CREATE SEQUENCE rdbo_seq2');
      $dbh->do('CREATE SEQUENCE rdbo_seq2_2');
      $dbh->do('CREATE SEQUENCE Rose_db_object_private.rdbo_seq2');
      $dbh->do('CREATE SEQUENCE Rose_db_object_private.rdbo_seq2_2');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id1   SERIAL NOT NULL,
  id2   INT NOT NULL DEFAULT nextval('rdbo_seq2'),
  name  VARCHAR(255),

  PRIMARY KEY (id1, id2)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_test
(
  id1   SERIAL NOT NULL,
  id2   INT NOT NULL DEFAULT nextval('Rose_db_object_private.rdbo_seq2'),
  name  VARCHAR(255),

  PRIMARY KEY (id1, id2)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test2
(
  id1   INT NOT NULL,
  id2   INT NOT NULL DEFAULT nextval('rdbo_seq2_2'),
  name  VARCHAR(255),

  PRIMARY KEY (id1, id2)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_test2
(
  id1   INT NOT NULL,
  id2   INT NOT NULL DEFAULT nextval('Rose_db_object_private.rdbo_seq2_2'),
  name  VARCHAR(255),

  PRIMARY KEY (id1, id2)
)
EOF


    $dbh->disconnect;

    package MyPgObject;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg') }
    MyPgObject->meta->table('Rose_db_object_test');
    MyPgObject->meta->columns(id1 => { type => 'serial' }, qw(id2 name));
    MyPgObject->meta->column('id2')->default_value_sequence_name('rdbo_seq2');
    MyPgObject->meta->primary_key_columns(qw(id1 id2));
    MyPgObject->meta->initialize;

    package MyPgWSObject;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg_with_schema') }
    MyPgWSObject->meta->table('Rose_db_object_test');
    MyPgWSObject->meta->columns(qw(id1 id2 name));
    MyPgWSObject->meta->primary_key_columns(qw(id1 id2));    
    MyPgWSObject->meta->primary_key->sequence_names(
      'Rose_db_object_private.rose_db_object_test_id1_seq',
      'Rose_db_object_private.rdbo_seq2');
    MyPgWSObject->meta->initialize;

    package MyPgObject2;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg') }
    MyPgObject2->meta->table('Rose_db_object_test2');
    MyPgObject2->meta->columns(qw(id1 id2 name));
    MyPgObject2->meta->column('id2')->default_value_sequence_name('rdbo_seq2_2');
    MyPgObject2->meta->primary_key_columns(qw(id1 id2));
    MyPgObject2->meta->initialize;

    package MyPgWSObject2;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg_with_schema') }
    MyPgWSObject2->meta->table('Rose_db_object_test2');
    MyPgWSObject2->meta->columns(qw(id1 id2 name));
    MyPgWSObject2->meta->primary_key_columns(qw(id1 id2));    
    MyPgWSObject2->meta->primary_key->sequence_names(
       undef,
      'Rose_db_object_private.rdbo_seq2_2');
    MyPgWSObject2->meta->initialize;
  }
}

END
{
  # Delete test table

  if($HAVE{'pg'})
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_test2 CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test2 CASCADE');
    $dbh->do('DROP SEQUENCE rdbo_seq2');
    $dbh->do('DROP SEQUENCE rdbo_seq2_2');
    $dbh->do('DROP SEQUENCE Rose_db_object_private.rdbo_seq2');
    $dbh->do('DROP SEQUENCE Rose_db_object_private.rdbo_seq2_2');
    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }
}
