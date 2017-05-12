#   Our beloved Emacs will give us -*- perl -*- mode :-)
#
#   $Id: dbd.pm.in,v 1.6 1999/10/21 20:05:43 joe Exp $
#
#   Copyright (c) 1994,1995,1996,1997 Alligator Descartes, Tim Bunce
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

package DBD::mysql;
use strict;
use vars qw(@ISA $VERSION $err $errstr $drh);

use DBI ();
use DynaLoader();
use Carp ();
@ISA = qw(DynaLoader);

$VERSION = '2.0419';

bootstrap DBD::mysql $VERSION;


$err = 0;	# holds error code   for DBI::err
$errstr = "";	# holds error string for DBI::errstr
$drh = undef;	# holds driver handle once initialised

sub driver{
    return $drh if $drh;
    my($class, $attr) = @_;

    $class .= "::dr";

    # not a 'my' since we use it above to prevent multiple drivers
    $drh = DBI::_new_drh($class, { 'Name' => 'mysql',
				   'Version' => $VERSION,
				   'Err'    => \$DBD::mysql::err,
				   'Errstr' => \$DBD::mysql::errstr,
				   'Attribution' => 'DBD::mysql by Jochen Wiedmann'
				 });

    $drh;
}

sub _OdbcParse($$$) {
    my($class, $dsn, $hash, $args) = @_;
    my($var, $val);
    if (!defined($dsn)) {
	return;
    }
    while (length($dsn)) {
	if ($dsn =~ /([^:;]*)[:;](.*)/) {
	    $val = $1;
	    $dsn = $2;
	} else {
	    $val = $dsn;
	    $dsn = '';
	}
	if ($val =~ /([^=]*)=(.*)/) {
	    $var = $1;
	    $val = $2;
	    if ($var eq 'hostname'  ||  $var eq 'host') {
		$hash->{'host'} = $val;
	    } elsif ($var eq 'db'  ||  $var eq 'dbname') {
		$hash->{'database'} = $val;
	    } else {
		$hash->{$var} = $val;
	    }
	} else {
	    foreach $var (@$args) {
		if (!defined($hash->{$var})) {
		    $hash->{$var} = $val;
		    last;
		}
	    }
	}
    }
}

sub _OdbcParseHost ($$) {
    my($class, $dsn) = @_;
    my($hash) = {};
    $class->_OdbcParse($dsn, $hash, ['host', 'port']);
    ($hash->{'host'}, $hash->{'port'});
}

sub AUTOLOAD {
    my ($meth) = $DBD::mysql::AUTOLOAD;
    my ($smeth) = $meth;
    $smeth =~ s/(.*)\:\://;

    my $val = constant($smeth, @_ ? $_[0] : 0);
    if ($! == 0) { eval "sub $meth { $val }"; return $val; }

    Carp::croak "$meth: Not defined";
}

1;


package DBD::mysql::dr; # ====== DRIVER ======
use strict;

sub connect {
    my($drh, $dsn, $username, $password, $attrhash) = @_;
    my($port);
    my($cWarn);

    # Avoid warnings for undefined values
    $username ||= '';
    $password ||= '';

    # create a 'blank' dbh
    my($this, $privateAttrHash);
    $privateAttrHash = {
	'Name' => $dsn,
	'user' => $username,
	'password' => $password
    };

    DBD::mysql->_OdbcParse($dsn, $privateAttrHash,
				    ['database', 'host', 'port']);

    if (!defined($this = DBI::_new_dbh($drh, {'Name' => $dsn},
				       $privateAttrHash))) {
	return undef;
    }

    # Call msqlConnect func in mSQL.xs file
    # and populate internal handle data.
    DBD::mysql::db::_login($this, $dsn, $username, $password)
	  or $this = undef;
    $this;
}

sub data_sources {
    my($self) = shift;
    my(@dsn) = $self->func('', '_ListDBs');
    my($i);
    for ($i = 0;  $i < @dsn;  $i++) {
	$dsn[$i] = "DBI:mysql:$dsn[$i]";
    }
    @dsn;
}

sub admin {
    my($drh) = shift;
    my($command) = shift;
    my($dbname) = ($command eq 'createdb'  ||  $command eq 'dropdb') ?
	shift : '';
    my($host, $port) = DBD::mysql->_OdbcParseHost(shift(@_) || '');
    my($user) = shift || '';
    my($password) = shift || '';

    $drh->func(undef, $command,
	       $dbname || '',
	       $host || '',
	       $port || '',
	       $user, $password, '_admin_internal');
}

package DBD::mysql::db; # ====== DATABASE ======
use strict;

%DBD::mysql::db::db2ANSI = ("INT"   =>  "INTEGER",
			   "CHAR"  =>  "CHAR",
			   "REAL"  =>  "REAL",
			   "IDENT" =>  "DECIMAL"
                          );

### ANSI datatype mapping to mSQL datatypes
%DBD::mysql::db::ANSI2db = ("CHAR"          => "CHAR",
			   "VARCHAR"       => "CHAR",
			   "LONGVARCHAR"   => "CHAR",
			   "NUMERIC"       => "INTEGER",
			   "DECIMAL"       => "INTEGER",
			   "BIT"           => "INTEGER",
			   "TINYINT"       => "INTEGER",
			   "SMALLINT"      => "INTEGER",
			   "INTEGER"       => "INTEGER",
			   "BIGINT"        => "INTEGER",
			   "REAL"          => "REAL",
			   "FLOAT"         => "REAL",
			   "DOUBLE"        => "REAL",
			   "BINARY"        => "CHAR",
			   "VARBINARY"     => "CHAR",
			   "LONGVARBINARY" => "CHAR",
			   "DATE"          => "CHAR",
			   "TIME"          => "CHAR",
			   "TIMESTAMP"     => "CHAR"
			  );

sub prepare {
    my($dbh, $statement, $attribs)= @_;

    # create a 'blank' dbh
    my $sth = DBI::_new_sth($dbh, {'Statement' => $statement});

    # Populate internal handle data.
    if (!DBD::mysql::st::_prepare($sth, $statement, $attribs)) {
	$sth = undef;
    }

    $sth;
}

sub db2ANSI {
    my $self = shift;
    my $type = shift;
    return $DBD::mysql::db::db2ANSI{"$type"};
}

sub ANSI2db {
    my $self = shift;
    my $type = shift;
    return $DBD::mysql::db::ANSI2db{"$type"};
}

sub admin {
    my($dbh) = shift;
    my($command) = shift;
    my($dbname) = ($command eq 'createdb'  ||  $command eq 'dropdb') ?
	shift : '';
    $dbh->{'Driver'}->func($dbh, $command, $dbname, '', '', '',
			   '_admin_internal');
}

sub _SelectDB ($$) {
    die "_SelectDB is removed from this module; use DBI->connect instead.";
}

{
    my $names = ['TABLE_CAT', 'TABLE_SCHEM', 'TABLE_NAME',
		 'TABLE_TYPE', 'REMARKS'];

    sub table_info ($) {
	my $dbh = shift;
	my @tables = map { [ undef, undef, $_, 'TABLE', undef ]
			 } $dbh->func('_ListTables');
	my $dbh2;
	if (!($dbh2 = $dbh->{'~dbd_driver~_sponge_dbh'})) {
	    $dbh2 = $dbh->{'~dbd_driver~_sponge_dbh'} =
		DBI->connect("DBI:Sponge:");
	    if (!$dbh2) {
	        DBI::set_err($dbh, 1, $DBI::errstr);
		return undef;
	    }
	}
	my $sth = $dbh2->prepare("LISTTABLES", { 'rows' => \@tables,
						 'NAME' => $names });
	if (!$sth) {
	    DBI::set_err($sth, $dbh2->err(), $dbh2->errstr());
	}
	$sth;
    }
}

package DBD::mysql::st; # ====== STATEMENT ======
use strict;

1;


__END__

=head1 NAME

DBD::mSQL / DBD::mysql - mSQL and mysql drivers for the Perl5 Database
Interface (DBI)

=head1 SYNOPSIS

    use DBI;

    $driver = "mSQL"; # or "mSQL1";
    $dsn = "DBI:$driver:database=$database;host=$hostname";

    $dbh = DBI->connect($dsn, undef, undef);

        or

    $driver = "mysql";
    $dsn = "DBI:$driver:database=$database;host=$hostname;port=$port";

    $dbh = DBI->connect($dsn, $user, $password);


    $drh = DBI->install_driver("mysql");
    @databases = $drh->func($host, $port, '_ListDBs');
    @tables = $dbh->func( '_ListTables' );

    $sth = $dbh->prepare("SELECT * FROM foo WHERE bla");
       or
    $sth = $dbh->prepare("LISTFIELDS $table");
       or
    $sth = $dbh->prepare("LISTINDEX $table $index");
    $sth->execute;
    $numRows = $sth->rows;
    $numFields = $sth->{'NUM_OF_FIELDS'};
    $sth->finish;

    $rc = $drh->func('createdb', $database, $host, $user, $password, 'admin');
    $rc = $drh->func('dropdb', $database, $host, $user, $password, 'admin');
    $rc = $drh->func('shutdown', $host, $user, $password, 'admin');
    $rc = $drh->func('reload', $host, $user, $password, 'admin');

    $rc = $dbh->func('createdb', $database, 'admin');
    $rc = $dbh->func('dropdb', $database, 'admin');
    $rc = $dbh->func('shutdown', 'admin');
    $rc = $dbh->func('reload', 'admin');


=head1 EXAMPLE

  #!/usr/bin/perl

  use strict;
  use DBI();

  # Connect to the database.
  my $dbh = DBI->connect("DBI:mysql:database=test;host=localhost",
                         "joe", "joe's password",
                         {'RaiseError' => 1});

  # Drop table 'foo'. This may fail, if 'foo' doesn't exist.
  # Thus we put an eval around it.
  eval { $dbh->do("DROP TABLE foo") };
  print "Dropping foo failed: $@\n" if $@;

  # Create a new table 'foo'. This must not fail, thus we don't
  # catch errors.
  $dbh->do("CREATE TABLE foo (id INTEGER, name VARCHAR(20))");

  # INSERT some data into 'foo'. We are using $dbh->quote() for
  # quoting the name.
  $dbh->do("INSERT INTO foo VALUES (1, " . $dbh->quote("Tim") . ")");

  # Same thing, but using placeholders
  $dbh->do("INSERT INTO foo VALUES (?, ?)", undef, 2, "Jochen");

  # Now retrieve data from the table.
  my $sth = $dbh->prepare("SELECT * FROM foo");
  $sth->execute();
  while (my $ref = $sth->fetchrow_hashref()) {
    print "Found a row: id = $ref->{'id'}, name = $ref->{'name'}\n";
  }
  $sth->finish();

  # Disconnect from the database.
  $dbh->disconnect();


=head1 DESCRIPTION

B<DBD::mysql> and B<DBD::mSQL> are the Perl5 Database Interface drivers
for the mysql, mSQL 1.I<x> and mSQL 2.I<x> databases. The drivers are part
of the I<Msql-Mysql-modules> package.

In other words: DBD::mSQL and DBD::mysql are an interface between the Perl
programming language and the mSQL or mysql programming API that come with
the mSQL any mysql relational database management systems. Most functions
provided by the respective programming API's are supported. Some
rarely used functions are missing, mainly because noone ever requested
them. :-)

In what follows we first discuss the use of DBD::mysql and DBD::mSQL,
because this is what you will need the most. For installation, see the
sections on L<INSTALLATION>, L<WIN32 INSTALLATION>, L<KNOWN PROBLEMS>
and L<KNOWN BUGS> below. See L<EXAMPLE> for a simple example above.

From perl you activate the interface with the statement

    use DBI;

After that you can connect to multiple mSQL or MySQL database servers
and send multiple queries to any of them via a simple object oriented
interface. Two types of objects are available: database handles and
statement handles. Perl returns a database handle to the connect
method like so:

  $dbh = DBI->connect("DBI:mSQL:database=$db;host=$host",
		      undef, undef, {RaiseError => 1});

or

  $dbh = DBI->connect("DBI:mysql:database=$db;host=$host",
		      $user, $password, {RaiseError => 1});

Once you have connected to a database, you can can execute SQL
statements with:

  my $query = sprintf("INSERT INTO foo VALUES (%d, %s)",
		      $number, $dbh->quote("name"));
  $dbh->do($query);

See L<DBI(3)> for details on the quote and do methods. An alternative
approach is

  $dbh->do("INSERT INTO foo VALUES (?, ?)", undef,
	   $number, $name);

in which case the quote method is executed automatically. See also
the bind_param method in L<DBI(3)>. See L<DATABASE HANDLES> below
for more details on database handles.

If you want to retrieve results, you need to create a so-called
statement handle with:

  $sth = $dbh->prepare("SELECT * FROM $table");
  $sth->execute();

This statement handle can be used for multiple things. First of all
you can retreive a row of data:

  my $row = $sth->fetchow_hashref();

If your table has columns ID and NAME, then $row will be hash ref with
keys ID and NAME. See L<STATEMENT HANDLES> below for more details on
statement handles.

But now for a more formal approach:


=head2 Class Methods

=over 4

=item B<connect>

    use DBI;

    $driver = "mSQL";  #  or "mSQL1"
    $dsn = "DBI:$driver:$database";
    $dsn = "DBI:$driver:database=$database;host=$hostname";

    $dbh = DBI->connect($dsn, undef, undef);

        or

    $dsn = "DBI:mysql:$database";
    $dsn = "DBI:mysql:database=$database;host=$hostname";
    $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";

    $dbh = DBI->connect($dsn, $user, $password);

A C<database> must always be specified.

=over 8

=item host

=item port

The hostname, if not specified or specified as '', will default to an
mysql or mSQL daemon running on the local machine on the default port
for the UNIX socket.

Should the mysql or mSQL daemon be running on a non-standard port number,
you may explicitly state the port number to connect to in the C<hostname>
argument, by concatenating the I<hostname> and I<port number> together
separated by a colon ( C<:> ) character or by using the  C<port> argument.
This doesn't work for mSQL 2: You have to create an alternative config
file and load it using the msql_configfile attribute, see below.


=item mysql_client_found_rows

Enables (TRUE value) or disables (FALSE value) the flag CLIENT_FOUND_ROWS
while connecting to the MySQL server. This has a somewhat funny effect:
Without mysql_client_found_rows, if you perform a query like

  UPDATE $table SET id = 1 WHERE id = 1

then the MySQL engine will always return 0, because no rows have changed.
With mysql_client_found_rows however, it will return the number of rows
that have an id 1, as some people are expecting. (At least for compatibility
to other engines.)

By default this flag is disabled. However, you can enable it by default,
when installing the Msql-Mysql-modules with

  perl Makefile.PL --config --mysql-use-client-found-rows
  make
  make install

=item mysql_compression

As of MySQL 3.22.3, a new feature is supported: If your DSN contains
the option "mysql_compression=1", then the communication between client
and server will be compressed.

=item mysql_connect_timeout

If your DSN contains the option "mysql_connect_timeout=##", the connect
request to the server will timeout if it has not been successful after
the given number of seconds.

=item mysql_read_default_file

=item mysql_read_default_group

These options can be used to read a config file like /etc/my.cnf or
~/.my.cnf. By default MySQL's C client library doesn't use any config
files unlike the client programs (mysql, mysqladmin, ...) that do, but
outside of the C client library. Thus you need to explicitly request
reading a config file, as in

    $dsn = "DBI:mysql:test;mysql_read_default_file=/home/joe/my.cnf";
    $dbh = DBI->connect($dsn, $user, $password)

The option mysql_read_default_group can be used to specify the default
group in the config file: Usually this is the I<client> group, but
see the following example:

    [perl]
    host=perlhost

    [client]
    host=localhost

If you read this config file, then you'll be typically connected to
I<localhost>. However, by using

    $dsn = "DBI:mysql:test;mysql_read_default_group=perl;"
        . "mysql_read_default_file=/home/joe/my.cnf";
    $dbh = DBI->connect($dsn, $user, $password);

you'll be connected to I<perlhost>. Note that if you specify a
default group and do not specify a file, then the default config
files will all be read.  See the (missing :-) documentation of
the C function mysql_options() for details.

=item mysql_socket

As of MySQL 3.21.15, it is possible to choose the Unix socket that is
used for connecting to the server. This is done, for example, with

    mysql_socket=/dev/mysql

Usually there's no need for this option, unless you are using another
location for the socket than that built into the client.


=back

=back


=head2 Private MetaData Methods

=over 4

=item B<ListDBs>

    my $drh = DBI->install_driver("mysql");
    @dbs = $drh->func("$hostname:$port", '_ListDBs');
    @dbs = $drh->func($hostname, $port, '_ListDBs');
    @dbs = $dbh->func('_ListDBs');

Returns a list of all databases managed by the mysql daemon or
mSQL daemon running on C<$hostname>, port C<$port>. This method
is rarely needed for databases running on C<localhost>: You should
use the portable method

    @dbs = DBI->data_sources("mysql");

        or

    @dbs = DBI->data_sources("mSQL");

whenever possible. It is a design problem of this method, that there's
no way of supplying a host name or port number to C<data_sources>, that's
the only reason why we still support C<ListDBs>. :-(


=item B<ListTables>

*WARNING*: This method is obsolete due to DBI's $dbh->table_info().

    @tables = $dbh->func('_ListTables');

Once connected to the desired database on the desired mysql or mSQL
mSQL daemon with the C<DBI->connect()> method, we may extract a list
of the tables that have been created within that database.

C<ListTables> returns an array containing the names of all the tables
present within the selected database. If no tables have been created,
an empty list is returned.

    @tables = $dbh->func( '_ListTables' );
    foreach $table ( @tables ) {
        print "Table: $table\n";
      }



=head2 Server Administration

=over 4

=item admin

    $rc = $drh->func("createdb", $dbname, [host, user, password,], 'admin');
    $rc = $drh->func("dropdb", $dbname, [host, user, password,], 'admin');
    $rc = $drh->func("shutdown", [host, user, password,], 'admin');
    $rc = $drh->func("reload", [host, user, password,], 'admin');

      or

    $rc = $dbh->func("createdb", $dbname, 'admin');
    $rc = $dbh->func("dropdb", $dbname, 'admin');
    $rc = $dbh->func("shutdown", 'admin');
    $rc = $dbh->func("reload", 'admin');

For server administration you need a server connection. For obtaining
this connection you have two options: Either use a driver handle (drh)
and supply the appropriate arguments (host, defaults localhost, user,
defaults to '' and password, defaults to ''). A driver handle can be
obtained with

    $drh = DBI->install_driver('mysql');

Otherwise reuse the existing connection of a database handle (dbh).

There's only one function available for administrative purposes, comparable
to the m(y)sqladmin programs. The command being execute depends on the
first argument:

=over 8

=item createdb

Creates the database $dbname. Equivalent to "m(y)sqladmin create $dbname".

=item dropdb

Drops the database $dbname. Equivalent to "m(y)sqladmin drop $dbname".

It should be noted that database deletion is
I<not prompted for> in any way.  Nor is it undo-able from DBI.

    Once you issue the dropDB() method, the database will be gone!

These method should be used at your own risk.

=item shutdown

Silently shuts down the database engine. (Without prompting!)
Equivalent to "m(y)sqladmin shutdown".

=item reload

Reloads the servers configuration files and/or tables. This can be particularly
important if you modify access privileges or create new users.

=back


=back


=head1 DATABASE HANDLES

The DBD::mysql driver supports the following attributes of database
handles (read only):

    $infoString = $dbh->{'info'};
    $threadId = $dbh->{'thread_id'};
    $insertId = $dbh->{'mysql_insertid'}

These correspond to mysql_info(), mysql_thread_id() and mysql_insertid(),
respectively.


=head1 STATEMENT HANDLES

The statement handles of DBD::mysql and DBD::mSQL support a number
of attributes. You access these by using, for example,

  my $numFields = $sth->{'NUM_OF_FIELDS'};

Note, that most attributes are valid only after a successfull I<execute>.
An C<undef> value will returned in that case. The most important exception
is the C<mysql_use_result> attribute: This forces the driver to use
mysql_use_result rather than mysql_store_result. The former is faster
and less memory consuming, but tends to block other processes. (That's why
mysql_store_result is the default.)

To set the C<mysql_use_result> attribute, use either of the following:

  my $sth = $dbh->prepare("QUERY", { "mysql_use_result" => 1});

or

  my $sth = $dbh->prepare("QUERY");
  $sth->{"mysql_use_result"} = 1;

Column dependent attributes, for example I<NAME>, the column names,
are returned as a reference to an array. The array indices are
corresponding to the indices of the arrays returned by I<fetchrow>
and similar methods. For example the following code will print a
header of table names together with all rows:

  my $sth = $dbh->prepare("SELECT * FROM $table");
  if (!$sth) {
      die "Error:" . $dbh->errstr . "\n";
  }
  if (!$sth->execute) {
      die "Error:" . $sth->errstr . "\n";
  }
  my $names = $sth->{'NAME'};
  my $numFields = $sth->{'NUM_OF_FIELDS'};
  for (my $i = 0;  $i < $numFields;  $i++) {
      printf("%s%s", $$names[$i], $i ? "," : "");
  }
  print "\n";
  while (my $ref = $sth->fetchrow_arrayref) {
      for (my $i = 0;  $i < $numFields;  $i++) {
	  printf("%s%s", $$ref[$i], $i ? "," : "");
      }
      print "\n";
  }

For portable applications you should restrict yourself to attributes with
capitalized or mixed case names. Lower case attribute names are private
to DBD::mSQL and DBD::mysql. The attribute list includes:

=over 4

=item ChopBlanks

this attribute determines whether a I<fetchrow> will chop preceding
and trailing blanks off the column values. Chopping blanks does not
have impact on the I<max_length> attribute.

=item mysql_insertid

MySQL has the ability to choose unique key values automatically. If this
happened, the new ID will be stored in this attribute. This attribute
is not valid for DBD::mSQL. An alternative way for accessing this attribute
is via $dbh->{'mysql_insertid'}. (Note we are using the $dbh in this case!)

=item mysql_is_blob

Reference to an array of boolean values; TRUE indicates, that the
respective column is a blob. This attribute is valid for MySQL only.

=item mysql_is_key

Reference to an array of boolean values; TRUE indicates, that the
respective column is a key. This is valid for MySQL only.

=item mysql_is_num

Reference to an array of boolean values; TRUE indicates, that the
respective column contains numeric values.

=item mysql_is_pri_key

Reference to an array of boolean values; TRUE indicates, that the
respective column is a primary key. This is only valid for MySQL
and mSQL 1.0.x: mSQL 2.x uses indices.

=item mysql_length

=item mysql_max_length

A reference to an array of maximum column sizes. The I<max_length> is
the maximum physically present in the result table, I<length> gives
the theoretically possible maximum. I<max_length> is valid for MySQL
only.

=item NAME

A reference to an array of column names.

=item NULLABLE

A reference to an array of boolean values; TRUE indicates that this column
may contain NULL's.

=item NUM_OF_FIELDS

Number of fields returned by a I<SELECT> or I<LISTFIELDS> statement.
You may use this for checking whether a statement returned a result:
A zero value indicates a non-SELECT statement like I<INSERT>,
I<DELETE> or I<UPDATE>.

=item mysql_table

A reference to an array of table names, useful in a I<JOIN> result.

=item TYPE

A reference to an array of column types. The engine's native column
types are mapped to portable types like DBI::SQL_INTEGER() or
DBI::SQL_VARCHAR(), as good as possible. Not all native types have
a meaningfull equivalent, for example DBD::mSQL::IDX_TYPE() or
DBD::mysql::FIELD_TYPE_INTERVAL are mapped to DBI::SQL_VARCHAR().
If you need the native column types, use I<mysql_type> or I<msql_type>,
respectively. See below.

=item mysql_type

A reference to an array of MySQL's native column types, for example
DBD::mysql::FIELD_TYPE_SHORT() or DBD::mysql::FIELD_TYPE_STRING().
Use the I<TYPE> attribute, if you want portable types like
DBI::SQL_SMALLINT() or DBI::SQL_VARCHAR().

=item mysql_type_name

Similar to mysql, but type names and not numbers are returned.
Whenever possible, the ANSI SQL name is preferred.

=back


=head1 TRANSACTION SUPPORT

Beginning with Msql-Mysql-modules 1.2216, transactions are supported
by DBD::mysql. The transaction support works as follows:

=over

=item *

By default AutoCommit mode is on, following the DBI specifications.

=item *

If you execute

    $dbh-E<gt>{'AutoCommit'} = 0;

or

    $dbh-E<gt>{'AutoCommit'} = 1;

then the driver will set the MySQL server variable autocommit to 0 or
1, respectively. Switching from 0 to 1 will also issue a COMMIT,
following the DBI specifications.

=item *

The methods

    $dbh-E<gt>rollback();
    $dbh-E<gt>commit();

will issue the commands COMMIT and ROLLBACK, respectively. A
ROLLBACK will also be issued if AutoCommit mode is off and the
database handles DESTROY method is called. Again, this is following
the DBI specifications.

=back

Given the above, you should note the following:

=over

=item *

You should never change the server variable autocommit manually,
unless you are ignoring DBI's transaction support.

=item *

Switching AutoCommit mode from on to off or vice versa may fail.
You should always check for errors, when changing AutoCommit mode.
The suggested way of doing so is using the DBI flag RaiseError.
If you don't like RaiseError, you have to use code like the
following:

  $dbh->{'AutoCommit'} = 0;
  if ($dbh->{'AutoCommit'}) {
    # An error occurred!
  }

=item *

If you detect an error while changing the AutoCommit mode, you
should no longer use the database handle. In other words, you
should disconnect and reconnect again, because the transaction
mode is unpredictable. Alternatively you may verify the transaction
mode by checking the value of the server variable autocommit.
However, such behaviour isn't portable.

=back


=head1 SQL EXTENSIONS

Certain metadata functions of mSQL and mysql that are available on the
C API level, haven't been implemented here. Instead they are implemented
as "SQL extensions" because they return in fact nothing else but the
equivalent of a statement handle. These are:

=over 4

=item LISTFIELDS $table

Returns a statement handle that describes the columns of $table.
Ses the docs of msqlListFields or mysql_list_fields (C API) for
details.

=item LISTINDEX $table $index

mSQL only; returns a statement handle that describes the index $index
of table $table. See the docs of msqlListIndex for details.

=back



=head1 COMPATIBILITY ALERT

The statement attribute I<TYPE> has changed its meaning, as of
Msql-Mysql-modules 1.19_19. Formerly it used to be the an array
of native engine's column types, but it is now an array of
portable SQL column types. The old attribute is still available
as I<mysql_type> or I<msql_type>, respectively.

The Msql-Mysql-modules are a moving target, due to a number of reasons:

=over 8

=item -

Of course they have to conform the DBI guidelines and developments.

=item -

They have to keep track with the latest MySQL developments.

=item -

And, surprisingly, they have to be as close to ODBC as possible: This is
due to the current direction of DBI.

=item -

And, last not least, as any tool they have a little bit of own life.

=back

This means that a lot of things had to and have to be changed. As I am not
interested in maintaining a lot of compatibility kludges, which only
increase the drivers code without being really usefull, I did and will
remove some features, methods or attributes.

To ensure a smooth upgrade, the following policy will be applied:

=over 8

=item Obsolete features

The first step is to declare something obsolete. This means, that no code
is changed, but the feature appears in the list of obsolete features. See
L<Obsolete Features> below.

=item Deprecated features

If the feature has been obsolete for quite some time, typically in the
next major stable release, warnings will be inserted in the code. You
can suppress these warnings by setting

    $DBD::mysql = 1;

In the docs the feature will be moved from the list of obsolete features
to the list of deprecated features. See L<Deprecated Features> below.

=item Removing features

Finally features will be removed silently in the next major stable
release. The feature will be shown in the list of historic features.
See L<Historic Features> below.

=back

Example: The statement handle attribute

    $sth->{'LENGTH'}

was declared obsolete in Msql-Mysql-modules 1.18xy. It is considered
deprecated in Msql-Mysql-modules 1.20xy (current as of this writing)
and will finally be removed in Msql-Mysql-modules 1.22xy.

=back


=head2 Obsolete Features

=over 8

=item _ListTables

This method is obsoleted by DBI's new method

    $dbh->tables()

See also $dbh->table_info(). Portable applications will prefer

    @tables = map { $_ =~ s/.*\.//; $_ } $dbh->tables()

because, depending on the engine, the string "user.table" will be
returned, user being the table owner. The method will be deprecated
in 1.23_xy and 1.24xy and removed in 1.25_xy and 1.26xy.

=back


=head2 Deprecated Features

=over 8

=item _InsertID

The method

    $dbh->func('_InsertID');

can be replaced with

    $dbh->{'mysql_insertid'};

The method is deprecated as of 1.21_xy, thus it will be removed in
1.23_xy and 1.24xy.

=item Statement handle attributes:

=over 12

=item affected_rows

=item IS_PRI_KEY

=item is_pri_key

=item IS_NOT_NULL

=item is_not_null

=item IS_KEY

=item is_key

=item IS_BLOB

=item is_blob

=item IS_NUM

=item is_num

=item LENGTH

=item length

=item MAXLENGTH

=item maxlength

=item NUMROWS

=item numrows

=item NUMFIELDS

=item numfields

=item RESULT

=item result

=item TABLE

=item table

=item format_max_size

=item format_default_size

=item format_type_name

=back

All of the above statement handle attributes are not conforming to DBI's
naming conventions, thus they have been declared deprecated in 1.20xy.
However, I forgot to insert warnings in the driver. These warnings have
been inserted in 1.21_07, thus the attributes will be removed in 1.23_xy
and 1.24xy.

In most of the above cases the driver name has been added and the resulting
name was lowercased. For example, you use

    $sth->{'mysql_is_num'};

now. IS_NOT_NULL can be replaced with NULLABLE (note you need to invert
the logical value!), LENGTH, format_max_size and format_default_size will
be dropped in favour of PRECISION, affected_rows and NUMROWS are identical
with

    $sth->rows();

and NUMFIELDS is the same as NUM_OF_FIELDS. Finally format_right_justify
is the same as mysql_type_name.

=back



=head2 Historic Features

=over 8

=item _CreateDB

=item _DropDB

The methods

    $dbh->func($db, '_CreateDB');
    $dbh->func($db, '_DropDB');

have been used for creating or dropping databases. They have been removed
in 1.21_07 in favour of

    $drh->func("createdb", $dbname, $host, "admin")
    $drh->func("dropdb", $dbname, $host, "admin")

=item _ListFields

The method

    $sth = $dbh->func($table, '_ListFields');

has been used to list a tables columns names, types and other attributes.
This method has been removed in 1.21_07 in favour of

    $sth = $dbh->prepare("LISTFIELDS $table");

=item _ListSelectedFields

The method

    $sth->func('_ListSelectedFields');

use to return a hash ref of attributes like 'IS_NUM', 'IS_KEY' and so
on. These attributes are now accessible via

    $sth->{'mysql_is_num'};
    $sth->{'mysql_is_key'};

and so on. Thus the method has been removed in 1.21_07.

=item _NumRows

The method

    $sth->func('_NumRows');

used to be equivalent to

    $sth->rows();

and has been removed in 1.21_07.

=back


=head1 MULTITHREADING

The multithreading capabilities of the Msql-Mysql-modules depend completely
on the underlying C libraries: The modules are working with handle data
only, no global variables are accessed or (to the best of my knowledge)
thread unsafe functions are called. Thus DBD::mSQL and DBD::mysql are
completely thread safe, if the C libraries thread safe and you don't
share handles among threads.

The obvious questions is: Are the C libraries thread safe? In the case of
mSQL the answer is definitely "no". The C library has a concept of one
single active connection at a time and that is not what threads like.

In the case of MySQL the answer is "mostly" and, in theory, you should
be able to get a "yes", if the C library is compiled for being thread
safe (By default it isn't.) by passing the option -with-thread-safe-client
to configure. See the section on I<How to make a threadsafe client> in
the manual.


=head1 INSTALLATION

Windows users may skip this section and pass over to L<WIN32
INSTALLATION> below. Others, go on reading.

First of all, you do not need an installed MySQL server for installing
DBD::mSQL and/or DBD::mysql. However, you need at least the client
libraries and possibly the header files, if you are compiling DBD::mysql
or DBD::mSQL from source. In the case of MySQL you can create a
client-only version by using the configure option --without-server.
If you are using precompiled binaries, then it may be possible to
use just selected RPM's like MySQL-client and MySQL-devel or something
similar, depending on the distribution.

First you need to install the DBI module. For using I<dbimon>, a
simple DBI shell it is recommended to install Data::ShowTable another
Perl module.

I recommend trying automatic installation via the CPAN module. Try

  perl -MCPAN -e shell

If you are using the CPAN module for the first time, it will prompt
you a lot of questions. If you finally receive the CPAN prompt, enter

  install Bundle::DBD::mSQL

or

  install Bundle::DBD::mysql

If this fails (which may be the case for a number of reasons, for
example because you are behind a firewall or don't have network
access), you need to do a manual installation. First of all you
need to fetch the archives from any CPAN mirror, for example

  ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module

The following archives are required (version numbers may have
changed, I choose those which are current as of this writing):

  DBI/DBI-1.13.tar.gz
  Data/Data-ShowTable-3.3.tar.gz
  DBD/Msql-Mysql-modules-1.2217.tar.gz

Then enter the following commands:

  gzip -cd DBI-1.13.tar.gz | tar xf -
  cd DBI-1.13
  perl Makefile.PL
  make
  make test
  make install

  cd ..
  gzip -cd Data-ShowTable-3.3.tar.gz | tar xf -
  cd Data-ShowTable-3.3
  perl Makefile.PL
  make
  make install  # Don't try make test, the test suite is broken

  cd ..
  gzip -cd Msql-Mysql-modules-1.2217.tar.gz | tar xf -
  cd Msql-Mysql-modules-1.2217
  perl Makefile.PL
  make
  make test
  make install

During "perl Makefile.PL" you will be prompted some questions. In
particular you have to choose the installed drivers (MySQL, mSQL2
and/or mSQL1). The MySQL driver will be called DBD::mysql, a single
mSQL driver will be called DBD::mSQL. If you want to support both
mSQL1 and mSQL2, they former will be DBD::mSQL1.

Other questions are the directories with header files and libraries.
For example, of your file F<mysql.h> is in F</usr/include/mysql/mysql.h>,
then enter the header directory F</usr>, likewise for
F</usr/lib/mysql/libmysqlclient.a> or F</usr/lib/libmysqlclient.so>.
For mSQL go looking for F<msql.h> (typically in F</usr/include/msql.h>
and F<libmsql.a> (probably in F</usr/lib/libmsql.a>).

See the L<KNOWN PROBLEMS> section below if you encounter any problems
within "make" or "make test".


=head1 WIN32 INSTALLATION

I have never attempted to install DBD::mSQL under Win32, so this is only
for MySQL. If anyone succeeds, please let me know what you did.

If you are using ActivePerl, you may use ppm to install DBD-mysql.
For Perl 5.6, upgrade to Build 623 or later, then it is sufficient
to run

  ppm install DBI
  ppm install DBD::mysql


The same applied to Perl 5.005.

Otherwise you definitely *need* a C compiler. And it *must* be the same
compiler that was being used for compiling Perl itself. If you don't
have a C compiler, the file README.win32 from the Perl source
distribution tells you where to obtain freely distributable C compilers
like egcs or gcc. The Perl sources are available on any CPAN mirror in
the src directory, for example

    ftp://ftp.funet.fi/pub/languages/perl/CPAN/src/latest.tar.gz

I recommend using the win32clients package for installing DBD::mysql
under Win32, available for download on www.tcx.se. The following steps
have been required for me:

=over 8

=item -

The current Perl versions (5.6, as of this writing) do have a problem
with detecting the C libraries. I recommend to apply the following
patch:

  *** c:\Perl\lib\ExtUtils\Liblist.pm.orig Sat Apr 15 20:03:40 2000
  --- c:\Perl\lib\ExtUtils\Liblist.pm      Sat Apr 15 20:03:45 2000
  ***************
  *** 230,235 ****
  --- 230,239 ----
      # add "$Config{installarchlib}/CORE" to default search path
      push @libpath, "$Config{installarchlib}/CORE";

  +     if ($VC  and  exists($ENV{LIB})  and  defined($ENV{LIB})) {
  +       push(@libpath, split(/;/, $ENV{LIB}));
  +     }
  +
      foreach (Text::ParseWords::quotewords('\s+', 0, $potential_libs)){

        $thislib = $_;
                                                                       
=item -

Extract sources into F<C:\>. This will create a directory F<C:\mysql>
with subdirectories include and lib.

IMPORTANT: Make sure this subdirectory is not shared by other TCX
files! In particular do *not* store the MySQL server in the same
directory. If the server is already installed in F<C:\mysql>,
choose a location like F<C:\tmp>, extract the win32clients there.
Note that you can remove this directory entirely once you have
installed the Msql-Mysql-modules.

=item -

Extract the Msql-Mysql-modules sources into another directory, for
example F<C:\src\siteperl>

=item -

Open a DOS shell and change directory to F<C:\src\siteperl>.

=item -

The next step is only required if you repeat building the modules: Make
sure that you have a clean build tree by running

  nmake realclean

If you don't have VC++, replace nmake with your flavour of make. If
error messages are reported in this step, you may safely ignore them.

=item -

Run

  perl Makefile.PL

which will prompt you for some settings. The really important ones are:

  Which DBMS do you want to use?

enter a 1 here (MySQL only), and

  Where is your mysql installed? Please tell me the directory that
  contains the subdir include.

where you have to enter the win32clients directory, for example
F<C:\mysql> or F<C:\tmp\mysql>.

=item -

Continued in the usual way:

  nmake
  nmake install

=back

See the first section of L<KNOWN PROBLEMS> below.

If you want to create a PPM package for the ActiveState Perl version, then
modify the above steps as follows: Run

  perl Makefile.PL NAME=DBD-mysql BINARY_LOCATION=DBD-mysql.tar.gz
  nmake ppd
  nmake

Once that is done, use tar and gzip (for example those from the CygWin32
distribution) to create an archive:

  mkdir x86
  tar cf x86/DBD-mysql.tar blib
  gzip x86/DBD-mysql.tar

Put the files x86/DBD-mysql.tar.gz and DBD-mysql.ppd onto some WWW server
and install them by typing

  install http://your.server.name/your/directory/DBD-mysql.ppd

in the PPM program.


=head1 KNOWN PROBLEMS

=over 8

=item 1.)

If the MySQL binaries are compiled with gcc or egcs (as the precompiled
binaries are), but your Perl is using another compiler, it is likely that
you receive an error message like the following when running "make test":

  t/00base............install_driver(mysql) failed: Can't load
  '../blib/arch/auto/DBD/mysql/mysql.so' for module DBD::mysql:
  ../blib/arch/auto/DBD/mysql/mysql.so: undefined symbol: _umoddi3
  at /usr/local/perl-5.005/lib/5.005/i586-linux-thread/DynaLoader.pm
  line 168.

This means, that your linker doesn't include libgcc.a. You have the
following options:

=over 12

=item a)

Either recompile Perl or Mysql, it doesn't matter which. The important
thing is that you use the same compiler for both. This is definitely
the recommended solution in the long term.

=item b)

A simple workaround is to include libgcc.a manually. Do a "make clean"
and "make" and in the output wait for a line like

  LD_RUN_PATH="/usr/lib/mysql:/lib" egcs -o
  ../blib/arch/auto/DBD/mysql/mysql.so  -shared -L/usr/local/lib
  dbdimp.o mysql.o -L/usr/lib/mysql -L/usr/lib/mysql -lmysqlclient
  -lm

Repeat the same line in the shell by adding

  -L/usr/lib/gcc-lib/i386-redhat-linux/gcc-2.7.2.3 -lgcc

where the directory is the location of libgcc.a. The best choice
for locating this file is executing

  gcc --print-libgcc-file

or

  gcc -v

=back


=item 2.)

There are known problems with shared versions of libmysqlclient, at
least on some Linux boxes. If you receive an error message similar to

  install_driver(mysql) failed: Can't load
  '/usr/lib/perl5/site_perl/i586-linux/auto/DBD/mysql/mysql.so'
  for module DBD::mysql: File not found at
  /usr/lib/perl5/i586-linux/5.00404/DynaLoader.pm line 166

then this error message can be misleading: It's not mysql.so that fails
being loaded, but libmysqlclient.so!

As a workaround, recompile the Msql-Mysql-modules with

  perl Makefile.PL --static --config
  make
  make test
  make install

This option forces linkage against the static libmysqlclient.a.


=item 3.)

By default mSQL2 is installed to allow local access only. This can break
the test scripts akmisc.t, msql1.t and msql2.t. You might notice a message
like

  t/akmisc............Can't connect to MSQL server on localhost at
  t/akmisc.t line 131
  Cannot connect: Can't connect to MSQL server on localhost
  It looks as if your server (on localhost) is not up and running.
  This test requires a running server.
  Please make sure your server is running and retry.
  dubious
  Test returned status 10 (wstat 2560, 0xa00)

If this is the case, try to change the value of "Remote_Access" in
your F<msql.conf> file to "True". If the value was set intentionally,
you might restore the old value after the tests ran ok.


=item 4.)

If linking fails under Win32 because of a missing symbol
pthread_cond_init, apply the following patch to dbd/dbdimp.c:

  *** dbd/dbdimp.c.orig	Wed Sep 23 14:39:33 1998
  --- dbd/dbdimp.c	Fri Oct 02 10:37:16 1998
  ***************
  *** 1708,1712 ****
  --- 1709,1720 ----
      }
      return TRUE;
    }
  + 
  + #if !defined(_UNIX_)  &&  defined(WIN32)
  + int pthread_cond_init()
  + {
  +   return 0;
  + }
  + #endif

    #endif

(I could make this part of the source distribution, but I think this is an
ugly hack and hopefully Monty will fix the missing symbol in the next
release of MyODBC.)


=item 5.)

mSQL 2.0.4 had a bug, that caused the test t/40bindparam.t to fail.
This bug is fixed in later versions, 2.0.6 and higher.


=item 6.)

From time to time compiling DBD::mSQL fails with messages like

  In file included from ../dbd/myMsql.h:55,
                   from ../dbd/dbdimp.h:32,
                   from dbdimp.c:29:
  /usr/local/Hughes/include/common/portability.h:74:
    redefinition of `u_int'
  /usr/include/sys/types.h:52: `u_int' previously declared here
  /usr/local/Hughes/include/common/portability.h:78: redefinition of
    `ssize_t'
  /usr/include/sys/types.h:116: `ssize_t' previously declared here
  *** Error code 1

A workaroud is using

	perl Makefile.PL --config DEFINE="-DHAVE_SSIZE_T  -DHAVE_U_INT"

=back


=head1 KNOWN BUGS

The I<port> part of the first argument to the connect call is
implemented in an unsafe way when using mSQL. In fact it is just
setting the environment variable MSQL_TCP_PORT during the connect
call. If another connect call uses another port and the handles
are used simultaneously, they will interfere. I doubt that this
will ever change.


=head1 AUTHORS

The current versions of B<DBD::mSQL> and B<DBD::mysql> is almost
completely written by Jochen Wiedmann (I<joe@ispsoft.de>). The
first version's author was Alligator Descartes(I<descarte@symbolstone.org>),
who has been aided and abetted by Gary Shea, Andreas König and Tim Bunce
amongst others.

The B<Msql> and B<Mysql> modules have originally been written by
Andreas König <koenig@kulturbox.de>. The current version, mainly
an emulation layer, is from Jochen Wiedmann.


=head1 COPYRIGHT

This module is Copyright (c) 1997-1999 Jochen Wiedmann, with code
portions Copyright (c)1994-1997 their original authors. This module is
released under the same license as Perl itself. See the Perl README
for details.


=head1 MAILING LIST SUPPORT

=head1 MAILING LIST SUPPORT

This module is maintained and supported on a mailing list,

    msql-mysql-modules@lists.mysql.com

To subscribe to this list, send a mail to

    msql-mysql-modules-subscribe@lists.mysql.com

or

    msql-mysql-modules-digest-subscribe@lists.mysql.com

Mailing list archives are available at

    http://www.progressive-comp.com/Lists/?l=msql-mysql-modules


Additionally you might try the dbi-user mailing list for questions about
DBI and its modules in general. Subscribe via

    http://www.fugue.com/dbi

Mailing list archives are at

     http://www.rosat.mpe-garching.mpg.de/mailing-lists/PerlDB-Interest/
     http://outside.organic.com/mail-archives/dbi-users/
     http://www.coe.missouri.edu/~faq/lists/dbi.html


=head1 ADDITIONAL DBI INFORMATION

Additional information on the DBI project can be found on the World
Wide Web at the following URL:

    http://www.symbolstone.org/technology/perl/DBI

where documentation, pointers to the mailing lists and mailing list
archives and pointers to the most current versions of the modules can
be used.

Information on the DBI interface itself can be gained by typing:

    perldoc DBI

right now!

=cut
