package Rose::DB::Oracle;

use strict;

use Carp();
use SQL::ReservedWords::Oracle();

use Rose::DB;

our $Debug = 0;

our $VERSION  = '0.767';

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar => '_default_post_connect_sql',
);

__PACKAGE__->_default_post_connect_sql
(
  [
    q(ALTER SESSION SET NLS_DATE_FORMAT = ') .
      ($ENV{'NLS_DATE_FORMAT'} || 'YYYY-MM-DD HH24:MI:SS') . q('),
    q(ALTER SESSION SET NLS_TIMESTAMP_FORMAT = ') . 
      ($ENV{'NLS_TIMESTAMP_FORMAT'} || 'YYYY-MM-DD HH24:MI:SS.FF') . q('),
    q(ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT = ') .
      ($ENV{'NLS_TIMESTAMP_TZ_FORMAT'} || 'YYYY-MM-DD HH24:MI:SS.FF TZHTZM') . q('),
  ]
);

sub default_post_connect_sql
{
  my($class) = shift;

  if(@_)
  {
    if(@_ == 1 && ref $_[0] eq 'ARRAY')
    {
      $class->_default_post_connect_sql(@_);
    }
    else
    {
      $class->_default_post_connect_sql([ @_ ]);
    }
  }

  return $class->_default_post_connect_sql;
}

sub post_connect_sql
{
  my($self) = shift;

  unless(@_)
  {
    return wantarray ? 
      ( @{ $self->default_post_connect_sql || [] }, @{$self->{'post_connect_sql'} || [] } ) :
      [ @{ $self->default_post_connect_sql || [] }, @{$self->{'post_connect_sql'} || [] } ];
  }

  if(@_ == 1 && ref $_[0] eq 'ARRAY')
  {
    $self->{'post_connect_sql'} = $_[0];
  }
  else
  {
    $self->{'post_connect_sql'} = [ @_ ];
  }

  return wantarray ? 
    ( @{ $self->default_post_connect_sql || [] }, @{$self->{'post_connect_sql'} || [] } ) :
    [ @{ $self->default_post_connect_sql || [] }, @{$self->{'post_connect_sql'} || [] } ];
}

sub schema
{
  my($self) = shift;
  $self->{'schema'} = shift  if(@_);
  return $self->{'schema'} || $self->username;
}

sub use_auto_sequence_name { 1 }

sub auto_sequence_name
{
  my($self, %args) = @_;

  my($table) = $args{'table'};
  Carp::croak 'Missing table argument' unless(defined $table);

  my($column) = $args{'column'};
  Carp::croak 'Missing column argument' unless(defined $column);

  return uc "${table}_${column}_SEQ";
}

sub build_dsn
{
  my($self_or_class, %args) = @_;

  my $database = $args{'db'} || $args{'database'};

  if($args{'host'} || $args{'port'})
  {
    $args{'sid'} = $database;

    return 'dbi:Oracle:' . 
      join(';', map { "$_=$args{$_}" } grep { $args{$_} } qw(sid host port));
  }

  return "dbi:Oracle:$database";
}

sub init_date_handler { Rose::DB::Oracle::DateHandler->new }

sub database_version
{
  my($self) = shift;

  return $self->{'database_version'} if (defined $self->{'database_version'});

  my($version) = $self->dbh->get_info(18); # SQL_DBMS_VER.

  # Convert to an integer, e.g., 10.02.0100 -> 100020100

  if($version =~ /^(\d+)\.(\d+)(?:\.(\d+))?/)
  {
    $version = sprintf('%d%03d%04d', $1, $2, $3);
  }

  return $self->{'database_version'} = $version;
}

sub dbi_driver { 'Oracle' }

sub likes_uppercase_table_names     { 1 }
sub likes_uppercase_schema_names    { 1 }
sub likes_uppercase_catalog_names   { 1 }
sub likes_uppercase_sequence_names  { 1 }

sub insertid_param { '' }

sub list_tables
{
  my($self, %args) = @_;

  my $types = $args{'include_views'} ? "'TABLE','VIEW'" : 'TABLE';

  my($error, @tables);

  TRY:
  {
    local $@;

    eval
    {
      my($dbh) = $self->dbh or die $self->error;

      local $dbh->{'RaiseError'} = 1;
      local $dbh->{'FetchHashKeyName'} = 'NAME';

      my $sth  = $dbh->table_info($self->catalog, uc $self->schema, '%', $types);
      my $info = $sth->fetchall_arrayref({}); # The {} are mandatory.

      for my $table (@$info)
      {
        push @tables, $$table{'TABLE_NAME'} if ($$table{'TABLE_NAME'} !~ /^BIN\$.+\$.+/);
      }
    };

    $error = $@;
  }

  if($error)
  {
    Carp::croak 'Could not list tables from ', $self->dsn, " - $error";
  }

  return wantarray ? @tables : \@tables;
}

sub next_value_in_sequence
{
  my($self, $sequence_name) = @_;

  my $dbh = $self->dbh or return undef;

  my($error, $value);

  TRY:
  {
    local $@;

    eval
    {
      local $dbh->{'PrintError'} = 0;
      local $dbh->{'RaiseError'} = 1;
      my $sth = $dbh->prepare("SELECT $sequence_name.NEXTVAL FROM DUAL");
      $sth->execute;
      $value = ${$sth->fetch}[0];
      $sth->finish;
    };

    $error = $@;
  }

  if($error)
  {
    $self->error("Could not get the next value in the sequence $sequence_name - $error");
    return undef;
  }

  return $value;
}

# Tried to execute a CURRVAL command on a sequence before the 
# NEXTVAL command was executed at least once.
use constant ORA_08002 => 8002;

sub current_value_in_sequence
{
  my($self, $sequence_name) = @_;

  my $dbh = $self->dbh or return undef;

  my($error, $value);

  TRY:
  {
    local $@;

    eval
    {
      local $dbh->{'PrintError'} = 0;
      local $dbh->{'RaiseError'} = 1;
      my $sth = $dbh->prepare("SELECT $sequence_name.CURRVAL FROM DUAL");

      $sth->execute;

      $value = ${$sth->fetch}[0];

      $sth->finish;
    };

    $error = $@;
  }

  if($error)
  {
    if(DBI->err == ORA_08002)
    {
      if(defined $self->next_value_in_sequence($sequence_name))
      {
        return $self->current_value_in_sequence($sequence_name);
      }
    }

    $self->error("Could not get the current value in the sequence $sequence_name - $error");
    return undef;
  }

  return $value;
}

# Sequence does not exist, or the user does not have the required
# privilege to perform this operation.
use constant ORA_02289 => 2289;

sub sequence_exists
{
  my($self, $sequence_name) = @_;

  my $dbh = $self->dbh or return undef;

  my $error;

  TRY:
  {
    local $@;

    eval
    {
      local $dbh->{'PrintError'} = 0;
      local $dbh->{'RaiseError'} = 1;
      my $sth = $dbh->prepare("SELECT $sequence_name.CURRVAL FROM DUAL");
      $sth->execute;
      $sth->fetch;
      $sth->finish;
    };

    $error = $@;
  }

  if($error)
  {
    my $dbi_error = DBI->err;

    if($dbi_error == ORA_08002)
    {
      if(defined $self->next_value_in_sequence($sequence_name))
      {
        return $self->sequence_exists($sequence_name);
      }
    }
    elsif($dbi_error == ORA_02289)
    {
      return 0;
    }

    $self->error("Could not check if sequence $sequence_name exists - $error");
    return undef;
  }

  return 1;
}

sub parse_dbi_column_info_default
{
  my($self, $default, $col_info) = @_;

  # For some reason, given a default value like this:
  #
  #   MYCOLUMN VARCHAR(128) DEFAULT 'foo' NOT NULL
  #
  # DBD::Oracle hands back a COLUMN_DEF value of:
  #
  #   $col_info->{'COLUMN_DEF'} = "'foo' "; # WTF?
  #
  # I have no idea why.  Anyway, we just want the value beteen the quotes.

  return undef unless (defined $default);

  $default =~ s/^\s*'(.+)'\s*$/$1/;

  return $default;
}

*is_reserved_word = \&SQL::ReservedWords::Oracle::is_reserved;

sub quote_identifier_for_sequence
{
  my($self, $catalog, $schema, $table) = @_;
  return join('.', map { uc } grep { defined } ($schema, $table));
}

# sub auto_quote_column_name
# {
#   my($self, $name) = @_;
# 
#   if($name =~ /[^\w#]/ || $self->is_reserved_word($name))
#   {
#     return $self->quote_column_name($name, @_);
#   }
# 
#   return $name;
# }

sub supports_schema { 1 }

sub max_column_name_length { 30 }
sub max_column_alias_length { 30 }

sub quote_column_name 
{
  my $name = uc $_[1];
  $name =~ s/"/""/g;
  return qq("$name");
}

sub quote_table_name
{
  my $name = uc $_[1];
  $name =~ s/"/""/g;
  return qq("$name");
}

sub quote_identifier {
  my($self) = shift;
  my $method = ref($self)->parent_class . '::quote_identifier';
  no strict 'refs';
  return uc $self->$method(@_);
}

sub primary_key_column_names
{
  my($self) = shift;

  my %args = @_ == 1 ? (table => @_) : @_;

  my $table   = $args{'table'} or Carp::croak "Missing table name parameter";
  my $schema  = $args{'schema'} || $self->schema;
  my $catalog = $args{'catalog'} || $self->catalog;

  no warnings 'uninitialized';
  $table   = uc $table;
  $schema  = uc $schema;
  $catalog = uc $catalog;

  my $table_unquoted = $self->unquote_table_name($table);

  my($error, $columns);

  TRY:
  {
    local $@;

    eval 
    {
      $columns = 
        $self->_get_primary_key_column_names($catalog, $schema, $table_unquoted);
    };

    $error = $@;
  }

  if($error || !$columns)
  {
    no warnings 'uninitialized'; # undef strings okay
    $error = 'no primary key columns found'  unless(defined $error);
    Carp::croak "Could not get primary key columns for catalog '" . 
                $catalog . "' schema '" . $schema . "' table '" . 
                $table_unquoted . "' - " . $error;
  }

  return wantarray ? @$columns : $columns;
}

sub format_limit_with_offset
{
  my($self, $limit, $offset, $args) = @_;

  delete $args->{'limit'};
  delete $args->{'offset'};

  if($offset)
  {
    # http://www.oracle.com/technology/oramag/oracle/06-sep/o56asktom.html
    # select * 
    #   from ( select /*+ FIRST_ROWS(n) */ 
    #   a.*, ROWNUM rnum 
    #       from ( your_query_goes_here, 
    #       with order by ) a 
    #       where ROWNUM <= 
    #       :MAX_ROW_TO_FETCH ) 
    # where rnum  >= :MIN_ROW_TO_FETCH;

    my $size  = $limit;
    my $start = $offset + 1;
    my $end   = $start + $size - 1;
    my $n     = $offset + $limit;

    $args->{'limit_prefix'} = 
      "SELECT * FROM (SELECT /*+ FIRST_ROWS($n) */\na.*, ROWNUM oracle_rownum FROM (";
      #"SELECT * FROM (SELECT a.*, ROWNUM oracle_rownum FROM (";

    $args->{'limit_suffix'} = 
      ") a WHERE ROWNUM <= $end) WHERE oracle_rownum >= $start";
  }
  else
  {
    $args->{'limit_prefix'} = "SELECT /*+ FIRST_ROWS($limit) */ a.* FROM (";
    #$args->{'limit_prefix'} = "SELECT a.* FROM (";
    $args->{'limit_suffix'} = ") a WHERE ROWNUM <= $limit";
  }
}

sub format_select_lock
{
  my($self, $class, $lock, $tables) = @_;

  $lock = { type => $lock }  unless(ref $lock);

  $lock->{'type'} ||= 'for update'  if($lock->{'for_update'});

  unless($lock->{'type'} eq 'for update')
  {
    Carp::croak "Invalid lock type: $lock->{'type'}";
  }

  my $sql = 'FOR UPDATE';

  my @columns;

  if(my $on = $lock->{'on'})
  {
    @columns = map { $self->column_sql_from_lock_on_value($class, $_, $tables) } @$on;
  }
  elsif(my $columns = $lock->{'columns'})
  {
    my %map;

    if($tables)
    {
      my $tn = 1;

      foreach my $table (@$tables)
      {
        (my $table_key = $table) =~ s/^(["']?)[^.]+\1\.//;
        $map{$table_key} = 't' . $tn++;
      }
    }

    @columns = map
      {
        ref $_ eq 'SCALAR' ? $$_ :
        /^([^.]+)\.([^.]+)$/ ? 
          $self->auto_quote_column_with_table($2, defined $map{$1} ? $map{$1} : $1) : 
          $self->auto_quote_column_name($_)
      }
      @$columns;
  }

  if(@columns)
  {
    $sql .= ' OF ' . join(', ', @columns);
  }

  if($lock->{'nowait'})
  {
    $sql .= ' NOWAIT';
  }
  elsif(my $wait = $lock->{'wait'})
  {
    $sql .= " WAIT $wait";
  }

  if($lock->{'skip_locked'})
  {
    $sql .= ' SKIP LOCKED';
  }

  return $sql;
}

sub format_boolean { $_[1] ? 't' : 'f' }

#
# Date/time keywords and inlining
#

sub validate_date_keyword
{
  no warnings;
  $_[1] =~ /^(?:CURRENT_|SYS|LOCAL)(?:TIMESTAMP|DATE)$/i ||
    ($_[0]->keyword_function_calls && $_[1] =~ /^\w+\(.*\)$/);
}

*validate_time_keyword      = \&validate_date_keyword;
*validate_timestamp_keyword = \&validate_date_keyword;
*validate_datetime_keyword  = \&validate_date_keyword;

sub should_inline_date_keyword      { 1 }
sub should_inline_datetime_keyword  { 1 }
sub should_inline_time_keyword      { 1 }
sub should_inline_timestamp_keyword { 1 }

package Rose::DB::Oracle::DateHandler;

use Rose::Object;
our @ISA = qw(Rose::Object);

use DateTime::Format::Oracle;

sub parse_date
{
  my($self, $value) = @_;

  local $DateTime::Format::Oracle::nls_date_format = $ENV{'NLS_DATE_FORMAT'} || 'YYYY-MM-DD HH24:MI:SS';

  # Add or extend the time to appease DateTime::Format::Oracle
  if($value =~ /\d\d:/)
  {
    $value =~ s/( \d\d:\d\d)([^:]|$)/$1:00$2/;
  }
  else
  {
    $value .= ' 00:00:00';
  }

  return DateTime::Format::Oracle->parse_date($value);
}

*parse_datetime = \&parse_date;

sub parse_timestamp
{
  my($self, $value) = @_;

  local $DateTime::Format::Oracle::nls_timestamp_format =
    $ENV{'NLS_TIMESTAMP_FORMAT'} || 'YYYY-MM-DD HH24:MI:SS.FF';

  # Add, extend, or truncate fractional seconds to appease DateTime::Format::Oracle
  for($value)
  {
    s/( \d\d:\d\d:\d\d)(?!\.)/$1.000000/ || 
    s/( \d\d:\d\d:\d\d\.)(\d{1,5})(\D|$)/ "$1$2" . ('0' x (6 - length($2))) . $3/e ||
    s/( \d\d:\d\d:\d\d\.\d{6})\d+/$1/;
  }

  return DateTime::Format::Oracle->parse_timestamp($value);
}

sub parse_timestamp_with_time_zone
{
  my($self, $value) = @_;

  local $DateTime::Format::Oracle::nls_timestamp_tz_format =
    $ENV{'NLS_TIMESTAMP_TZ_FORMAT'} || 'YYYY-MM-DD HH24:MI:SS.FF TZHTZM';

  # Add, extend, or truncate fractional seconds to appease DateTime::Format::Oracle
  for($value)
  {
    s/( \d\d:\d\d:\d\d)(?!\.)/$1.000000/ || 
    s/( \d\d:\d\d:\d\d\.)(\d{1,5})(\D|$)/ "$1$2" . ('0' x (6 - length($2))) . $3/e ||
    s/( \d\d:\d\d:\d\d\.\d{6})\d+/$1/;
  }

  return DateTime::Format::Oracle->parse_timestamp_with_time_zone($value);
}

sub format_date
{
  my($self) = shift;

  local $DateTime::Format::Oracle::nls_date_format =
    $ENV{'NLS_DATE_FORMAT'} || 'YYYY-MM-DD HH24:MI:SS';

  return DateTime::Format::Oracle->format_date(@_);
}

*format_datetime = \&format_date;

sub format_timestamp
{
  my($self) = shift;

  local $DateTime::Format::Oracle::nls_timestamp_format =
    $ENV{'NLS_TIMESTAMP_FORMAT'} || 'YYYY-MM-DD HH24:MI:SS.FF';

  return DateTime::Format::Oracle->format_timestamp(@_);
}

sub format_timestamp_with_time_zone
{
  my($self) = shift;

  local $DateTime::Format::Oracle::nls_timestamp_tz_format =
    $ENV{'NLS_TIMESTAMP_TZ_FORMAT'} || 'YYYY-MM-DD HH24:MI:SS.FF TZHTZM';

  return DateTime::Format::Oracle->format_timestamp_with_time_zone(@_);
}

1;

__END__

=head1 NAME

Rose::DB::Oracle - Oracle driver class for Rose::DB.

=head1 SYNOPSIS

  use Rose::DB;

  Rose::DB->register_db
  (
    domain   => 'development',
    type     => 'main',
    driver   => 'Oracle',
    database => 'dev_db',
    host     => 'localhost',
    username => 'devuser',
    password => 'mysecret',
  );

  Rose::DB->default_domain('development');
  Rose::DB->default_type('main');
  ...

  $db = Rose::DB->new; # $db is really a Rose::DB::Oracle-derived object
  ...

=head1 DESCRIPTION

L<Rose::DB> blesses objects into a class derived from L<Rose::DB::Oracle> when the L<driver|Rose::DB/driver> is "oracle".  This mapping of driver names to class names is configurable.  See the documentation for L<Rose::DB>'s L<new()|Rose::DB/new> and L<driver_class()|Rose::DB/driver_class> methods for more information.

This class cannot be used directly.  You must use L<Rose::DB> and let its L<new()|Rose::DB/new> method return an object blessed into the appropriate class for you, according to its L<driver_class()|Rose::DB/driver_class> mappings.

Only the methods that are new or have different behaviors than those in L<Rose::DB> are documented here.  See the L<Rose::DB> documentation for the full list of methods.

B<Oracle 9 or later is required.>

B<Note:> This class is a work in progress.  Support for Oracle databases is not yet complete.  If you would like to help, please contact John Siracusa at siracusa@gmail.com or post to the L<mailing list|Rose::DB/SUPPORT>.

=head1 CLASS METHODS

=over 4

=item B<default_post_connect_sql [STATEMENTS]>

Get or set the default list of SQL statements that will be run immediately after connecting to the database.  STATEMENTS should be a list or reference to an array of SQL statements.  Returns a reference to the array of SQL statements in scalar context, or a list of SQL statements in list context.

The L<default_post_connect_sql|/default_post_connect_sql> statements will be run before any statements set using the L<post_connect_sql|/post_connect_sql> method.  The default list contains the following:

    ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS.FF'
    ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT = 'YYYY-MM-DD HH24:MI:SS.FF TZHTZM'

If one or more C<NLS_*_FORMAT> environment variables are set, the format strings above are replaced by the values that these environment variables have I<at the time this module is loaded>.

=back

=head1 OBJECT METHODS

=over 4

=item B<post_connect_sql [STATEMENTS]>

Get or set the SQL statements that will be run immediately after connecting to the database.  STATEMENTS should be a list or reference to an array of SQL statements.  Returns a reference to an array (in scalar) or a list of the L<default_post_connect_sql|/default_post_connect_sql> statements and the L<post_connect_sql|/post_connect_sql> statements.  Example:

    $db->post_connect_sql('UPDATE mytable SET num = num + 1');

    print join("\n", $db->post_connect_sql);

    ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'
    ALTER SESSION SET NLS_TIMESTAMP_FORMAT='YYYY-MM-DD HH24:MI:SSxFF'
    UPDATE mytable SET num = num + 1

=item B<schema [SCHEMA]>

Get or set the database schema name.  In Oracle, every user has a corresponding schema.  The schema is comprised of all objects that user owns, and has the same name as that user.  Therefore, this attribute defaults to the L<username|Rose::DB/username> if it is not set explicitly.

=back

=head2 Value Parsing and Formatting

=over 4

=item B<validate_date_keyword STRING>

Returns true if STRING is a valid keyword for the PostgreSQL "date" data type.  Valid (case-insensitive) date keywords are:

    current_date
    current_timestamp
    localtimestamp
    months_between
    sysdate
    systimestamp

The keywords are case sensitive.  Any string that looks like a function call (matches C</^\w+\(.*\)$/>) is also considered a valid date keyword if L<keyword_function_calls|Rose::DB/keyword_function_calls> is true.

=item B<validate_timestamp_keyword STRING>

Returns true if STRING is a valid keyword for the Oracle "timestamp" data type, false otherwise.  Valid timestamp keywords are:

    current_date
    current_timestamp
    localtimestamp
    months_between
    sysdate
    systimestamp

The keywords are case sensitive.  Any string that looks like a function call (matches C</^\w+\(.*\)$/>) is also considered a valid timestamp keyword if L<keyword_function_calls|Rose::DB/keyword_function_calls> is true.

=back

=head1 AUTHORS

John C. Siracusa (siracusa@gmail.com), Ron Savage (ron@savage.net.au)

=head1 LICENSE

Copyright (c) 2008 by John Siracusa and Ron Savage.  All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
