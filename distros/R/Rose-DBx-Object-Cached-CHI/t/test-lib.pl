#!/usr/bin/perl

use strict;

use FindBin qw($Bin);

use Rose::DB;

BEGIN
{  
  Rose::DB->default_domain('test');

  #
  # Postgres
  #

  eval { require DBD::Pg };

  $ENV{'PGDATESTYLE'} = 'MDY';

  no warnings 'uninitialized';

  # Many tests don't work with DBD::Pg version 2.1.x and 2.2.0
  unless($DBD::Pg::VERSION =~ /^2\.(?:1\.|2\.0)/)
  {
    # Main
    Rose::DB->register_db(
      domain   => 'test',
      type     => 'pg',
      driver   => 'Pg',
      database => 'test',
      host     => 'localhost',
      username => 'postgres',
      password => '',
      connect_options => { AutoCommit => 1 },
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
      driver   => 'Pg',
      database => 'test',
      host     => 'localhost',
      username => 'postgres',
      password => '',
      connect_options => { AutoCommit => 1 },
      post_connect_sql =>
      [
        'SET default_transaction_isolation TO "read committed"',
      ],
    );

    # Admin
    Rose::DB->register_db(
      domain   => 'test',
      type     => 'pg_admin',
      driver   => 'Pg',
      database => 'test',
      host     => 'localhost',
      username => 'postgres',
      password => '',
      connect_options => { AutoCommit => 1 },
      post_connect_sql =>
      [
        'SET default_transaction_isolation TO "read committed"',
      ],
    );
  }

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
    connect_options => { AutoCommit => 1 },
    post_connect_sql =>
    [
      'SET LOCK MODE TO WAIT 100',
      'SET ISOLATION TO DIRTY READ',
    ],
  );

  # Admin
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'informix_admin',
    driver   => 'Informix',
    database => 'test@test',
    connect_options => { AutoCommit => 1 },
    post_connect_sql =>
    [
      'SET LOCK MODE TO WAIT 100',
      'SET ISOLATION TO DIRTY READ',
    ],
  );

  #
  # SQLite
  #

  eval
  {
    local $^W = 0;
    require DBD::SQLite;
  };

  my $version = $DBD::SQLite::VERSION || 0;

  unless($ENV{'RDBO_NO_SQLITE'} || $version < 1.11 || $version >= 1.13)
  {
    #unlink("$Bin/sqlite.db");

    # Main
    Rose::DB->register_db(
      domain   => 'test',
      type     => 'sqlite',
      driver   => 'sqlite',
      database => "$Bin/sqlite.db",
      auto_create     => 0,
      connect_options => { AutoCommit => 1 },
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
      connect_options => { AutoCommit => 1 },
      post_connect_sql =>
      [
        'PRAGMA synchronous = OFF',
        'PRAGMA temp_store = MEMORY',
      ],
    );
  }

  #
  # Oracle
  #

  # Main
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'oracle',
    driver   => 'oracle',
    database => 'test@test',
    connect_options => { AutoCommit => 1 },
  );

  # Admin
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'oracle_admin',
    driver   => 'oracle',
    database => 'test@test',
    connect_options => { AutoCommit => 1 },
  );

  my @types = qw(pg pg_with_schema pg_admin mysql mysql_admin 
                 informix informix_admin oracle oracle_admin);

  unless($Rose::DB::Object::Test::NoDefaults)
  {
    foreach my $db_type (qw(PG MYSQL INFORMIX ORACLE))
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
    $dbh = Rose::DB->new($type)->retain_dbh()
      or die Rose::DB->error;
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

sub mysql_supports_innodb
{
  my $db = get_db('mysql_admin') or return 0;

  eval
  {
    my $dbh = $db->dbh;

    CLEAR:
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rdbo_innodb_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_innodb_test 
(
  id INTEGER PRIMARY KEY
)
TYPE=InnoDB
EOF

    # MySQL will silently ignore the "TYPE=InnoDB" part and create
    # a MyISAM table instead.  MySQL is evil!  Now we have to manually
    # check to make sure an InnoDB table was really created.
    my $db_name = $db->database;
    my $sth = $dbh->prepare("SHOW TABLE STATUS FROM `$db_name` LIKE ?");
    $sth->execute('rdbo_innodb_test');
    my $info = $sth->fetchrow_hashref;

    unless(lc $info->{'Type'} eq 'innodb' || lc $info->{'Engine'} eq 'innodb')
    {
      die "Missing InnoDB support";
    }

    $dbh->do('DROP TABLE rdbo_innodb_test');
  };

  if($@)
  {
    warn $@  unless($@ =~ /Missing InnoDB support/);
    return 0;
  }

  return 1;
}

our $PG_HAS_CHKPASS = $ENV{'PG_HAS_CHKPASS'};

sub pg_has_chkpass
{
  return $PG_HAS_CHKPASS  if(defined $PG_HAS_CHKPASS);

  my $dbh = get_dbh('pg_admin') or return undef;

  eval
  {
    local $dbh->{'RaiseError'} = 1;
    local $dbh->{'PrintError'} = 0;
    $dbh->do('CREATE TABLE rose_db_object_chkpass_test (pass CHKPASS)');
    $dbh->do('DROP TABLE rose_db_object_chkpass_test');
  };

  return $PG_HAS_CHKPASS = $@ ? 0 : 1;
}

our $PG_MAX_CONNECTIONS;

sub pg_max_connections
{
  return $PG_MAX_CONNECTIONS  if(defined $PG_MAX_CONNECTIONS);

  my $dbh = get_dbh('pg') or return 0;
  my @dbh = ($dbh);

  for(;;)
  {
    eval { $dbh = get_dbh('pg') or die; push(@dbh, $dbh) };
    last if($@ || @dbh > 50);
  }

  return $PG_MAX_CONNECTIONS = @dbh;
}

sub oracle_is_broken
{
  return undef  unless(have_db('oracle'));

  my $db = get_db('oracle');

  # This particular version of Oracle 10g on Mac OS X is broken
  return ($db->database_version == 100010300 && $^O =~ /darwin/i) ? 1 : 0;
}

our $HAVE_TEST_MEMORY_CYCLE;

eval
{
  require Test::Memory::Cycle;
  $HAVE_TEST_MEMORY_CYCLE = 1;
};

sub test_memory_cycle_ok
{
  my($val, $msg) = @_;

  $HAVE_TEST_MEMORY_CYCLE ? 
    Test::Memory::Cycle::memory_cycle_ok($val, $msg) : 
    Test::More::ok(1, "$msg (skipped)");
}

my %Column_Args =
(
  enum => [ values => [ 'a' .. 'z' ] ],
);

sub nonpersistent_column_definitions
{
  my @columns;
  my $i = 1;

  foreach my $type (Rose::DB::Object::Metadata->column_type_names)
  {
    next  if($type =~ /(?:chkpass| to |serial|array|\bset\b)/);
    push(@columns, 'np' . $i++ => { type => $type, smart_modification => 0,
         temp => 1, @{ $Column_Args{$type} || [] } });
  }

  return @columns;
}

sub modify_nonpersistent_column_values
{
  my($object) = shift;
  
  foreach my $column ($object->meta->nonpersistent_columns)
  {
    my $method = $column->mutator_method_name;
    $object->$method(undef); # with smart modification off, this should be sufficient
  }
}

sub add_nonpersistent_columns_and_methods
{
  my($class) = shift;
  my $meta = $class->meta;
  
  $meta->add_columns(nonpersistent_column_definitions());
  $meta->make_nonpersistent_column_methods();
}

1;

