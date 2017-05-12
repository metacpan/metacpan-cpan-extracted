package Mojar::Mysql::Connector;
use DBI 1.4.3;
use Mojo::Base 'DBI';

# Register subclass structure
__PACKAGE__->init_rootclass;

our $VERSION = 2.161;

use Carp 'croak';
use File::Spec::Functions 'catfile';
use Mojar::ClassShare 'have';

sub import {
  my ($pkg, %param) = @_;
  my $caller = caller;
  # Helpers
  $param{-connector} //= 1 if exists $param{-dbh} and $param{-dbh};
  if (exists $param{-connector} and my $cname = delete $param{-connector}) {
    $cname = 'connector' if "$cname" eq '1';
    no strict 'refs';
    *{"${caller}::$cname"} = sub {
      my $self = shift;
      if (@_) {
        $self->{$cname} = (@_ > 1) ? Mojar::Mysql::Connector->new(@_) : shift;
        return $self;
      }
      return $self->{$cname} //= Mojar::Mysql::Connector->new;
    };
    if (exists $param{-dbh} and my $hname = delete $param{-dbh}) {
      $hname = 'dbh' if "$hname" eq '1';
      *{"${caller}::$hname"} = sub {
        my $self = shift;
        if (@_) {
          $self->{$hname} = (@_ > 1) ? $self->$cname->connect(@_) : shift;
          return $self;
        }
        return $self->{$hname}
          if defined $self->{$hname} and $self->{$hname}->ping;
        return $self->{$hname} = $self->$cname->connect;
      };
    }
  }
  # Global defaults
  if (%param and %{$pkg->Defaults}) {
    # Already have defaults => check unchanged
    # Not interested in defaults of Defaults => use hash not methods
    my $ps = join ':', map +($_ .':'. ($param{$_} // 'undef')),
        sort keys %param;
    my $ds = join ':', map +($_ .':'. ($pkg->Defaults->{$_} // 'undef')),
        sort keys %{$pkg->Defaults};
    die "Redefining class defaults for $pkg" unless $ps eq $ds;
  }
  @{$pkg->Defaults}{keys %param} = values %param if %param;
  # Debugging
  $pkg->trace($param{TraceLevel})
    if exists $param{TraceLevel} and defined $param{TraceLevel};
}

# Class attribute

# Use a singleton object for holding use-time class defaults
have Defaults => sub { bless {} => ref $_[0] || $_[0] };

# Attributes

has quiesce_timeout => 500;

my @DbdFields = qw(RaiseError PrintError PrintWarn AutoCommit TraceLevel
    mysql_auto_reconnect mysql_enable_utf8);

has RaiseError => 1;
has PrintError => 0;
has PrintWarn => 0;
has AutoCommit => 1;
has TraceLevel => 0;
has mysql_auto_reconnect => 0;
has mysql_enable_utf8 => 1;

my @ConFields = qw(label cnfdir cnf cnfgroup);

has 'label';
has cnfdir => '.';
has 'cnf';
has 'cnfgroup';

my @DbiFields = qw(driver host port schema user password);

has driver => 'mysql';
has 'host';  # eg 'localhost'
has 'port';  # eg 3306
has 'schema';  # eg 'test';
has 'user';
has 'password';

# Public methods

sub new {
  my ($proto, %param) = @_;
  # $proto may contain defaults to be cloned
  # %param may contain defaults for overriding
  my %defaults = ref $proto ? ( %{ ref($proto)->Defaults }, %$proto )
                            : %{$proto->Defaults};
  delete $defaults{$_} for grep { ref $proto and /^dbh\./ } keys %defaults;
  return Mojo::Base::new($proto, %defaults, %param);
}

sub connect {
  my ($proto, @args) = @_;
  my $class = ref $proto || $proto;
  @args = $proto->dsn(@args) unless @args and $args[0] =~ /^DBI:/i;
  my $dbh;
  eval { $dbh = $class->SUPER::connect(@args) }
  or do {
    my $e = $@;
    croak sprintf "Connection error\n%s\n%s", $proto->dsn_to_dump(@args), $e;
  };
  return $dbh;
}

sub connection {
  my ($self, $tag) = @_; $tag //= 'connection';
  return $self->{"dbh.$tag"} if ($self->{"dbh.$tag"} //= $self->connect)->ping;
  return $self->{"dbh.$tag"} = $self->connect;
}

sub dsn {
  my ($proto, %param) = @_;
  my $param = $proto->new(%param);

  my $cnf_txt = '';
  if (my $cnf = $param->cnf) {
    # MySQL .cnf file
    $cnf .= '.cnf' unless $cnf =~ /\.cnf$/;
    $cnf = catfile $param->cnfdir, $cnf if ! -r $cnf and defined $param->cnfdir;
    croak "Failed to find/read .cnf file ($cnf)" unless -f $cnf and -r $cnf;

    $cnf_txt = ';mysql_read_default_file='. $cnf;
    $cnf_txt .= ';mysql_read_default_group='. $param->cnfgroup
      if defined $param->cnfgroup;
  }

  # DBD params
  # Only set private_config if it would have useful values
  my %custom;
  defined($param->$_) and $custom{$_} = $param->$_ for qw(label cnf cnfgroup);
  my $dbd_param = %custom ? { private_config => {%custom} } : {};
  $dbd_param->{$_} = $param->{$_} for grep /^mysql_/, keys %$param;
  @$dbd_param{@DbdFields} = map $param->$_, @DbdFields;

  return (
    'DBI:'. $param->driver .q{:}
          . ($param->schema // $param->{db} // '')
          . (defined $param->host ? q{;host=}. $param->host : '')
          . (defined $param->port ? q{;port=}. $param->port : '')
          . $cnf_txt,
    $param->user,
    $param->password,
    $dbd_param
  );
}

sub dsn_to_dump {
  my ($proto, @args) = @_;
  @args = $proto->dsn unless @args;
  # Occlude password
  if ($args[2] and $_ = length $args[2] and $_ > 1) {
    --$_;
    my $blanks = '*' x $_;
    $args[2] = substr($args[2], 0, 1). $blanks;
  }
  require Mojar::Util;
  return Mojar::Util::dumper(@args);
}

# ============
package Mojar::Mysql::Connector::db;
@Mojar::Mysql::Connector::db::ISA = 'DBI::db';

use Carp 'croak';
use Mojar::Util 'lc_keys';
use Scalar::Util 'looks_like_number';

our $_as_hash = { Slice => {} };
sub as_hash { $_as_hash }

# Public methods

sub dsn { shift->get_info(2) }
# 2 : SQL_DATA_SOURCE_NAME

sub mysqld_version { shift->get_info(18) }
# 18 : SQL_DBMS_VER

sub identifier_quote { shift->get_info(29) }
# 29 : SQL_IDENTIFIER_QUOTE_CHAR

sub identifier_separator { shift->get_info(41) }
# 41 : SQL_QUALIFIER_NAME_SEPARATOR

sub async_mode { shift->get_info(10021) }
# 10021 : SQL_ASYNC_MODE

sub async_max_statements { shift->get_info(10022) }
# 10022 : SQL_MAX_ASYNC_CONCURRENT_STATEMENTS

sub thread_id { shift->{mysql_thread_id} // 0 }

sub current_schema {
  my ($self) = @_;
  my ($schema) = $self->selectrow_array(
q{SELECT DATABASE()}
  );
  return $schema;
}

sub session_var { shift->_var('SESSION', @_) }

sub global_var {
  my $self = shift;
  return $self->_var(GLOBAL => @_)
    if @_ >= 2 or @_ == 1 and $_[0] ne 'have_innodb';

  my $variables = $self->_var('GLOBAL');

  # Workaround for MySQL bug #59393 wrt ignore-builtin-innodb
  $variables->{have_innodb} = 'NO'
    if exists $variables->{ignore_builtin_innodb}
        and ($variables->{ignore_builtin_innodb} // '') eq 'ON';

  return $variables->{have_innodb} if @_ == 1 and $_[0] eq 'have_innodb';
  return $variables;
}

sub disable_quotes { shift->session_var(sql_quote_show_create => 0) }

sub enable_quotes {
  my ($self, $value) = @_;
  $value //= 1;
  $self->session_var(sql_quote_show_create => $value)
}

sub disable_fk_checks { shift->session_var(foreign_key_checks => 0) }

sub enable_fk_checks {
  my ($self, $value) = @_;
  $value //= 1;
  $self->session_var(foreign_key_checks => $value)
}

sub schemata {
  my ($self, @args) = @_;
  # args[0] : schema pattern
  my $schemata;
  eval {
    my $sql = q{SHOW DATABASES};
    $sql .= sprintf q{ LIKE '%s'}, $args[0] if defined $args[0];
    $schemata = $self->selectcol_arrayref($sql, $args[1]) or die;
    @$schemata = grep !/^(?:\#|lost\+found)/, @$schemata;
    1;
  }
  or do {
    my $e = $@ // '';
    croak "Failed to list schemata\n$e";
  };
  return $schemata;
}

sub tables_and_views {
  my ($self, @args) = @_;
  # args[0] : schema
  # args[1] : table pattern
  # args[2] : type
  # args[3] : attr
  $args[2] //= 'TABLE,VIEW';
  my $tables;
  eval {
    my $sth = $self->table_info('', @args);
    @$tables = map $_->[2], @{$sth->fetchall_arrayref};
    1;
  }
  or do {
    my $e = $@ // '';
    croak "Failed to list tables\n$e";
  };
  return $tables;
}

sub real_tables {
  my ($self, @args) = @_;
  # args[0] : schema
  # args[1] : table pattern
  # args[2] : attr
  return $self->tables_and_views(@args[0,1], 'TABLE', $args[2]);
}

sub views {
  my ($self, @args) = @_;
  # args[0] : schema
  # args[1] : table pattern
  # args[2] : attr
  return $self->tables_and_views(@args[0,1], 'VIEW', $args[2]);
}

sub selectall_arrayref_hashrefs {
  my ($self, $sql, $opts, @args) = @_;
  if (defined $opts) {
    $opts->{Slice} = {};
  }
  else {
    $opts = $_as_hash;
  }
  return $self->selectall_arrayref($sql, $opts, @args);
}

sub selectall_lookup {
  my $self = shift;
  my $rs = $self->selectall_arrayref(@_);  # ($sql, $opts, @args)
  return undef if @$rs >= 1 and @{$$rs[0]} != 2;  # wrong qty cols
  return {map @$_, @$rs};  # flatten
}

sub threads {
  my $p = shift->selectall_arrayref_hashrefs(q{SHOW FULL PROCESSLIST});
  @$p = map lc_keys($_), @$p;
  return $p;
}

sub engines {
  my ($self) = @_;

  my $engines = {};
  my $e = $self->selectall_arrayref(q{SHOW ENGINES});
  for (@$e) {
    if ($_->[1] eq 'DEFAULT') {
      $engines->{default} = lc $_->[0];
      $engines->{lc $_->[0]} = 1;
    }
    else {
      $engines->{lc $_->[0]} = $_->[1] eq 'YES' ? 1 : 0;
    }
  }
  return $engines;
}

sub statistics {
  my ($self) = @_;

  # Arbitrary query to ensure results
  ($_) = $self->selectrow_array(q{SELECT VERSION()});

  my $s = $self->selectall_arrayref(q{SHOW /*!50000 GLOBAL */ STATUS});
  return lc_keys { map @$_, @$s };
}

sub engine {
  my ($self, $schema, $table) = @_;
  my $engine;
  if ($self->mysqld_version =~ /^(\d+)\./ and $1 >= 5) {
    ($engine) = $self->selectrow_array(
q{SELECT ENGINE
FROM information_schema.TABLES
WHERE
  TABLE_SCHEMA = ?
  AND TABLE_NAME = ?},
      undef,
      $schema,
      $table
    );
  }
  return $engine;
}

sub indices {
  my ($self, $schema, $table) = @_;
  croak 'Missing required schema name' unless defined $schema and length $schema;
  croak 'Missing required table name'  unless defined $table and length $table;
  my $i = $self->selectall_arrayref(sprintf(
q{SHOW INDEXES FROM %s IN %s}, $table, $schema
    ), $_as_hash
  );
  # $i is arrayref of hashrefs
  lc_keys $_ for @$i;
  return $i;
}

sub table_status {
  my ($self, $schema, $table_pattern) = @_;
  croak 'Missing required schema name' unless defined $schema and length $schema;
  my $sql = sprintf
q{SHOW TABLE STATUS FROM %s}, $schema;
  $sql .= sprintf(q{ LIKE '%s'}, $table_pattern) if defined $table_pattern;
  my $s = $self->selectall_arrayref($sql, $_as_hash);
  # $s is arrayref of hashrefs
  lc_keys $_ for @$s;
  return $s;
}

sub engine_status {
  my ($self, $engine) = @_;
  $engine //= 'InnoDB';
  Carp::croak "Bad engine ($engine)" unless $engine =~ /^\w+$/;

  my ($major, $minor) = ($self->mysqld_version =~ /^(\d+)\.(\d+)\./);
  my $i = $major > 5 ? 2 : $major == 5 && $minor >= 1 ? 2 : 0;
  my $raw = ($self->selectrow_array(
      qq{SHOW /*!50500 ENGINE */ $engine STATUS}))[$i]
      // die "Failed to get engine ($engine) status\n";
  $raw =~ s/\t/ /g;

  my ($title, $buffer, $status) = ('', '', {});
  while ($raw =~ /^(.*)$/mg) {
    my $line = $1;
    if ($line =~ /^-+$/ and length $buffer) {
      # Finish previous record
      $status->{$title} = $buffer;
      $title = $buffer = '';
    }
    elsif ($line =~ /^-+$/) {
      # Start new record
    }
    elsif (not length $title) {
      chomp $line;
      $title = lc $line;
      $title =~ s/\s+/_/g;
      $title =~ s/\W//g;
    }
    elsif ($line =~ /^=+$/) {
      next;
    }
    else {
      $buffer .= $line . $/;
    }
    # Ignore final record
  }
  return $status;
}

sub table_space {
  my ($self, $schema, $table) = @_;
  my $space;
  eval {
    ($space) = $self->selectrow_array(
q{SELECT CONCAT(TRUNCATE(DATA_FREE / 1024, 0), ' kB')
FROM information_schema.TABLES
WHERE
  TABLE_SCHEMA = ?
  AND TABLE_NAME = ?},
      undef,
      $schema, $table
    );
    $space ne '0 kB';
  }
  or eval {
    my $comment = $self->table_status($schema, $table)->[0]{comment};
    $space = $1 if $comment =~ /InnoDB free: (\d+ \w+)/;
  };
  return $space;
}

sub date_from_today {
  my ($self, $days, $format) = @_;
  $days //= 0;
  $format //= '%Y-%m-%d';
  my ($date) = $self->selectrow_array(sprintf
q{SELECT DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL %s DAY), '%s')},
    $days, $format
  );
  return $date;
}

sub quiesce {
  my ($self) = @_;

  # Record existing state
  my $pct = $self->global_var('innodb_max_dirty_pages_pct')
    // die "Failed to get dirty_pages info\n";
  my $repl = $self->selectrow_hashref('SHOW SLAVE STATUS') // {};
  Carp::croak "Cannot quiesce while replicating"
    if ($repl->{Slave_SQL_Running} // '') =~ /^Yes/i;

  # Prepare callback to un-quiesce db
  my $cb = sub {
    eval { $self->do('UNLOCK TABLES') };
    $self->global_var(innodb_max_dirty_pages_pct => shift // $pct);
  };

  # Quiesce
  eval {
    $self->global_var(innodb_max_dirty_pages_pct => 0);
    $self->do('FLUSH TABLES WITH READ LOCK');
    my ($quiesced, $count) = (0, 0);
    while (++$count < $self->quiesce_timeout) {
      my $state = $self->engine_status('InnoDB')->{buffer_pool_and_memory};
      if ($state =~ /^Modified db pages\s+(\d+)$/m) {
        ++$quiesced, last if $1 == 0;
      }
      else {
        die "Failed to check dirty pages\n";
      }
      sleep 1;
    }
    $quiesced;
  } or do {
    my $e = $@ // '';
    eval { $cb->(); };
    die "Failed to quiesce database: $e\n";
  };
  return $cb;
}

# Private method

sub _var {
  my ($self, $scope) = (shift, shift);
  $scope //= 'SESSION';

  unless (@_) {
    # All vars
    my $v = $self->selectall_arrayref(qq{SHOW $scope VARIABLES});
    return { map @$_, @$v };
  }

  my $var = shift;
  unless (@_) {
    # Getter
    my ($value) = $self->selectrow_array(sprintf
q{SELECT @@%s.%s}, $scope, $var);
    return $value;
  }

  # Setter
  my $value = shift;
  my ($old, $new);
  eval {
    ($old) = $self->selectrow_array(sprintf
q{SELECT @@%s.%s}, $scope, $var);
    $value = "'$value'" unless looks_like_number $value;
    $self->do(qq{SET $scope $var = $value});
    ($new) = $self->selectrow_array(sprintf
q{SELECT @@%s.%s}, $scope, $var);
    1;
  }
  or do {
    my $e = $@ // '';
    croak "Failed to set var ($var)\n$e";
  };
  return wantarray ? ($old, $new) : $self;
}

#TODO: clean up this ancient code
#sub insert_hash {
#  my ($self, $schema, $table, $field_map) = @_;
#  my @fields = keys %$field_map;
#  my @values = values %$field_map;
#  $self->do(sprintf(
#q{INSERT INTO %s.%s (%s) VALUES (%s)},
#      $schema,
#      $table,
#      join(q{,}, @fields),
#      join(q{,}, '?' x @fields)),
#    undef,
#    @values
#  );
#}

#TODO: clean up this ancient code
#sub search_hash {
#  my ($self, $schema, $table, $field_map, @columns) = @_;
#  my @fields = keys %$field_map;
#  my @values = values %$field_map;
#  my $wanted = scalar(@columns) ? join q{, }, @columns : q{*};
#  my $where = '';
#  $where = q{WHERE }. join q{ AND }, map '$_ = ?', @fields if @fields;
#  $self->selectall_arrayref(sprintf(
#q{SELECT %s FROM %s.%s %s},
#    $wanted, $schema, $table, $where),
#    undef,
#    @values
#  );
#}

# ============
package Mojar::Mysql::Connector::st;
@Mojar::Mysql::Connector::st::ISA = 'DBI::st';

1;
__END__

=head1 NAME

Mojar::Mysql::Connector - MySQL connector (dbh producer) with added convenience

=head1 SYNOPSIS

In an application making only one type of connection.

  use Mojar::Mysql::Connector (
    cnfdir => '/var/local/auth/myapp',
    cnf => 'rw_localhost',
    schema => 'Users'
  );
  ...
  my $dbh = Mojar::Mysql::Connector->connect;

In an application making multiple types of connection.

  use Mojar::Mysql::Connector (
    cnfdir => '/var/local/auth/myapp'
  );

  my $read_connector = Mojar::Mysql::Connector->new(
    cnf => 'ro_remotehost',
    schema => 'Orders'
  );
  my $write_connector = Mojar::Mysql::Connector->new(
    cnf => 'rw_localhost',
    schema => 'Reports'
  );
  ...
  my $read_dbh = $read_connector->connect(mysql_auto_reconnect => 1);
  my $write_dbh = $write_connector->connect;

Employing a helper.

  use Mojar::Mysql::Connector (
    cnfdir => '/var/local/auth/myapp',
    cnf => 'rw_localhost',
    schema => 'Users',
    -dbh => 1
  );
  sub do_da_db_doodah {
    my $self = shift;
    my $dbh = $self->dbh;
    ...
  }

From the commandline.

  perl -MMojar::Mysql::Connector=cnf,ro_localhost,schema,Users,-dbh,1
    -E'say join qq{\n}, @{main->dbh->real_tables}'

=head1 DESCRIPTION

MySQL-specific extension (subclass) to L<DBI> in order to improve convenience,
security, and error handling.  Supports easy use of credential (cnf) files, akin
to

  mysql --defaults-file=credentials.cnf

It aims to reduce boilerplate, verbosity, mistakes, and parameter overload, but
above all it tries to make it quick and easy to Do The Right Thing.

As the name implies, the class provides connector objects -- containers for
storing and updating your connection parameters.  When you call C<connect>, the
connector returns a handle created using its retained parameters plus any
call-time parameters passed.  You don't however have to use connectors; for
simple usage it can be easier to use C<connect> directly from the class.

You can use a DSN tuple if you want to, but it's more readable and less
error-prone to specify your parameters either as a hash or by setting individual
attributes.  Each call to C<connect> will then construct the DSN for you.

You can optionally import a helper method, called C<dbh> (or whatever name you
choose) so that you can focus even less on the connector/connection and more on
your code.  The helper will cache your database handle and create a new one
automatically if the old one is destroyed or goes stale.

The fourth layer of convenience is provided by the added database handle
methods.  Changing session variables (C<session_var>) is easy, listing only
genuine tables (C<real_tables>) is easy, and there's
L<more|/"DATABASE HANDLE METHODS">.

=head1 CLASS METHODS

=head2 C<new>

  Mojar::Mysql::Connector->new(label => 'cache', cnf => 'myuser_localhost');

Constructor for a connector, based on class defaults.  Takes a (possibly empty)
list of parameters.  Returns a connector (Mojar::Mysql::Connector object) the
defaults of which are those of the class overlaid with those passed to the
constructor.

=head2 C<connect>

 $dbh1 = Mojar::Mysql::Connector->connect(
   'DBI:mysql:test;host=localhost', 'admin', 's3cr3t', {}
 );
 $dbh2 = Mojar::Mysql::Connector->connect(
   schema => 'test',
   host => 'localhost',
   user => 'admin',
   password => 's3cr3t'
 );
 $dbh3 = Mojar::Mysql::Connector->connect;

Constructor for a connection (db handle).  If the first element passed has
prefix C<DBI:> then it is a DSN string (the traditional route) and so is passed
straight to C<DBI::connect> (L<DBI/"DBI Class Methods">).  Otherwise a DSN is
first constructed.  (The DSN tuple does not persist and is constructed fresh on
each call to C<connect>.)

In the examples above, $dbh1 and $dbh2 are not equivalent because the second
connector would also incorporate module defaults and use-time parameters, in
addition to the passed parameters.  So, for instance, mysql_enable_utf8 might be
included in the second connector.

=head2 C<dsn>

  @dbi_args = Mojar::Mysql::Connector->dsn(
    cnf => 'myuser_localhost', schema => 'test'
  );

A convenience method used internally by connect.  Takes a (possibly empty)
parameter hash.  Returns a four-element array to pass to C<DBI::connect>,
constructed from the default values of the constructing class overlaid with any
additional parameters passed.  The main reason for using this method is when you
want to use L<DBI> (or another DSN-consumer) directly but want to avoid the
inconvenience of assembling sensible parameters yourself.

  use DBI;
  use Mojar::Mysql::Connector (
    cnfdir => '/srv/myapp/cfg',
    cnf => 'myuser_localhost'
  );
  my $dbh = DBI->connect(
    Mojar::Mysql::Connector->dsn(schema => 'foo', AutoCommit => 0)
  );

=head2 C<dsn_to_dump>

  warn(Mojar::Mysql::Connector->dsn_to_dump(@dsn));

A convenience method used internally to chop up the four-element array
(particularly the fourth element, the hash ref) into something more readable,
for error reporting and debugging.  Tries to occlude any password within.

=head2 C<Defaults>

  say Mojar::Util::dumper(Mojar::Mysql::Connector->Defaults);

Provides access to the class defaults in order to help debugging.

=head1 OBJECT METHODS

=head2 C<new>

  $connector->new(label => 'transaction', AutoCommit => 0);

Constructor for a connector based on an existing connector.  Takes a
(possibly empty) parameter hash.  Returns a connector (Mojar::Mysql::Connector
object) the defaults of which are those of the given connector overlaid with
any arguments passed in.

=head2 C<connect>

  $dbh = $connector->connect(
    'DBI:mysql:test;host=localhost', 'admin', 's3cr3t', {});
  $dbh = $connector->connect(AutoCommit => 0);
  $dbh = $connector->connect;

Constructor for a connection (db handle).  If the first element passed has
prefix C<DBI:> then it is a DSN string (the traditional route) and so is passed
straight to C<DBI::connect> (L<DBI/"DBI Class Methods">) without consideration
of the connector's existing parameters.  Otherwise a DSN is first constructed.
(The DSN tuple does not persist and is constructed fresh on each call to
C<connect>.)

=head2 Attributes

All connector parameters are implemented as attributes with exactly the same
spelling.  So for example you can

  $connector->RaiseError(undef);  # disable RaiseError
  $connector->mysql_enable_utf8(0);  # disable mysql_enable_utf8

The attributes, with their coded defaults, are

  RaiseError => 1
  PrintError => 0
  PrintWarn => 0
  AutoCommit => 1
  TraceLevel => 0
  mysql_auto_reconnect => 0
  mysql_enable_utf8 => 1

  label
  cnfdir => '.'
  cnf
  cnfgroup

  driver => 'mysql'
  host
  port
  schema
  user
  password

In addition, any L<DBD::mysql> attributes (beginning "mysql_") are passed
through to the driver.

  $dbh = $connector->connect(mysql_skip_secure_auth => 1);

=head1 DATABASE HANDLE METHODS

=head2 C<selectall_arrayref_hashrefs>

  $_->{Command} ne 'Sleep' and say $_->{User}
    for $dbh->selectall_arrayref_hashrefs(q{SHOW FULL PROCESSLIST});

  printf '%s can select: %s', $_->{User}, $_->{Select_priv}
    for $dbh->selectall_arrayref_hashrefs(q{SELECT * FROM mysql.user});

Returns an arrayref of hashrefs, each hashref being a record of the resultset.
The keys of the hashref are the column/field names of the record.  This is
simply minimal sugar on the selectall_arrayref method provided by DBI; it saves
the little boilerplate of "Slice => {}".  If you want to pass bound values then
you need undef as the second argument.

  printf '%s can select: %s', $_->{User}, $_->{Select_priv}
    for $dbh->selectall_arrayref_hashrefs(
      q{SELECT * FROM mysql.user WHERE User != ?}, undef, 'root'
    );

=head2 C<mysqld_version>

  if ($dbh->mysqld_version =~ /^5.0/) {...}

Returns the version of the db server connected to; the version part of

  mysqld --version

=head2 C<thread_id>

  $tmp_table_name = q{ConcurrencySafe_}. $dbh->thread_id;

Utility method to get the connection's thread identifier (unique on that db
server at that point in time).

=head2 C<current_schema>

  $schema_name = $dbh->current_schema;

The same string as given by

  SELECT DATABASE();

=head2 C<session_var>

  my ($old) = $dbh->session_var(sql_mode => 'ANSI_QUOTES');
  ...
  $dbh->session_var(sql_mode => $old);

Getter/setter for session variables.  To get a value, simply pass the variable's
name.

  $value = $dbh->session_var('date_format');

In list context returns the old value and the new value; in scalar context
returns the handle to facilitate chaining.

  $dbh->session_var(var1 => ...)
      ->session_var(var2 => ...);

=head2 C<disable_quotes>

  my @ddl = $dbh->disable_quotes->selectrow_array(q{SHOW CREATE ...});

Disable optional quotes around identifiers.  Currently only affects output of
C<SHOW CREATE TABLE>.  If you have unsafe identifiers (eg spaces or keywords)
then those will still be quoted.  Lasts the lifetime of the connection.

=head2 C<enable_quotes>

The inverse of C<disable_quotes>.

=head2 C<disable_fk_checks>

  $dbh->disable_fk_checks->do(q{DROP TABLE ...});

Disable foreign key checks.  Lasts the lifetime of the connection.

=head2 C<enable_fk_checks>

The inverse of C<disable_fk_checks>.

=head2 C<schemata>

  for my $schema (@{$dbh->schemata}) {...}

Returns an arrayref of schema names, similar to

  SHOW DATABASES

but does not get fooled by C<lost+found>.

=head2 C<tables_and_views>

  foreach my $table ($dbh->tables_and_views) {...}

Returns a hashref of table and view names, similar to

  SHOW TABLES

See also L<DBI/tables>.

=head2 C<real_tables>

  for my $table (@{$dbh->real_tables}) {...}

Returns a arrayref of real table names, similar to

  SHOW TABLES

but excluding views.

=head2 C<views>

  for my $view (@{$dbh->views}) {...}

Returns a arrayref of view names, similar to

  SHOW TABLES

but excluding real tables.

=head1 CHARACTER ENCODINGS

To read/store characters encoded as non-ASCII, non-UTF8, you must disable
handling of UTF-8.

  $connector = Mojar::Mysql::Connector->new(mysql_enable_utf8 => 0);

This is essential, for example, when fetching high-latin (eg non-ASCII 8859-1)
characters.

=head1 DEBUGGING

You can enable DBI trace logging at use-time:

  use Mojar::Mysql::Connector (TraceLevel => '3|CON');

and since you have access to all of L<DBI>, you can set tracing using the method

  $dbh->trace('3|CON');
  ...
  $dbh->trace(0);

or by using the attribute

  {
    local $dbh->{TraceLevel} = '3|CON';
    ...
  }

To set tracing for all handles, use the class method instead.  See
L<DBI/TRACING>.

=head1 SUPPORT

=head2 Homepage

L<http://niczero.github.com/mojar-mysql>

=head2 Wiki

L<http://github.com/niczero/mojar/wiki>

=head1 RATIONALE

This class was first used in production in 2002.  Before then, connecting to
databases was ugly and annoying.  Setting C<RaiseError> upon every connect was
clumsy and irritating.  In development teams it was tricky checking that all
code was using sensible parameters and awkward ensuring use of risky parameters
(eg C<disable_fk_checks>) was kept local.  As use of this class spread, it had
to be useful in persistent high performance applications as well as many small
scripts and the occasional commandline.  More recently I discovered the Joy of
L<Mojolicious> and employed L<Mojo::Base> to remove unwanted complexity and
eliminate a long-standing bug.  The ensuing fun motivated an extensive rewrite,
fixing broken documentation, improved the tests (thank you travis), and we have,
finally, its public release.  As noted below there are now quite a few smart
alternatives out there but I'm still surprised how little support there is for
keeping passwords out of your codebase and helping you manage multiple
connections.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002--2017, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojo::mysql>, L<Coro::Mysql>, L<AnyEvent::DBI>, L<DBIx::Custom>,
L<DBIx::Connector>, L<DBI>.

=cut

# engine_status and quiesce have been tested on 4.0.27, 4.1.11, 5.0.87, 5.1.73,
# 5.6.23, 5.7.16
