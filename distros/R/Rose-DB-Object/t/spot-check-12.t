#!/usr/bin/perl

use strict;

use Test::More tests => 10;

require 't/test-lib.pl';

use Rose::DB::Object::Util qw(:children);
use Rose::DB::Object::Constants qw(MODIFIED_COLUMNS);
#
# This test was created by Lucian Dragus
#

SKIP:
{
  skip('sqlite tests', 10)  unless(have_db('sqlite_admin'));

  Rose::DB->default_type('sqlite');

  ###
  package Clients;
  use base 'Rose::DB::Object';
  __PACKAGE__->meta->setup(
      table => 'clients',

      columns => [
          id   => { type => 'integer', not_null => 1 },
          name => { type => 'varchar', not_null => 1 },
      ],

      primary_key_columns => ['id'],

      helpers => 'load_or_save',
      helpers => { load_or_insert => 'find_or_create2' }, 

      unique_key => ['name'],

      relationships => [
          address => {
              class      => 'Addresses',
              column_map => { id => 'client_id' },
              type       => 'one to one',
          },
      ],
  );

  sub init_db { Rose::DB->new }

  ###
  package Addresses;
  use base 'Rose::DB::Object';
  __PACKAGE__->meta->setup(
      table => 'addresses',

      columns => [
          id        => { type => 'integer', not_null => 1 },
          client_id => { type => 'integer', not_null => 1 },
          street    => { type => 'varchar' },
      ],

      primary_key_columns => ['id'],

      unique_key => ['client_id'],

      helpers => [ 'load_or_save', { load_or_insert => 'find_or_create' } ],

      ###foreign_keys => [
      ###    client => {
      ###        class       => 'Clients',
      ###        key_columns => { client_id => 'id' },
      ###    },
      ###],
  );

  sub init_db { Rose::DB->new }

  ###
  package main;
  {
      my $dbh = Rose::DB->new->retain_dbh();
      {
          local $dbh->{'RaiseError'} = 0;
          local $dbh->{'PrintError'} = 0;

          $dbh->do('DROP TABLE addresses');
          $dbh->do('DROP TABLE clients');
      }

      $dbh->do(<<"EOF");
CREATE TABLE clients
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  name  VARCHAR,

  UNIQUE(name)
)
EOF

      $dbh->do(<<"EOF");
CREATE TABLE addresses
(
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  client_id INT NOT NULL REFERENCES clients (id),
  street    VARCHAR,

  UNIQUE(client_id)
)
EOF

      $dbh->disconnect;
  }

  Clients->new( name => 'c1' )->save;

  ok(Addresses->can('load_or_save'), 'helpers 1');
  ok(Addresses->can('find_or_create'), 'helpers 2');

  ok(Clients->can('load_or_save'), 'helpers 3');
  ok(Clients->can('find_or_create2'), 'helpers 4');

  my $c = Clients->new( name => 'c1' );
  $c->load;

  my $a = Addresses->new( client_id => $c->id, street => 's1' );
  $c->address($a);

  #$Rose::DB::Object::Debug = 1;
  #$Rose::DB::Object::Manager::Debug = 1;

  ok($c->save( cascade => 1, changes_only => 1 ), 'save cascade changes only');


  $c = Rose::DB::Object::Manager->get_objects(
         object_class => 'Clients', 
         with_objects => 'address')->[0];

  ok(!keys %{ $c->{MODIFIED_COLUMNS()} || {} }, 'check modified columns');

  ok(has_loaded_related($c, 'address'), 'has_loaded_related() 1');
  ok(has_loaded_related(object => $c, relationship => 'address'), 'has_loaded_related() 2');

  $c->address->street('s2');

  ok($c->save(cascade => 1, changes_only => 1), 'save cascade changes only - loaded with Manager');

  $a = Addresses->new(id => $a->id)->load;

  is($a->street, 's2', 'save cascade changes only - check');
}

END
{
  if(have_db('sqlite_admin'))
  {
    my $dbh = get_dbh('sqlite_admin');
    local $dbh->{'RaiseError'} = 0;
    local $dbh->{'PrintError'} = 0;

    $dbh->do('DROP TABLE addresses');
    $dbh->do('DROP TABLE clients');
  }
}
