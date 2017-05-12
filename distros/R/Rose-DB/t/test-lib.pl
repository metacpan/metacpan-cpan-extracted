#!/usr/bin/perl

use strict;

use FindBin qw($Bin);

use Rose::DB;

BEGIN
{
  Rose::DB->default_domain('test');

  #
  # PostgreSQL
  #

  # Main
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'pg',
    driver   => 'pg',
    database => 'test',
    host     => 'localhost',
    username => 'postgres',
    password => '',
    post_connect_sql =>
    [
      'SET default_transaction_isolation TO "read committed"',
    ],
  );

  # Private schema
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'pg_with_schema',
    schema   => 'rose_db_object_private',
    driver   => 'pg',
    database => 'test',
    host     => 'localhost',
    username => 'postgres',
    password => '',
    post_connect_sql =>
    [
      'SET default_transaction_isolation TO "read committed"',
    ],
  );

  # Admin
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'pg_admin',
    driver   => 'pg',
    database => 'test',
    host     => 'localhost',
    username => 'postgres',
    password => '',
    post_connect_sql =>
    [
      'SET default_transaction_isolation TO "read committed"',
    ],
  );

  #
  # Oracle
  #

  # Main
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'oracle',
    driver   => 'oracle',
    database => 'test',
    host     => 'localhost',
    username => '',
    password => '',
    post_connect_sql =>
    [
      "alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS'",
    ],
  );

  # Admin
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'oracle_admin',
    driver   => 'oracle',
    database => 'test',
    host     => 'localhost',
    username => '',
    password => '',
    post_connect_sql =>
    [
      "alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS'",
    ],
  );

  #
  # MySQL
  #

  # Main
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'mysql',
    driver   => 'mysql',
    database => 'test',
    host     => 'localhost',
    username => 'root',
    password => ''
  );

  # Admin
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'mysql_admin',
    driver   => 'mysql',
    database => 'test',
    host     => 'localhost',
    username => 'root',
    password => ''
  );

  #
  # Informix
  #

  # Main
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'informix',
    driver   => 'Informix',
    database => 'test@test',
    connect_options => 
    {
      AutoCommit => 1, 
      ((rand() < 0.5) ? (FetchHashKeyName => 'NAME_lc') : ()),
    },
    post_connect_sql =>
    [
      'SET LOCK MODE TO WAIT 60',
      'SET ISOLATION TO DIRTY READ',
    ],
  );

  # Admin
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'informix_admin',
    driver   => 'Informix',
    database => 'test@test',
    connect_options => 
    {
      AutoCommit => 1, 
      ((rand() < 0.5) ? (FetchHashKeyName => 'NAME_lc') : ()),
    },
    post_connect_sql =>
    [
      'SET LOCK MODE TO WAIT 60',
      'SET ISOLATION TO DIRTY READ',
    ],
  );

  # Just test that the catalog attribute works.  No supported DBs use it.
  Rose::DB->register_db(
    domain   => 'catalog_test',
    type     => 'catalog_test',
    driver   => 'pg',
    database => 'test',
    catalog  => 'somecatalog',
    schema   => 'someschema',
    host     => 'localhost',
    username => 'postgres',
    password => '',
  );

  #
  # SQLite
  #

  eval
  {
    local $^W = 0;
    require DBD::SQLite;
  };

  (my $version = $DBD::SQLite::VERSION || 0) =~ s/_//g;

  unless($ENV{'RDBO_NO_SQLITE'} || $version < 1.11 || ($version >= 1.13 && $version < 1.1902))
  {
    # Main
    Rose::DB->register_db(
      domain   => 'test',
      type     => 'sqlite',
      driver   => 'sqlite',
      database => "$Bin/sqlite.db",
      auto_create     => 0,
      connect_options => 
      {
        AutoCommit => 1, 
        ((rand() < 0.5) ? (FetchHashKeyName => 'NAME_lc') : ()),
      },
      post_connect_sql =>
      [
        'PRAGMA synchronous = OFF',
        'PRAGMA temp_store = MEMORY',
      ],
    );

    # Admin
    Rose::DB->register_db(
      domain   => 'test',
      type     => 'sqlite_admin',
      driver   => 'sqlite',
      database => "$Bin/sqlite.db",
      connect_options => 
      {
        AutoCommit => 1, 
        ((rand() < 0.5) ? (FetchHashKeyName => 'NAME_lc') : ()),
      },
      post_connect_sql =>
      [
        'PRAGMA synchronous = OFF',
        'PRAGMA temp_store = MEMORY',
      ],
    );
  }

  my @types = qw(oracle oracle_admin pg pg_with_schema pg_admin mysql mysql_admin
                 informix informix_admin sqlite sqlite_admin);

  unless($Rose::DB::Object::Test::NoDefaults)
  {
    foreach my $db_type (qw(ORACLE PG MYSQL INFORMIX))
    {
      if(my $dsn = $ENV{"RDBO_${db_type}_DSN"})
      {
        foreach my $type (grep { /^$db_type(?:_|$)/i } @types)
        {
          Rose::DB->modify_db(domain => 'test', type => $type, dsn => $dsn);
        }
      }

      if(my $user = $ENV{"RDBO_${db_type}_USER"})
      {
        foreach my $type (grep { /^$db_type(?:_|$)/i } @types)
        {
          Rose::DB->modify_db(domain => 'test', type => $type, username => $user);
        }
      }

      if(my $user = $ENV{"RDBO_${db_type}_PASS"})
      {
        foreach my $type (grep { /^$db_type(?:_|$)/i } @types)
        {
          Rose::DB->modify_db(domain => 'test', type => $type, password => $user);
        }
      }
    }
  }
}

Rose::DB->load_driver_classes(qw(ORAcle pg MySQL informix SQLItE));

# Subclass testing
package My::DB;
@My::DB::ISA = qw(Rose::DB);

package My::DB2;
@My::DB2::ISA = qw(My::DB);

sub init_dbh
{
  my($self) = shift;
  $My::DB2::Called{'init_dbh'}++;
  $self->SUPER::init_dbh(@_);
}

package My::DB2::Oracle;
@My::DB2::Oracle::ISA = qw(Rose::DB::Oracle);

sub subclass_special_oracle { 'ORACLE' }

package My::DB2::Pg;
@My::DB2::Pg::ISA = qw(Rose::DB::Pg);

sub subclass_special_pg { 'PG' }

package My::DB2::MySQL;
@My::DB2::MySQL::ISA = qw(Rose::DB::MySQL);

sub subclass_special_mysql { 'MYSQL' }

package My::DB2::Informix;
@My::DB2::Informix::ISA = qw(Rose::DB::Informix);

sub subclass_special_informix { 'INFORMIX' }

My::DB2->driver_class(Oracle => 'My::DB2::Oracle');
My::DB2->driver_class(Pg => 'My::DB2::Pg');
My::DB2->driver_class(mysql => 'My::DB2::MySQL');
My::DB2->driver_class(Informix => 'My::DB2::Informix');

package My::DB3;
@My::DB3::ISA = qw(My::DB2);

My::DB3->use_private_registry;

package My::DBReg;
@My::DBReg::ISA = qw(Rose::DB);

My::DBReg->registry(Rose::DB::Registry->new);

My::DBReg->register_db(
  domain   => 'test',
  type     => 'pg_sub',
  driver   => 'Pg',
  database => 'test_sub',
  host     => 'subhost',
  username => 'subuser');

package main;

my %Have_DB;

sub get_db
{
  my($type) = shift;

  if((defined $Have_DB{$type} && !$Have_DB{$type}) || !get_dbh($type))
  {
    return undef;
  }

  return Rose::DB->new($type);
}

sub get_dbh
{
  my($type) = shift;

  my $dbh;

  eval 
  {
    my $db = Rose::DB->new($type);
    $db->print_error(0);
    $dbh = $db->retain_dbh or die Rose::DB->error;
    $db->print_error(1);
  };

  if(!$@ && $dbh)
  {
    $Have_DB{$type} = 1;
    return $dbh;
  }

  return $Have_DB{$type} = 0;
}

sub have_db
{
  my($type) = shift;

  if($type =~ /^sqlite(?:_admin)$/ && $ENV{'RDBO_NO_SQLITE'})
  {
    return $Have_DB{$type} = 0;
  }

  return $Have_DB{$type} = shift if(@_);
  return $Have_DB{$type}  if(exists $Have_DB{$type});
  return get_dbh($type) ? 1 : 0;
}

1;

