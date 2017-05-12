#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
}

our %Have;

#
# Test created by Jud
#

foreach my $db_type (qw(pg))
{
  SKIP:
  {
    skip("$db_type tests", 1)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  my $t1 = T1->new(id => 1)->save;
  my $t2 = T2->new(id => 1)->save;
  my $tt = T1T2Map->new;
  $tt->t1_id(1);
  $tt->t2_id(1);
  $tt->save;

  my @results = $t2->t1s;

  is(scalar @results, 1, "bigint keys - $db_type");
}

BEGIN
{
  our %Have;

  #
  # Pg
  #

  my $dbh;

  eval
  {
    my $db = Rose::DB->new('pg_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE t1_t2_map');
      $dbh->do('DROP TABLE t1');
      $dbh->do('DROP TABLE t2');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'pg'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE t1
(
  id BIGINT NOT NULL PRIMARY KEY
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE t2
(
  id BIGINT NOT NULL PRIMARY KEY
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE t1_t2_map
(
  t1_id BIGINT NOT NULL,
  t2_id BIGINT NOT NULL,

  PRIMARY KEY(t1_id, t2_id)
)
EOF

    $dbh->disconnect;

    Rose::DB->default_type('pg');

    package T1;
    our @ISA = qw(Rose::DB::Object);

    __PACKAGE__->meta->setup
    (
      table   => 't1',
      columns =>
      [
        id => { type => 'bigint', not_null => 1, primary_key => 1 },
      ],

      relationships => 
      [
        related => 
        {
          type      => 'many to many',
          map_class => 'T1T2Map',
          map_from  => 't1',
          map_to    => 't2',
        },
      ],
    );

    package T1T2Map;
    our @ISA = qw(Rose::DB::Object);

    __PACKAGE__->meta->setup
    (
      table   => 't1_t2_map',
      columns =>
      [
        t1_id => { type => 'bigint', not_null => 1 },
        t2_id => { type => 'bigint', not_null => 1 },
      ],

      primary_key_columns => ['t1_id', 't2_id'],

      foreign_keys => 
      [
        t1 => { class => 'T1' },
        t2 => { class => 'T2' },
      ],
    );

    package T2;
    our @ISA = qw(Rose::DB::Object);

    __PACKAGE__->meta->setup
    (
      table   => 't2',
      columns =>
      [
        id => { type => 'bigint', not_null => 1, primary_key => 1 },
      ],

      relationships =>
      [
        t1s => 
        {
          type       => 'many to many',
          map_class  => 'T1T2Map',
          column_map => { node_id => 'id' },
        },
      ],
    );
  }
}

END
{
  # Delete test tables

  if($Have{'pg'})
  {
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE t1_t2_map');
    $dbh->do('DROP TABLE t1');
    $dbh->do('DROP TABLE t2');
    $dbh->disconnect;
  }
}
