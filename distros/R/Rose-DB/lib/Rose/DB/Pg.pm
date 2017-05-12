package Rose::DB::Pg;

use strict;

use DateTime::Infinite;
use DateTime::Format::Pg;
use SQL::ReservedWords::PostgreSQL();

use Rose::DB;

our $VERSION = '0.786'; # overshot version number, freeze until caught up

our $Debug = 0;

#
# Object data
#

use Rose::Object::MakeMethods::Generic
(
  'scalar' =>
  [
    qw(sslmode service options)
  ],
);

#
# Object methods
#

sub build_dsn
{
  my($self_or_class, %args) = @_;

  my %info;

  $info{'dbname'} = $args{'db'} || $args{'database'};

  @info{qw(host port options service sslmode)} =
    @args{qw(host port options service sslmode)};

  return
    "dbi:Pg:" . 
    join(';', map { "$_=$info{$_}" } grep { defined $info{$_} }
              qw(dbname host port options service sslmode));
}

sub dbi_driver { 'Pg' }

sub init_date_handler
{
  my($self) = shift;

  my $parent_class = ref($self)->parent_class;
  my $european_dates   = "${parent_class}::european_dates";
  my $server_time_zone = "${parent_class}::server_time_zone";

  no strict 'refs';
  my $parser = 
    DateTime::Format::Pg->new(
      ($self->$european_dates() ? (european => 1) : ()),
      ($self->$server_time_zone() ? 
        (server_tz => $self->$server_time_zone()) : ()));

  return $parser;
}

sub default_implicit_schema { 'public' }
sub likes_lowercase_table_names    { 1 }
sub likes_lowercase_schema_names   { 1 }
sub likes_lowercase_catalog_names  { 1 }
sub likes_lowercase_sequence_names { 1 }

sub supports_multi_column_count_distinct  { 0 }
sub supports_arbitrary_defaults_on_insert { 1 }
sub supports_select_from_subselect        { 1 }

sub pg_enable_utf8 { shift->dbh_attribute_boolean('pg_enable_utf8', @_) }

sub supports_schema { 1 }

sub max_column_name_length { 63 }
sub max_column_alias_length { 63 }

sub last_insertid_from_sth
{
  #my($self, $sth, $obj) = @_;

  # PostgreSQL demands that the primary key column not be in the insert
  # statement at all in order for it to auto-generate a value.  The
  # insert SQL will need to be modified to make this work for
  # Rose::DB::Object...
  #if($DBD::Pg::VERSION >= 1.40)
  #{
  #  my $meta = $obj->meta;
  #  return $self->dbh->last_insert_id(undef, $meta->select_schema, $meta->table, undef);
  #}

  return undef;
}

sub format_select_lock
{
  my($self, $class, $lock, $tables_list) = @_;

  $lock = { type => $lock }  unless(ref $lock);

  $lock->{'type'} ||= 'for update'  if($lock->{'for_update'});

  my %types =
  (
    'for update' => 'FOR UPDATE',
    'shared'     => 'FOR SHARE',
  );

  my $sql = $types{$lock->{'type'}}
    or Carp::croak "Invalid lock type: $lock->{'type'}";

  my @tables;

  if(my $on = $lock->{'on'})
  {
    @tables = map { $self->table_sql_from_lock_on_value($class, $_, $tables_list) } @$on;
  }
  elsif(my $lock_tables = $lock->{'tables'})
  {
    my %map;

    if($tables_list)
    {
      my $tn = 1;

      foreach my $table (@$tables_list)
      {
        (my $table_key = $table) =~ s/^(["']?)[^.]+\1\.//;
        $map{$table_key} = 't' . $tn++;
      }
    }

    @tables = map
      {
        ref $_ eq 'SCALAR' ? $$_ :
          $self->auto_quote_table_name(defined $map{$_} ? $map{$_} : $_)
      }
      @$lock_tables;
  }

  if(@tables)
  {
    $sql .= ' OF ' . join(', ', @tables);
  }

  $sql .= ' NOWAIT'  if($lock->{'nowait'});

  return $sql;
}

sub parse_datetime
{
  my($self) = shift;

  unless(ref $_[0])
  {
    no warnings 'uninitialized';
    return DateTime::Infinite::Past->new   if($_[0] eq '-infinity');
    return DateTime::Infinite::Future->new if($_[0] eq 'infinity');
  }

  my $method = ref($self)->parent_class . '::parse_datetime';

  no strict 'refs';
  $self->$method(@_);
}

sub parse_timestamp
{
  my($self) = shift;

  unless(ref $_[0])
  {
    no warnings 'uninitialized';
    return DateTime::Infinite::Past->new   if($_[0] eq '-infinity');
    return DateTime::Infinite::Future->new if($_[0] eq 'infinity');
  }

  my $method = ref($self)->parent_class . '::parse_timestamp';

  no strict 'refs';
  $self->$method(@_);
}

sub parse_timestamp_with_time_zone
{
  my($self, $value) = @_;

  unless(ref $value)
  {
    no warnings 'uninitialized';
    return DateTime::Infinite::Past->new   if($value eq '-infinity');
    return DateTime::Infinite::Future->new if($value eq 'infinity');
  }

  my $method = ref($self)->parent_class . '::parse_timestamp_with_time_zone';

  no strict 'refs';
  shift->$method(@_);
}

sub validate_date_keyword
{
  no warnings;
  $_[1] =~ /^(?:(?:now|timeofday)(?:\(\))?|(?:current_(?:date|time(?:stamp)?)
    |localtime(?:stamp)?)(?:\(\d*\))?|epoch|today|tomorrow|yesterday|)$/xi ||
    ($_[0]->keyword_function_calls && $_[1] =~ /^\w+\(.*\)$/);
}

sub validate_time_keyword
{
  no warnings;
  $_[1] =~ /^(?:(?:now|timeofday)(?:\(\))?|(?:current_(?:date|time(?:stamp)?)
    |localtime(?:stamp)?)(?:\(\d*\))?|allballs)$/xi ||
    ($_[0]->keyword_function_calls && $_[1] =~ /^\w+\(.*\)$/);
}

sub validate_timestamp_keyword
{
  no warnings;
  $_[1] =~ /^(?:(?:now|timeofday)(?:\(\))?|(?:current_(?:date|time(?:stamp)?)
    |localtime(?:stamp)?)(?:\(\d*\))?|-?infinity|epoch|today|tomorrow|yesterday|allballs)$/xi ||
    ($_[0]->keyword_function_calls && $_[1] =~ /^\w+\(.*\)$/);

}

*validate_datetime_keyword = \&validate_timestamp_keyword;

sub server_time_zone
{
  my($self) = shift;

  $self->{'date_handler'} = undef  if(@_);

  my $method = ref($self)->parent_class . '::server_time_zone';

  no strict 'refs';
  $self->$method(@_);
}

sub european_dates
{
  my($self) = shift;

  $self->{'date_handler'} = undef  if(@_);

  my $method = ref($self)->parent_class . '::european_dates';

  no strict 'refs';
  $self->$method(@_);
}

sub parse_array
{
  my($self) = shift;

  return $_[0]  if(ref $_[0]);
  return [ @_ ] if(@_ > 1);

  my $val = $_[0];

  return undef  unless(defined $val);

  $val =~ s/^ (?:\[.+\]=)? \{ (.*) \} $/$1/sx;

  my @array;

  while($val =~ s/(?:"((?:[^"\\]+|\\.)*)"|([^",]+))(?:,|$)//)
  {
    my($item) = map { $_ eq 'NULL' ? undef : $_ } (defined $1 ? $1 : $2);
    $item =~ s{\\(.)}{$1}g  if(defined $item);
    push(@array, $item);
  }

  return \@array;
}

sub format_array
{
  my($self) = shift;

  return undef  unless(ref $_[0] || defined $_[0]);

  my @array = (ref $_[0]) ? @{$_[0]} : @_;

  return '{' . join(',', map 
  {
    if(!defined $_)
    {
      'NULL'
    }
    elsif(/^[-+]?\d+(?:\.\d*)?$/)
    {
      $_
    }
    elsif(ref($_) eq 'ARRAY')
    {
      $self->format_array($_);
    }
    else
    {
      s/\\/\\\\/g; 
      s/"/\\"/g;
      qq("$_") 
    }
  } @array) . '}';
}

sub parse_interval
{
  my($self, $value, $end_of_month_mode) = @_;

  if(!defined $value || UNIVERSAL::isa($value, 'DateTime::Duration') || 
     $self->validate_interval_keyword($value) || 
     ($self->keyword_function_calls && $value =~ /^\w+\(.*\)$/))
  {
    return $value;
  }

  my($dt_duration, $error);

  TRY:
  {
    local $@;
    eval { $dt_duration = $self->date_handler->parse_interval($value) };
    $error = $@;
  }

  my $method = ref($self)->parent_class . '::parse_interval';

  no strict 'refs';
  return $self->$method($value, $end_of_month_mode)  if($error);

  if(defined $end_of_month_mode && $dt_duration)
  {
    # XXX: There is no mutator for end_of_month_mode, so I'm being evil
    # XXX: and setting it directly.  Blah.
    $dt_duration->{'end_of_month'} = $end_of_month_mode;
  }

  return $dt_duration;
}

BEGIN
{
  require DateTime::Format::Pg;

  # Handle DateTime::Format::Pg bug
  # http://rt.cpan.org/Public/Bug/Display.html?id=18487  
  if($DateTime::Format::Pg::VERSION < 0.11)
  {
    *format_interval = sub
    {
      my($self, $dur) = @_;
      return $dur  if(!defined $dur || $self->validate_interval_keyword($dur) ||
        ($self->keyword_function_calls && $dur =~ /^\w+\(.*\)$/));
      my $val = $self->date_handler->format_interval($dur);

      $val =~ s/(\S+e\S+) seconds/sprintf('%f seconds', $1)/e;
      return $val;
    };
  }
  else
  {
    *format_interval = sub
    {
      my($self, $dur) = @_;
      return $dur  if(!defined $dur || $self->validate_interval_keyword($dur) ||
        ($self->keyword_function_calls && $dur =~ /^\w+\(.*\)$/));
      return $self->date_handler->format_interval($dur);
    };
  }
}

sub next_value_in_sequence
{
  my($self, $sequence_name) = @_;

  my $dbh = $self->dbh or return undef;

  my($value, $error);

  TRY:
  {
    local $@;

    eval
    {
      local $dbh->{'PrintError'} = 0;
      local $dbh->{'RaiseError'} = 1;
      my $sth = $dbh->prepare(qq(SELECT nextval(?)));
      $sth->execute($sequence_name);
      $value = ${$sth->fetchrow_arrayref}[0];
    };

    $error = $@;
  }

  if($error)
  {
    $self->error("Could not get the next value in the sequence '$sequence_name' - $error");
    return undef;
  }

  return $value;
}

sub current_value_in_sequence
{
  my($self, $sequence_name) = @_;

  my $dbh = $self->dbh or return undef;

  my($value, $error);

  TRY:
  {
    local $@;

    eval
    {
      local $dbh->{'PrintError'} = 0;
      local $dbh->{'RaiseError'} = 1;
      my $name = $dbh->quote_identifier($sequence_name);
      my $sth = $dbh->prepare(qq(SELECT last_value FROM $name));
      $sth->execute;
      $value = ${$sth->fetchrow_arrayref}[0];
    };

    $error = $@;
  }

  if($error)
  {
    $self->error("Could not get the current value in the sequence '$sequence_name' - $error");
    return undef;
  }

  return $value;
}

sub sequence_exists { defined shift->current_value_in_sequence(@_) ? 1 : 0 }

sub use_auto_sequence_name { 1 }

sub auto_sequence_name
{
  my($self, %args) = @_;

  my $table = $args{'table'};
  Carp::croak "Missing table argument"  unless(defined $table);

  my $column = $args{'column'};
  Carp::croak "Missing column argument"  unless(defined $column);

  return lc "${table}_${column}_seq";
}

*is_reserved_word = \&SQL::ReservedWords::PostgreSQL::is_reserved;

#
# DBI introspection
#

sub refine_dbi_column_info
{
  my($self, $col_info, $meta) = @_;

  # Save default value
  my $default = $col_info->{'COLUMN_DEF'};

  my $method = ref($self)->parent_class . '::refine_dbi_column_info';

  no strict 'refs';
  $self->$method($col_info);


  if(defined $default)
  {
    # Set sequence name key, if present
    if($default =~ /^nextval\(\(?'((?:''|[^']+))'::\w+/)
    {
      $col_info->{'rdbo_default_value_sequence_name'} = 
        $self->likes_lowercase_sequence_names ? lc $1 : $1;

      if($meta)
      {
        my $seq = $col_info->{'rdbo_default_value_sequence_name'};

        my $implicit_schema = $self->default_implicit_schema;

        # Strip off default implicit schema unless a schema is explicitly 
        # specified in the RDBO metadata object.
        if(defined $seq && defined $implicit_schema && !defined $meta->schema)
        {
          $seq =~ s/^$implicit_schema\.//;
        }

        $col_info->{'rdbo_default_value_sequence_name'} = $self->unquote_column_name($seq);

        # Pg returns serial columns as integer or bigint
        if($col_info->{'TYPE_NAME'} eq 'integer' ||
           $col_info->{'TYPE_NAME'} eq 'bigint')
        {
          my $db = $meta->db;

          my $auto_seq =
            $db->auto_sequence_name(table  => $meta->table,
                                    column => $col_info->{'COLUMN_NAME'});

          # Use schema prefix on auto-generated name if necessary
          if($seq =~ /^[^.]+\./)
          {
            my $schema = $meta->select_schema($db);
            $auto_seq = "$schema.$auto_seq"  if($schema);
          }

          no warnings 'uninitialized';
          if(lc $seq eq lc $auto_seq)
          {
            $col_info->{'TYPE_NAME'} =
              $col_info->{'TYPE_NAME'} eq 'integer' ? 'serial' : 'bigserial';
          }
        }
      }
    }
    elsif($default =~ /^NULL::[\w ]+$/)
    {
      # RT 64331: https://rt.cpan.org/Ticket/Display.html?id=64331
      $col_info->{'COLUMN_DEF'} = undef;
    }
  }

  my $type_name = $col_info->{'TYPE_NAME'};

  # Pg has some odd/different names for types.  Convert them to standard forms.
  if($type_name eq 'character varying')
  {
    $col_info->{'TYPE_NAME'} = 'varchar';
  }
  elsif($type_name eq 'bit')
  {
    $col_info->{'TYPE_NAME'} = 'bits';
  }
  elsif($type_name eq 'real')
  {
    $col_info->{'TYPE_NAME'} = 'float';
  }
  elsif($type_name eq 'time without time zone')
  {
    $col_info->{'TYPE_NAME'} = 'time';
    $col_info->{'pg_type'} =~ /^time(?:\((\d+)\))? without time zone$/i;
    $col_info->{'TIME_SCALE'} = $1 || 0;
  }
  elsif($type_name eq 'double precision')
  {
    $col_info->{'COLUMN_SIZE'} = undef;
  }
  elsif($type_name eq 'money')
  {
    $col_info->{'COLUMN_SIZE'} = undef;
  }

  # Pg does not populate COLUMN_SIZE correctly for bit fields, so
  # we have to extract the number of bits from pg_type.
  if($col_info->{'pg_type'} =~ /^bit\((\d+)\)$/)
  {
    $col_info->{'COLUMN_SIZE'} = $1;
  }

  # Extract precision and scale from numeric types
  if($col_info->{'pg_type'} =~ /^numeric/i)
  {
    no warnings 'uninitialized';

    if($col_info->{'COLUMN_SIZE'} =~ /^(\d+),(\d+)$/)
    {
      $col_info->{'COLUMN_SIZE'}    = $1;
      $col_info->{'DECIMAL_DIGITS'} = $2;
    }
    elsif($col_info->{'pg_type'} =~ /^numeric\((\d+),(\d+)\)$/i)
    {
      $col_info->{'COLUMN_SIZE'}    = $2;
      $col_info->{'DECIMAL_DIGITS'} = $1;
    }
  }

  # Treat custom types that look like enums as enums
  if(ref $col_info->{'pg_enum_values'} && @{$col_info->{'pg_enum_values'}})
  {
    $col_info->{'TYPE_NAME'} = 'enum';
    $col_info->{'RDBO_ENUM_VALUES'} = $col_info->{'pg_enum_values'};
    $col_info->{'RDBO_DB_TYPE'} = $col_info->{'pg_type'};
  }

  # We currently treat all arrays the same, regardless of what they are 
  # arrays of: integer, character, float, etc.  So we covert TYPE_NAMEs
  # like 'integer[]' into 'array'
  if($col_info->{'TYPE_NAME'} =~ /^\w.*\[\]$/)
  {
    $col_info->{'TYPE_NAME'} = 'array';
  }

  return;
}

sub parse_dbi_column_info_default 
{
  my($self, $string, $col_info) = @_;

  no warnings 'uninitialized';
  local $_ = $string;

  my $pg_vers = $self->dbh->{'pg_server_version'};

  # Example: q(B'00101'::"bit")
  if(/^B'([01]+)'::(?:bit|"bit")$/ && $col_info->{'TYPE_NAME'} eq 'bit')
  {
    return $1;
  }
  # Example: 922337203685::bigint
  elsif(/^(.+)::"?bigint"?$/i && $col_info->{'TYPE_NAME'} eq 'bigint')
  {
    return $1;
  }
  # TODO: http://rt.cpan.org/Ticket/Display.html?id=35462
  # Example: '{foo,"\\"bar,",baz}'::text[]
  # ...
  # Example: 'value'::character varying
  # Example: ('now'::text)::timestamp(0)
  elsif(/^\(*'(.*)'::.+$/)
  {
    my $default = $1;

    # Single quotes are backslash-escaped, but PostgreSQL 8.1 and
    # later uses doubled quotes '' instead.  Strangely, I see
    # doubled quotes in 8.0.x as well...
    if($pg_vers >= 80000 && index($default, q('')) > 0)
    {
      $default =~ s/''/'/g;
    }
    elsif($pg_vers < 80100 && index($default, q(\')) > 0)
    {
      $default = $1;
      $default =~ s/\\'/'/g;
    }

    return $default;
  }
  # Handle sequence-based defaults elsewhere
  elsif(/^nextval\(/)
  {
    return undef;
  }

  return $string;
}

sub list_tables
{
  my($self, %args) = @_;

  my $types = $args{'include_views'} ? "'TABLE','VIEW'" : 'TABLE';
  my @tables;

  my $schema = $self->schema;
  $schema = $self->default_implicit_schema  unless(defined $schema);

  my $error;

  TRY:
  {
    local $@;

    eval
    {
      my $dbh = $self->dbh or die $self->error;

      local $dbh->{'RaiseError'} = 1;
      local $dbh->{'FetchHashKeyName'} = 'NAME';

      my $sth = $dbh->table_info($self->catalog, $schema, '', $types,
                                 { noprefix => 1, pg_noprefix => 1 });

      $sth->execute;

      while(my $table_info = $sth->fetchrow_hashref)
      {
        push(@tables, $self->unquote_table_name($table_info->{'TABLE_NAME'}));
      }
    };

    $error = $@;
  }

  if($error)
  {
    Carp::croak "Could not list tables from ", $self->dsn, " - $error";
  }

  return wantarray ? @tables : \@tables;
}

# sub list_tables
# {
#   my($self) = shift;
# 
#   my @tables;
# 
#   my $schema = $self->schema;
#   $schema = $db->default_implicit_schema  unless(defined $schema);
#     
#   if($DBD::Pg::VERSION >= 1.31) 
#   {
#     @tables = $self->dbh->tables($self->catalog, $schema, '', 'TABLE',
#                               { noprefix => 1, pg_noprefix => 1 });
#     }
#     else 
#     {
#       @tables = $dbh->tables;
#     }
#   }
# 
#   return wantarray ? @tables : \@tables;
# }

1;

__END__

=head1 NAME

Rose::DB::Pg - PostgreSQL driver class for Rose::DB.

=head1 SYNOPSIS

  use Rose::DB;

  Rose::DB->register_db(
    domain   => 'development',
    type     => 'main',
    driver   => 'Pg',
    database => 'dev_db',
    host     => 'localhost',
    username => 'devuser',
    password => 'mysecret',
    server_time_zone => 'UTC',
    european_dates   => 1,
  );

  Rose::DB->default_domain('development');
  Rose::DB->default_type('main');
  ...

  $db = Rose::DB->new; # $db is really a Rose::DB::Pg-derived object
  ...

=head1 DESCRIPTION

L<Rose::DB> blesses objects into a class derived from L<Rose::DB::Pg> when the L<driver|Rose::DB/driver> is "pg".  This mapping of driver names to class names is configurable.  See the documentation for L<Rose::DB>'s L<new()|Rose::DB/new> and L<driver_class()|Rose::DB/driver_class> methods for more information.

This class cannot be used directly.  You must use L<Rose::DB> and let its L<new()|Rose::DB/new> method return an object blessed into the appropriate class for you, according to its L<driver_class()|Rose::DB/driver_class> mappings.

Only the methods that are new or have different behaviors than those in L<Rose::DB> are documented here.  See the L<Rose::DB> documentation for the full list of methods.

=head1 OBJECT METHODS

=over 4

=item B<european_dates [BOOL]>

Get or set the boolean value that determines whether or not dates are assumed to be in european dd/mm/yyyy format.  The default is to assume US mm/dd/yyyy format (because this is the default for PostgreSQL).

This value will be passed to L<DateTime::Format::Pg> as the value of the C<european> parameter in the call to the constructor C<new()>.  This L<DateTime::Format::Pg> object is used by L<Rose::DB::Pg> to parse and format date-related column values in methods like L<parse_date|Rose::DB/parse_date>, L<format_date|Rose::DB/format_date>, etc.

=item B<next_value_in_sequence SEQUENCE>

Advance the sequence named SEQUENCE and return the new value.  Returns undef if there was an error.

=item B<server_time_zone [TZ]>

Get or set the time zone used by the database server software.  TZ should be a time zone name that is understood by L<DateTime::TimeZone>.  The default value is "floating".

This value will be passed to L<DateTime::Format::Pg> as the value of the C<server_tz> parameter in the call to the constructor C<new()>.  This L<DateTime::Format::Pg> object is used by L<Rose::DB::Pg> to parse and format date-related column values in methods like L<parse_date|Rose::DB/parse_date>, L<format_date|Rose::DB/format_date>, etc.

See the L<DateTime::TimeZone> documentation for acceptable values of TZ.

=item B<pg_enable_utf8 [BOOL]>

Get or set the L<pg_enable_utf8|DBD::Pg/pg_enable_utf8> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::Pg> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::Pg|DBD::Pg/pg_enable_utf8> documentation to learn more about this attribute.

=item B<sslmode [MODE]>

Get or set the SSL mode of the connection.  Valid values for MODE are C<disable>, C<allow>, C<prefer>, and C<require>.  This attribute is used to build the L<DBI> L<dsn|Rose::DB/dsn>.  Setting it has no effect until the next L<connect|Rose::DB/connect>ion.  See the L<DBD::Pg|DBD::Pg/connect> documentation to learn more about this attribute.

=back

=head2 Value Parsing and Formatting

=over 4

=item B<format_array ARRAYREF | LIST>

Given a reference to an array or a list of values, return a string formatted according to the rules of PostgreSQL's "ARRAY" column type.  Undef is returned if ARRAYREF points to an empty array or if LIST is not passed.

=item B<format_interval DURATION>

Given a L<DateTime::Duration> object, return a string formatted according to the rules of PostgreSQL's "INTERVAL" column type.  If DURATION is undefined, a L<DateTime::Duration> object, a valid interval keyword (according to L<validate_interval_keyword|Rose::DB/validate_interval_keyword>), or if it looks like a function call (matches C</^\w+\(.*\)$/>) and L<keyword_function_calls|Rose::DB/keyword_function_calls> is true, then it is returned unmodified.

=item B<parse_array STRING>

Parse STRING and return a reference to an array.  STRING should be formatted according to PostgreSQL's "ARRAY" data type.  Undef is returned if STRING is undefined.

=item B<parse_interval STRING>

Parse STRING and return a L<DateTime::Duration> object.  STRING should be formatted according to the PostgreSQL native "interval" (years, months, days, hours, minutes, seconds) data type.

If STRING is a L<DateTime::Duration> object, a valid interval keyword (according to L<validate_interval_keyword|Rose::DB/validate_interval_keyword>), or if it looks like a function call (matches C</^\w+\(.*\)$/>) and L<keyword_function_calls|Rose::DB/keyword_function_calls> is true, then it is returned unmodified.  Otherwise, undef is returned if STRING could not be parsed as a valid "interval" value.

=item B<validate_date_keyword STRING>

Returns true if STRING is a valid keyword for the PostgreSQL "date" data type.  Valid (case-insensitive) date keywords are:

    current_date
    epoch
    now
    now()
    today
    tomorrow
    yesterday

The keywords are case sensitive.  Any string that looks like a function call (matches C</^\w+\(.*\)$/>) is also considered a valid date keyword if L<keyword_function_calls|Rose::DB/keyword_function_calls> is true.

=item B<validate_datetime_keyword STRING>

Returns true if STRING is a valid keyword for the PostgreSQL "datetime" data type, false otherwise.  Valid (case-insensitive) datetime keywords are:

    -infinity
    allballs
    current_date
    current_time
    current_time()
    current_timestamp
    current_timestamp()
    epoch
    infinity
    localtime
    localtime()
    localtimestamp
    localtimestamp()
    now
    now()
    timeofday()
    today
    tomorrow
    yesterday

The keywords are case sensitive.  Any string that looks like a function call (matches C</^\w+\(.*\)$/>) is also considered a valid datetime keyword if L<keyword_function_calls|Rose::DB/keyword_function_calls> is true.

=item B<validate_time_keyword STRING>

Returns true if STRING is a valid keyword for the PostgreSQL "time" data type, false otherwise.  Valid (case-insensitive) timestamp keywords are:

    allballs
    current_time
    current_time()
    localtime
    localtime()
    now
    now()
    timeofday()

The keywords are case sensitive.  Any string that looks like a function call (matches C</^\w+\(.*\)$/>) is also considered a valid timestamp keyword if L<keyword_function_calls|Rose::DB/keyword_function_calls> is true.

=item B<validate_timestamp_keyword STRING>

Returns true if STRING is a valid keyword for the PostgreSQL "timestamp" data type, false otherwise.  Valid (case-insensitive) timestamp keywords are:

    -infinity
    allballs
    current_date
    current_time
    current_time()
    current_timestamp
    current_timestamp()
    epoch
    infinity
    localtime
    localtime()
    localtimestamp
    localtimestamp()
    now
    now()
    timeofday()
    today
    tomorrow
    yesterday

The keywords are case sensitive.  Any string that looks like a function call (matches C</^\w+\(.*\)$/>) is also considered a valid timestamp keyword if L<keyword_function_calls|Rose::DB/keyword_function_calls> is true.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
