package Rose::DB::Registry::Entry;

use strict;

use Clone::PP();

use Rose::Object;
our @ISA = qw(Rose::Object);

our $VERSION = '0.765';

our $Debug = 0;

#
# Object data
#

our %Attrs;

BEGIN
{
  our %Attrs =
  (
    # Generic
    catalog            => { type => 'scalar' },
    database           => { type => 'scalar' },
    dbi_driver         => { type => 'scalar' },
    description        => { type => 'scalar' },
    domain             => { type => 'scalar' },
    driver             => { type => 'scalar', make_method => 0 },
    dsn                => { type => 'scalar' },
    host               => { type => 'scalar' },
    password           => { type => 'scalar' },
    port               => { type => 'scalar' },
    schema             => { type => 'scalar' },
    server_time_zone   => { type => 'scalar' },
    type               => { type => 'scalar' },
    username           => { type => 'scalar' },

    connect_options    => { type => 'hash', method_spec => { interface => 'get_set_init' } },

    pre_disconnect_sql => { type => 'array' },
    post_connect_sql   => { type => 'array' },

    # Pg
    european_dates     => { type => 'boolean', method_spec => { default => 0 } },
    pg_enable_utf8     => { type => 'boolean' },
    options            => { type => 'scalar' },
    service            => { type => 'scalar' },
    sslmode            => { type => 'scalar' },

    # SQLite
    auto_create    => { type => 'boolean', method_spec => { default => 1 } },
    sqlite_unicode => { type => 'boolean' },

    # MySQL
    mysql_auto_reconnect     => { type => 'boolean' },
    mysql_client_found_rows  => { type => 'boolean' },
    mysql_compression        => { type => 'boolean' },
    mysql_connect_timeout    => { type => 'boolean' },
    mysql_embedded_groups    => { type => 'scalar' },
    mysql_embedded_options   => { type => 'scalar' },
    mysql_enable_utf8        => { type => 'boolean' },
    mysql_enable_utf8mb4     => { type => 'boolean' },
    mysql_local_infile       => { type => 'scalar' },
    mysql_multi_statements   => { type => 'boolean' },
    mysql_read_default_file  => { type => 'scalar' },
    mysql_read_default_group => { type => 'scalar' },
    mysql_socket             => { type => 'scalar' },
    mysql_ssl                => { type => 'boolean' },
    mysql_ssl_ca_file        => { type => 'scalar' },
    mysql_ssl_ca_path        => { type => 'scalar' },
    mysql_ssl_cipher         => { type => 'scalar' },
    mysql_ssl_client_cert    => { type => 'scalar' },
    mysql_ssl_client_key     => { type => 'scalar' },
    mysql_use_result         => { type => 'boolean' },
    mysql_bind_type_guessing => { type => 'boolean' },
  );
}

sub _attrs
{
  my(%args) = @_;

  my $type = $args{'type'};

  # Type filter first
  my @attrs = 
    $type ? (grep { $Attrs{$_}{'type'} eq $type } keys(%Attrs)) : keys(%Attrs);

  if($args{'with_defaults'})
  {
    @attrs = grep 
    {
      $Attrs{$_}{'method_spec'} && 
      defined $Attrs{$_}{'method_spec'}{'default'} 
    }
    @attrs;
  }
  elsif($args{'no_defaults'})
  {
    @attrs = grep 
    {
      !$Attrs{$_}{'method_spec'} ||
      !defined $Attrs{$_}{'method_spec'}{'default'} 
    }
    @attrs;
  }

  return wantarray ? @attrs : \@attrs;
}

sub _attr_method_specs
{  
  my $attrs = _attrs(@_);

  my @specs;

  foreach my $attr (@$attrs)
  {
    next if(exists $Attrs{$attr}{'make_method'} && !$Attrs{$attr}{'make_method'});

    if(my $spec = $Attrs{$attr}{'method_spec'})
    {
      push(@specs, $attr => $spec);
    }
    else
    {
      push(@specs, $attr);
    }
  }

  return wantarray ? @specs : \@specs;
}

use Rose::Object::MakeMethods::Generic
(
  'scalar' =>
  [
    _attr_method_specs(type => 'scalar'),
  ],

  'boolean' =>
  [
    _attr_method_specs(type => 'boolean'),
  ],

  'hash' =>
  [
    _attr_method_specs(type => 'hash'),
    'connect_option'  => { hash_key => 'connect_options' },
  ],

  'array' =>
  [
    _attr_method_specs(type => 'array'),
  ]
);

sub init_connect_options { {} }

sub autocommit   { shift->connect_option('AutoCommit', @_) }
sub print_error  { shift->connect_option('PrintError', @_) }
sub raise_error  { shift->connect_option('RaiseError', @_) }
sub handle_error { shift->connect_option('HandleError', @_) }

sub driver
{
  my($self) = shift;
  return $self->{'driver'}  unless(@_);
  $self->{'dbi_driver'} = shift;
  return $self->{'driver'} = lc $self->{'dbi_driver'};
}

sub dump
{
  my($self) = shift;

  my %dump;

  foreach my $attr (_attrs(type => 'scalar'), 
                    _attrs(type => 'boolean', no_defaults => 1))
  {
    my $value = $self->$attr();
    next  unless(defined $value);
    $dump{$attr} = $value;
  }

  foreach my $attr (_attrs(type => 'hash'), _attrs(type => 'array'))
  {
    my $value = $self->$attr();
    next  unless(defined $value);
    $dump{$attr} = Clone::PP::clone($value);
  }


  # These booleans have defaults, but we only want the ones 
  # where the values were explicitly set.  Ugly...
  foreach my $attr (_attrs(type => 'boolean', with_defaults => 1))
  {
    my $value = $self->{$attr};
    next  unless(defined $value);
    $dump{$attr} = Clone::PP::clone($value);
  }

  return \%dump;
}

sub clone { Clone::PP::clone($_[0]) }

1;

__END__

=head1 NAME

Rose::DB::Registry::Entry - Data source registry entry.

=head1 SYNOPSIS

  use Rose::DB::Registry::Entry;

  $entry = Rose::DB::Registry::Entry->new(
    domain   => 'production',
    type     => 'main',
    driver   => 'Pg',
    database => 'big_db',
    host     => 'dbserver.acme.com',
    username => 'dbadmin',
    password => 'prodsecret',
    server_time_zone => 'UTC');

  Rose::DB->register_db($entry);

  # ...or...

  Rose::DB->registry->add_entry($entry);

  ...

=head1 DESCRIPTION

C<Rose::DB::Registry::Entry> objects store information about a single L<Rose::DB> data source.  See the L<Rose::DB> documentation for more information on data sources, and the L<Rose::DB::Registry> documentation to learn how C<Rose::DB::Registry::Entry> objects are managed.

C<Rose::DB::Registry::Entry> inherits from, and follows the conventions of, L<Rose::Object>.  See the L<Rose::Object> documentation for more information.

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a C<Rose::DB::Registry::Entry> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=head2 GENERAL

=over 4

=item B<autocommit [VALUE]>

Get or set the value of the "AutoCommit" connect option.

=item B<catalog [CATALOG]>

Get or set the database catalog name.  This setting is only relevant to databases that support the concept of catalogs.

=item B<clone>

Returns a clone (i.e., deep copy) of the current object.

=item B<connect_option NAME [, VALUE]>

Get or set the connect option named NAME.  Returns the current value of the connect option.

=item B<connect_options [HASHREF | PAIRS]>

Get or set the options passed in a hash reference as the fourth argument to the call to C<DBI-E<gt>connect()>.  See the C<DBI> documentation for descriptions of the various options.

If a reference to a hash is passed, it replaces the connect options hash.  If a series of name/value pairs are passed, they are added to the connect options hash.

Returns a reference to the hash of options in scalar context, or a list of name/value pairs in list context.

=item B<database [NAME]>

Get or set the database name.

=item B<description [TEXT]>

A description of the data source.

=item B<domain [DOMAIN]>

Get or set the data source domain.  Note that changing the C<domain> after a registry entry has been added to the registry has no affect on where the entry appears in the registry.

=item B<driver [DRIVER]>

Get or set the driver name.  The DRIVER argument is converted to lowercase before being set.

=item B<dsn [DSN]>

Get or set the C<DBI> DSN (Data Source Name).  Note that an explicitly set DSN may render some other attributes inaccurate.  For example, the DSN may contain a host name that is different than the object's current C<host()> value.  I recommend not setting the DSN value explicitly unless you are also willing to manually synchronize (or ignore) the corresponding object attributes.

=item B<dump>

Returns a reference to a hash of the entry's attributes.  Only those attributes with defined values are included in the hash keys.  All values are deep copies.

=item B<handle_error [VALUE]>

Get or set the value of the "HandleError" connect option.

=item B<host [NAME]>

Get or set the database server host name.

=item B<password [PASS]>

Get or set the database password.

=item B<port [NUM]>

Get or set the database server port number.

=item B<pre_disconnect_sql [STATEMENTS]>

Get or set the SQL statements that will be run immediately before disconnecting from the database.  STATEMENTS should be a list or reference to an array of SQL statements.  Returns a reference to the array of SQL statements in scalar context, or a list of SQL statements in list context.

=item B<post_connect_sql [STATEMENTS]>

Get or set the SQL statements that will be run immediately after connecting to the database.  STATEMENTS should be a list or reference to an array of SQL statements.  Returns a reference to the array of SQL statements in scalar context, or a list of SQL statements in list context.

=item B<print_error [VALUE]>

Get or set the value of the "PrintError" connect option.

=item B<raise_error [VALUE]>

Get or set the value of the "RaiseError" connect option.

=item B<schema [SCHEMA]>

Get or set the database schema name.  This setting is only useful to databases that support the concept of schemas (e.g., PostgreSQL).

=item B<server_time_zone [TZ]>

Get or set the time zone used by the database server software.  TZ should be a time zone name that is understood by C<DateTime::TimeZone>.  See the C<DateTime::TimeZone> documentation for acceptable values of TZ.

=item B<type [TYPE]>

Get or set the  data source type.  Note that changing the C<type> after a registry entry has been added to the registry has no affect on where the entry appears in the registry.

=item B<username [NAME]>

Get or set the database username.

=back

=head2 DRIVER-SPECIFIC ATTRIBUTES

=head3 MySQL

These attributes should only be used with registry entries where the L<driver|/driver> is C<mysql>.

=over 4

=item B<mysql_auto_reconnect [BOOL]>

Get or set the L<mysql_auto_reconnect|DBD::mysql/mysql_auto_reconnect> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_auto_reconnect> documentation to learn more about this attribute.

=item B<mysql_client_found_rows [BOOL]>

Get or set the L<mysql_client_found_rows|DBD::mysql/mysql_client_found_rows> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_client_found_rows> documentation to learn more about this attribute.

=item B<mysql_compression [BOOL]>

Get or set the L<mysql_compression|DBD::mysql/mysql_compression> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_compression> documentation to learn more about this attribute.

=item B<mysql_connect_timeout [BOOL]>

Get or set the L<mysql_connect_timeout|DBD::mysql/mysql_connect_timeout> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_connect_timeout> documentation to learn more about this attribute.

=item B<mysql_embedded_groups [STRING]>

Get or set the L<mysql_embedded_groups|DBD::mysql/mysql_embedded_groups> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_embedded_groups> documentation to learn more about this attribute.

=item B<mysql_embedded_options [STRING]>

Get or set the L<mysql_embedded_options|DBD::mysql/mysql_embedded_options> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_embedded_options> documentation to learn more about this attribute.

=item B<mysql_enable_utf8 [BOOL]>

Get or set the L<mysql_enable_utf8|DBD::mysql/mysql_enable_utf8> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_enable_utf8> documentation to learn more about this attribute.

=item B<mysql_enable_utf8mb4 [BOOL]>

Get or set the L<mysql_enable_utf8mb4|DBD::mysql/mysql_enable_utf8mb4> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_enable_utf8mb4> documentation to learn more about this attribute.

=item B<mysql_local_infile [STRING]>

Get or set the L<mysql_local_infile|DBD::mysql/mysql_local_infile> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_local_infile> documentation to learn more about this attribute.

=item B<mysql_multi_statements [BOOL]>

Get or set the L<mysql_multi_statements|DBD::mysql/mysql_multi_statements> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_multi_statements> documentation to learn more about this attribute.

=item B<mysql_read_default_file [STRING]>

Get or set the L<mysql_read_default_file|DBD::mysql/mysql_read_default_file> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_read_default_file> documentation to learn more about this attribute.

=item B<mysql_read_default_group [STRING]>

Get or set the L<mysql_read_default_group|DBD::mysql/mysql_read_default_group> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_read_default_group> documentation to learn more about this attribute.

=item B<mysql_socket [STRING]>

Get or set the L<mysql_socket|DBD::mysql/mysql_socket> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_socket> documentation to learn more about this attribute.

=item B<mysql_ssl [BOOL]>

Get or set the L<mysql_ssl|DBD::mysql/mysql_ssl> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl> documentation to learn more about this attribute.

=item B<mysql_ssl_ca_file [STRING]>

Get or set the L<mysql_ssl_ca_file|DBD::mysql/mysql_ssl_ca_file> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl_ca_file> documentation to learn more about this attribute.

=item B<mysql_ssl_ca_path [STRING]>

Get or set the L<mysql_ssl_ca_path|DBD::mysql/mysql_ssl_ca_path> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl_ca_path> documentation to learn more about this attribute.

=item B<mysql_ssl_cipher [STRING]>

Get or set the L<mysql_ssl_cipher|DBD::mysql/mysql_ssl_cipher> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl_cipher> documentation to learn more about this attribute.

=item B<mysql_ssl_client_cert [STRING]>

Get or set the L<mysql_ssl_client_cert|DBD::mysql/mysql_ssl_client_cert> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl_client_cert> documentation to learn more about this attribute.

=item B<mysql_ssl_client_key [STRING]>

Get or set the L<mysql_ssl_client_key|DBD::mysql/mysql_ssl_client_key> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl_client_key> documentation to learn more about this attribute.

=item B<mysql_use_result [BOOL]>

Get or set the L<mysql_use_result|DBD::mysql/mysql_use_result> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_use_result> documentation to learn more about this attribute.

=back

=head3 PostgreSQL

These attributes should only be used with registry entries where the L<driver|/driver> is C<pg>.

=over 4

=item B<european_dates [BOOL]>

Get or set the boolean value that determines whether or not dates are assumed to be in european dd/mm/yyyy format.  The default is to assume US mm/dd/yyyy format (because this is the default for PostgreSQL).

This value will be passed to L<DateTime::Format::Pg> as the value of the C<european> parameter in the call to the constructor C<new()>.  This L<DateTime::Format::Pg> object is used by L<Rose::DB::Pg> to parse and format date-related column values in methods like L<parse_date|Rose::DB/parse_date>, L<format_date|Rose::DB/format_date>, etc.

=item B<pg_enable_utf8 [BOOL]>

Get or set the L<pg_enable_utf8|DBD::Pg/pg_enable_utf8> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::Pg> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::Pg|DBD::Pg/pg_enable_utf8> documentation to learn more about this attribute.

=item B<sslmode [MODE]>

Get or set the SSL mode of the connection.  Valid values for MODE are C<disable>, C<allow>, C<prefer>, and C<require>.  See the L<DBD::Pg|DBD::Pg/connect> documentation to learn more about this attribute.

=back

=head3 SQLite

These attributes should only be used with registry entries where the L<driver|/driver> is C<sqlite>.

=over 4

=item B<auto_create [BOOL]>

Get or set a boolean value indicating whether or not a new SQLite L<database|Rose::DB/database> should be created if it does not already exist.  Defaults to true.

If false, and if the specified L<database|Rose::DB/database> does not exist, then a fatal error will occur when an attempt is made to L<connect|Rose::DB/connect> to the database.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
