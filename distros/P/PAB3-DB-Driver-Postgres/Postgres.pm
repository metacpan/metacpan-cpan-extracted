package PAB3::DB::Driver::Postgres;
# =============================================================================
# Perl Application Builder
# Module: PAB::DB::Driver::Postgres
# Wrapper of libpgsql functions
# =============================================================================

use strict;
no strict 'refs';
use warnings;
no warnings 'uninitialized';
no warnings 'numeric';

use vars qw($VERSION $PGPATH @EXPORT_FNC @EXPORT_CONST $MODPERL $SessionCleanup);

use constant {
	CLIENT_RECONNECT	=> 16384,
};

BEGIN {
	$VERSION = '1.07';
	
	require XSLoader;
	XSLoader::load( __PACKAGE__, $VERSION );
	
	*fetch_array = \&fetch_row;
	
	@EXPORT_FNC = qw(
		connect close reconnect query prepare bind_param execute
		num_fields num_rows fetch_names fetch_row fetch_col fetch_array
		fetch_hash fetch_field fetch_lengths field_seek free_result
		insert_id
		row_seek row_tell quote quote_id errno error
		set_charset get_charset
		show_dbs show_tables show_fields show_index
	);
	@EXPORT_CONST = qw(
		CLIENT_RECONNECT
	);
	
	$MODPERL = 2 if exists $ENV{'MOD_PERL_API_VERSION'}
		&& $ENV{'MOD_PERL_API_VERSION'} == 2;
	$MODPERL = 1 if defined $Apache::VERSION
		&& $Apache::VERSION > 1 && $Apache::VERSION < 1.99;

	if( $MODPERL == 2 ) {
		require mod_perl2;
		require Apache2::Module;
		require Apache2::ServerUtil;
	}
	elsif( $MODPERL == 1 ) {
		require Apache;
	}
	$SessionCleanup = 0;
}

END {
	&_cleanup();
}

sub import {
	my $pkg = shift;
	my $callpkg = caller();
	if( $_[0] and $pkg eq __PACKAGE__ and $_[0] and $_[0] eq 'import' ) {
		*{$callpkg.'::import'} = \&import;
		return;
	}
	# export symbols
	*{$callpkg . '::pg_' . $_} = \&{$pkg . '::' . $_} foreach @EXPORT_FNC;
	*{$callpkg . '::PG_' . $_} = \&{$pkg . '::' . $_} foreach @EXPORT_CONST;
}

sub connect {
	$SessionCleanup or set_session_cleanup();
	&_connect( @_ );
}

sub db_connect {
	my %arg = @_;
	my( $opt, $key, $options, $server );
	$SessionCleanup or set_session_cleanup();
	$opt = 0;
	$options = $arg{'options'};
	if( $options && ref( $options ) eq 'HASH' ) {
		foreach( keys %{ $options } ) {
			$key = lc( $_ );
			if( $key eq 'reconnect' ) {
				$opt |= CLIENT_RECONNECT if $options->{$_};
			}
		}
	}
	if( $arg{'host'} ) {
		$server = $arg{'host'};
	}
	if( $arg{'socket'} ) {
		$server .= ':' . $arg{'socket'};
	}
	elsif( $arg{'port'} ) {
		$server .= ':' . $arg{'port'};
	}
	return &_connect( $server, $arg{'user'}, $arg{'passwd'}, $arg{'db'}, $opt );
}

sub sql_pre_calc_rows {
	return $_[0];
}

sub sql_calc_rows {
	my( $sql ) = @_;
	# SELECT ... FROM ...
	$sql =~ s!^\s*SELECT.+?FROM!SELECT COUNT(*) FROM!si; 
	$sql =~ s!\s*LIMIT\s+\d+!!si;
	$sql =~ s!\s*OFFSET\s+\d+!!si;
	return $sql;
}

sub show_fields {
	my $linkid = $_[0] > 0 ? shift : 0;
	my( $table, $schema, $db, $wild ) = @_;
	my( $sql, $res, @row, @res, $nl, %pkd, %ukd );
	$table = lc( $table );
	$schema = lc( $schema ) if $schema;
	$sql = <<EOT1;
SELECT
  pc.conname as f0
  , pg_catalog.pg_get_constraintdef(pc.oid, true) AS f1
  , pc.contype as f2
FROM
  pg_catalog.pg_constraint pc
WHERE
  pc.conrelid = (
  	SELECT oid FROM pg_catalog.pg_class WHERE relname = '$table'
EOT1
	if( $schema ) {
		$sql .=
		 'AND relnamespace = ( SELECT oid FROM pg_catalog.pg_namespace'
		 . ' WHERE nspname = \'' . $schema . '\' )';
	}
	$sql .= ' )';
	$res = &query( $linkid, $sql ) or return undef;
#	print $sql, "\n";
#	print "-------\n", join( '|', &fetch_names( $res ) ), "\n-------\n";
	while( @row = &fetch_row( $res ) ) {
		my @tmp = map{ ( m!\"(.+)\"! )[0] }
			split( /,\s*/, ( $row[1] =~ m!\((.+?)\)! )[0] );
#		print join( '|', @row ), "\n";
		if( $row[2] eq 'p' ) {
			$pkd{$_} = 1 foreach @tmp;
		}
		elsif( $row[2] eq 'u' ) {
			$ukd{$_} = 1 foreach @tmp;
		}
	}
	&free_result( $res );
	$sql = <<EOT3;
SELECT
	a.attname as f0,
	pg_catalog.format_type(a.atttypid, a.atttypmod) as f1, 
	a.attnotnull as f2,
	adef.adsrc as f3,
	(
		SELECT 1 FROM pg_depend pd, pg_class pc
		WHERE pd.objid = pc.oid 
			AND pd.classid = pc.tableoid 
			AND pd.refclassid = pc.tableoid
			AND pd.refobjid = a.attrelid
			AND pd.refobjsubid = a.attnum
			AND pd.deptype = 'i'::"char"
			AND pc.relkind = 'S'::"char"
	) IS NOT NULL AS f4
FROM
pg_attribute a
LEFT JOIN pg_attrdef adef ON a.attrelid = adef.adrelid AND a.attnum = adef.adnum
WHERE 
a.attrelid = (
	SELECT oid FROM pg_class WHERE relname = '$table'
EOT3
	if( $schema ) {
		$sql .= 'AND relnamespace = (SELECT oid FROM pg_namespace'
			. ' WHERE nspname = \'' . $schema . '\')'
		;
	}
	$sql .= <<EOT4;
)
AND a.attnum > 0 AND NOT a.attisdropped
ORDER BY a.attnum
EOT4
#	print "\n", $sql;
	$res = &query( $linkid, $sql ) or return undef;
	@res = ();
#	print "-------\n", join( '|', &fetch_names( $res ) ), "\n-------\n";
	while( @row = &fetch_row( $res ) ) {
		# COLUMN, NULLABLE, DEFAULT, IS_PRIMARY, IS_UNIQUE, TYPENAME, AUTOINC
		$nl = $row[2] eq 't' ? 0 : 1;
		push @res,
		[
			$row[0],
			$nl,
			$row[3] ? $row[3] : $nl ? undef : '',
			$pkd{$row[0]},
			$ukd{$row[0]},
			$row[1],
			$row[4] eq 't' ? 1 : 0,
		];
#		print join( '|', @row ), "\n";
	}
	&free_result( $res );
#	print "---\n";
	return @res;
}

sub show_index {
	my $linkid = $_[0] > 0 ? shift : 0;
	my( $table, $schema, $db ) = @_;
	my( $sql, $res, @row, @res );
	$table = lc( $table );
	$schema = lc( $schema ) if $schema;

	$sql = <<EOT1;
SELECT
	c2.relname AS f0,
	i.indisprimary AS f1,
	i.indisunique AS f2,
	pg_catalog.pg_get_indexdef(i.indexrelid, 0, true) AS f3
FROM
	pg_catalog.pg_class c,
	pg_catalog.pg_class c2,
	pg_catalog.pg_index i,
	pg_namespace n
WHERE
	c.relname = '$table'
	{schema}
	AND pg_catalog.pg_table_is_visible( c.oid ) 
	AND c.oid = i.indrelid
	AND i.indexrelid = c2.oid
	AND n.oid = c2.relnamespace
ORDER BY c2.relname
EOT1

	if( $schema ) {
		$sql =~ s!\{schema\}!AND n.nspname = '$schema'!;
	}
	else {
		$sql =~ s!\{schema\}!!;
	}
#	print $sql, "\n";
	$res = &query( $linkid, $sql ) or return undef;
#	print "-------\n", join( '|', &fetch_names( $res ) ), "\n-------\n";
	while( @row = &fetch_row( $res ) ) {
		# NAME, COLUMN, TYPE(1,2,3)
		foreach( split( /,\s*/, ( $row[3] =~ m!\((.+?)\)! )[0] ) ) {
			push @res, [
				$row[0],
				$_,
				$row[1] eq 't' ? 1 : $row[2] eq 't' ? 2 : 3
			];
		}
#		print join( '|', @row ), "\n";
	}
	&free_result( $res );
	return @res;
}

sub set_session_cleanup {
    if( ! $SessionCleanup ) {
		if( $MODPERL == 2 ) {
	    	my $r = Apache2::RequestUtil->request;
	    	$r->pool->cleanup_register( \&session_cleanup );
	    }
		elsif( $MODPERL == 1 ) {
	    	my $r = Apache->request;
	    	$r->register_cleanup( \&session_cleanup );
	    }
	    elsif( $ENV{'GATEWAY_INTERFACE'} eq 'CGI-PerlEx' ) {
	    	if( $PAB3::CGI::VERSION ) {
	    		&PAB3::CGI::cleanup_register( \&session_cleanup );
	    	}
	    }
		$SessionCleanup = 1;
	}
}

sub session_cleanup {
	return if ! $SessionCleanup;
	$SessionCleanup = 0;
	&_cleanupSession();
}

1;

__END__

=head1 NAME

PAB3::DB::Driver::Postgres - Perl5 wrapper to the pgsql libary and driver
for the PAB3::DB class

See more at L<the PAB3::DB manpage|PAB3::DB>

=head1 SYNOPSIS

  use PAB3::DB::Driver::Postgres;
  # functions and constants are exported by default
  
  $linkid = pg_connect();
  $linkid = pg_connect( $server );
  $linkid = pg_connect( $server, $user );
  $linkid = pg_connect( $server, $user, $auth );
  $linkid = pg_connect( $server, $user, $auth, $db );
  $linkid = pg_connect( $server, $user, $auth, $db, $client_flag );
  
  $resid = pg_query( $statement );
  $resid = pg_query( $linkid, $statement );
  
  $stmtid = pg_prepare( $statement );
  $stmtid = pg_prepare( $linkid, $statement );
  
  $rv = pg_bind_param( $stmtid, $p_num );
  $rv = pg_bind_param( $stmtid, $p_num, $value );
  $rv = pg_bind_param( $stmtid, $p_num, $value, $type );
  
  $stmtid = $resid = pg_execute( $stmtid );
  $stmtid = $resid = pg_execute( $stmtid, @bind_values );
  
  @row = pg_fetch_row( $resid );
  @row = pg_fetch_row( $stmtid );
  @row = pg_fetch_array( $resid );
  @row = pg_fetch_array( $stmtid );
  
  @col = pg_fetch_col( $resid );
  @col = pg_fetch_col( $stmtid );
  
  %row = pg_fetch_hash( $resid );
  %row = pg_fetch_hash( $stmtid );
  
  @names = pg_fetch_names( $resid );
  @names = pg_fetch_names( $stmtid );
  
  @lengths = pg_fetch_lengths( $resid );
  @lengths = pg_fetch_lengths( $stmtid );
  
  $num_rows = pg_num_rows( $resid );
  $num_rows = pg_num_rows( $stmtid );
  
  $row_index = pg_row_tell( $resid );
  $row_index = pg_row_tell( $stmtid );
  
  pg_row_seek( $resid, $row_index );
  pg_row_seek( $stmtid, $row_index );
  
  $num_fields = pg_num_fields( $resid );
  $num_fields = pg_num_fields( $stmtid );
  
  %field = pg_fetch_field( $resid );
  %field = pg_fetch_field( $resid, $offset );
  %field = pg_fetch_field( $stmtid );
  %field = pg_fetch_field( $stmtid, $offset );
  
  $field_index = pg_field_tell( $resid );
  $field_index = pg_field_tell( $stmtid );
  
  $hr = pg_field_seek( $resid );
  $hr = pg_field_seek( $resid, $offset );
  $hr = pg_field_seek( $stmtid );
  $hr = pg_field_seek( $stmtid, $offset );
  
  pg_free_result( $resid );
  pg_free_result( $stmtid );
  
  $affected_rows = pg_affected_rows();
  $affected_rows = pg_affected_rows( $linkid );
  $affected_rows = pg_affected_rows( $stmtid );
  
  $id = pg_insert_id( $field, $table );
  $id = pg_insert_id( $field, $table, $schema );
  $id = pg_insert_id( $linkid, $field, $table );
  $id = pg_insert_id( $linkid, $field, $table, $schema );
  $id = pg_insert_id( $stmtid, $field, $table );
  $id = pg_insert_id( $stmtid, $field, $table, $schema );
  
  $hr = pg_set_charset( $charset );
  $hr = pg_set_charset( $linkid, $charset );
  
  $charset = pg_get_charset();
  $charset = pg_get_charset( $linkid );
  
  $quoted = pg_quote( $str );
  $quoted = pg_quote_id( ... );
  
  pg_auto_commit( $mode );
  pg_auto_commit( $linkid, $mode );
  pg_begin_work();
  pg_begin_work( $linkid );
  pg_commit();
  pg_commit( $linkid );
  pg_rollback();
  pg_rollback( $linkid );
  
  $str = pg_error();
  $str = pg_error( $linkid );
  
  pg_close();
  pg_close( $linkid );
  pg_close( $stmtid );
  pg_close( $resid );

=head1 DESCRIPTION

C<PAB3::DB::Driver::Postgres> provides an interface to the pgsql library.

This module should be B<threadsafe, BUT:>

If you plan using C<threads>, you should use own connections in each
thread. It is never safe to use the same connection in two or more threads.

Under ModPerl or PerlEx environment several scripts may take access to the same
instance of the perl interpreter. All functions are thread local but global to
the interpreter!
If you plan using different connections in your scripts which may access to
the same interpreter you should explicitly set I<$linkid> in all expected
functions.
You can alternatively use the C<PAB3::DB> class. It takes care of it by itself.
See more at L<the PAB3::DB manpage|PAB3::DB>.

=head2 Examples

=head3 Using "query" method

  use PAB3::DB::Driver::Postgres;
  
  # make a connection
  $linkid = pg_connect( 'host', 'user', 'passwd', 'db' )
      or die pg_error();
  
  # send a query and store the result
  $resid = pg_query( 'SELECT * FROM my_table' )
      or die pg_error();
  
  # fetch rows from the result
  while( @row = pg_fetch_row( $resid ) ) {
      print join( ', ', @row ), "\n";
  }
  
  # free the result
  pg_free_result( $result );
  
  # close the connection
  pg_close( $linkid );

=head3 Using "prepare" and "execute" methods

  use PAB3::DB::Driver::Postgres;
  
  # make a connection
  $linkid = pg_connect( 'host', 'user', 'passwd', 'db' )
      or die pg_error();
  
  # prepare statement
  $stmtid = pg_prepare( 'SELECT * FROM my_table WHERE my_field = ?' )
      or die pg_error();
  
  # bind "foo" to parameter 1 as string
  pg_bind_param( $stmtid, 1, 'foo', 's' );
      or die pg_error();
  
  # execute statement and store the result
  $resid = pg_execute( $stmtid )
      or die pg_error();
  
  # fetch rows from the result
  while( @row = pg_fetch_row( $resid ) ) {
      print join( ', ', @row ), "\n";
  }

=head2 Exports

By default all functions and constants are exported. Exported functions get the
prefix "pg_". Exported constants get the prefix "PG_".

=head1 METHODS

=head2 Connection Control Methods

=over 2

=item connect ()

=item connect ( $server )

=item connect ( $server, $user )

=item connect ( $server, $user, $auth )

=item connect ( $server, $user, $auth, $db )

=item connect ( $server, $user, $auth, $db, $client_flag )

Opens a connection to a PostgreSQL server.

B<Parameters>

I<$server>

The PostgreSQL server. It can also include a port number. e.g. "hostname:port". 

I<$username>

The username.

I<$auth>

The authorization password.

I<$db>

The database name. 

I<$client_flag>

The I<$client_flag> parameter can be a combination of the following constants:

  CLIENT_RECONNECT ..... Enable automatic reconnection to the server if the
                         connection is found to have been lost.

B<Return Values>

Returns a connection link identifier ($linkid) on success, or NULL on failure. 

B<Example>

  use PAB3::DB::Driver::Postgres;
  # functions and constants are exported by default
  
  # make connection to localhost as user "user" to database "testdb"
  $linkid = pg_connect( '', 'user', '', 'testdb', PG_CLIENT_RECONNECT );
  if( ! $linkid ) {
      die 'Connection failed: ' . pg_error();
  }


=item db_connect ( %arg )

Wrapper to connect() used by L<PAB3::DB::connect()|PAB3::DB/connect>.

Following arguments are supported:

  host       => hostname
  user       => authorized username
  auth       => authorization password
  db         => database name
  port       => port for tcp/ip connection
  options    => hashref with parameters mapped to $client_flag
                these parameters are:
                'reconnect'
                a description can be found at connect() above

B<Return Values>

Returns a connection link identifier ($linkid) on success, or NULL on failure. 


=item close ()

=item close ( $linkid )

Closes a previously opened database connection

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

B<Return Values:>

Returns TRUE on success or FALSE on failure.


=item set_charset ( $charset )

=item set_charset ( $linkid, $charset )

Sets the default character set to be used when sending data from and to the
database server.

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

I<$charset>

The charset to be set as default.

B<Return Values:>

Returns TRUE on success or FALSE on failure.


=item get_charset ()

=item get_charset ( $linkid )

Gets the default character.

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

B<Return Values:>

Returns the default charset or NULL on error.


=item error ()

=item error ( $linkid )

Returns the last error message for the most recent function call that can
succeed or fail.

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

B<Return Values:>

A string that describes the error. An empty string if no error occurred.


=back

=head2 Command Execution Methods

=over 2

=item query ( $query )

=item query ( $linkid, $query )

Sends a query to the currently active database on the server that is associated
with the specified link identifier. 

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

I<$query>

The query, as a string. 

B<Return Values:>

For SELECT, SHOW, DESCRIBE, EXPLAIN and other statements returning resultset,
query returns a result set identifier ($resid) on success, or FALSE on error. 

For other type of SQL statements, UPDATE, DELETE, DROP, etc, query returns
TRUE on success or FALSE on error. 


=item prepare ( $query )

=item prepare ( $linkid, $query )

Prepares the SQL query pointed to by the null-terminated string query, and
returns a statement handle to be used for further operations on the statement.
The query must consist of a single SQL statement. 

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

I<$query>

The query, as a string. 

This parameter can include one or more parameter markers in the SQL statement
by embedding question mark (?) characters at the appropriate positions. 

B<Return Values>

Returns a statement identifier ($stmtid) or FALSE if an error occured.

B<See Also>

L<execute>, L<bind_param>

=item bind_param ( $stmtid, $p_num )

=item bind_param ( $stmtid, $p_num, $value )

=item bind_param ( $stmtid, $p_num, $value, $type )

Binds a value to a prepared statement as parameter

B<Parameters>

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare>.

I<$p_num>

The number of parameter starting at 1.

I<$value>

Any value.

I<$type>

A string that contains one character which specify the type for the
corresponding bind value: 

  Character Description
  ---------------------
  i   corresponding value has type integer
  d   corresponding value has type double
  s   corresponding value has type string
  b   corresponding value has type binary

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item execute ( $stmtid )

=item execute ( $stmtid, @bind_values )

Executes a query that has been previously prepared using the prepare() function.
When executed any parameter markers which exist will automatically be replaced
with the appropiate data. 

B<Parameters>

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare>.

I<@bind_values>

An array of values to bind. Values bound in this way are usually treated as
"string" types unless the driver can determine the correct type, or unless
bind_param() has already been used to specify the type.

B<Return Values>

For SELECT, SHOW, DESCRIBE, EXPLAIN and other statements returning resultset,
query returns a result set identifier ($resid) on success, or FALSE on error. 

For other type of SQL statements, UPDATE, DELETE, DROP, etc, query returns
TRUE on success or FALSE on error. 


=back

=head3 Retrieving Query Result Information

=over 2

=item affected_rows ()

=item affected_rows ( $linkid )

=item affected_rows ( $stmtid )

Gets the number of affected rows in a previous SQL operation
After executing a statement with L<query()|PAB3::DB::Driver::Postgres/query> or
L<execute()|PAB3::DB::Driver::Postgres/execute>, returns the number
of rows changed (for UPDATE), deleted (for DELETE), or inserted (for INSERT).
For SELECT statements, affected_rows() works like
L<num_rows()|PAB3::DB::Driver::Postgres/num_rows>. 

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

An integer greater than zero indicates the number of rows affected or retrieved.
Zero indicates that no records where updated for an UPDATE statement,
no rows matched the WHERE clause in the query or that no query has yet
been executed.


=item insert_id ( $linkid, $field, $table )

=item insert_id ( $linkid, $field, $table, $schema )

=item insert_id ( $stmtid, $field, $table )

=item insert_id ( $stmtid, $field, $table, $schema )

Returns the auto generated id used in the last query or statement. 

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

I<$field>

The field to retrieve the generated id from.

I<$table>

The table where the field is located.

I<$schema>

The schema where the table is located.

B<Return Values>

The value of the SERIAL field that was updated by the previous query.
Returns zero if there was no previous query on the connection or if the query
did not update an SERIAL value of the specified field and table. 


=back

=head4 Accessing Rows in a Result Set

=over 2

=item fetch_row ( $resid )

=item fetch_row ( $stmtid )

=item fetch_array ( $resid )

=item fetch_array ( $stmtid )

Get a result row as an enumerated array. fetch_array is a synonym for fetch_row.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

Returns an array of values that corresponds to the fetched row or NULL if there
are no more rows in result set.


=item fetch_hash ( $resid )

=item fetch_hash ( $stmtid )

Fetch a result row as an associative array (hash).

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

Returns an associative array (hash) of values representing the fetched row in
the result set, where each key in the hash represents the name of one of the
result set's columns or NULL if there are no more rows in resultset. 

If two or more columns of the result have the same field names, the last
column will take precedence. To access the other column(s) of the same name,
you either need to access the result with numeric indices by using
L<fetch_row()|PAB3::DB::Driver::Postgres/fetch_row> or add alias names.


=item fetch_col ( $resid )

=item fetch_col ( $stmtid )

Fetch the first column of each row in the result set a an array.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

Returns an array of values that corresponds to the first column of each row
in the result set or FALSE if no data is available.


=item fetch_lengths ( $resid )

=item fetch_lengths ( $stmtid )

Returns the lengths of the columns of the current row in the result set.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

An array of integers representing the size of each column (not including
terminating null characters). FALSE if an error occurred.


=item num_rows ( $resid )

=item num_rows ( $stmtid )

Gets the number of rows in a result.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

Returns number of rows in the result set.


=item row_tell ( $resid )

=item row_tell ( $stmtid )

Gets the actual position of row cursor in a result (Starting at 0).

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

Returns the actual position of row cursor in a result.


=item row_seek ( $resid, $offset )

=item row_seek ( $stmtid, $offset )

Sets the actual position of row cursor in a result (Starting at 0).

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

I<$offset>

Absolute row position. Valid between 0 and
L<num_rows()|PAB3::DB::Driver::Postgres/num_rows> - 1.

B<Return Values>

Returns the previous position of row cursor in a result.


=back

=head4 Accessing Fields (Columns) in a Result Set

=over 2

=item fetch_names ( $resid )

=item fetch_names ( $stmtid )

Returns an array of field names representing in a result set.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

Returns an array of field names or FALSE if no field information is available. 


=item num_fields ( $resid )

=item num_fields ( $stmtid )

Gets the number of fields (columns) in a result.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

Returns number of fields in the result set.


=item fetch_field ( $resid )

=item fetch_field ( $resid, $offset )

=item fetch_field ( $stmtid )

=item fetch_field ( $stmtid, $offset )

Returns the next field in the result.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

I<$offset>

If set, moves the field cursor to this position.

B<Return Values>

Returns a hash which contains field definition information or FALSE if no
field information is available. 


=item field_tell ( $resid )

=item field_tell ( $stmtid )

Gets the actual position of field cursor in a result (Starting at 0).

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

Returns the actual position of field cursor in the result.


=item field_seek ( $resid, $offset )

=item field_seek ( $stmtid, $offset )

Sets the actual position of field cursor in the result (Starting at 0).

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

I<$offset>

Absolute field position. Valid between 0 and
L<num_fields()|PAB3::DB::Driver::Postgres/num_fields> - 1.

B<Return Values>

Returns the previous position of field cursor in the result.


=back

=head4 Freeing Results or Statements

=over 2

=item free_result ( $resid )

=item free_result ( $stmtid )

Frees the memory associated with a result or statement.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Postgres/query>
or L<execute()|PAB3::DB::Driver::Postgres/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Postgres/prepare> which has been executed.

B<Return Values>

Resturn TRUE on success or FALSE on error.

=back

=head2 Transaction Methods

=over 2

=item auto_commit ( $bool )

=item auto_commit ( $linkid, $mode )

Turns on or off auto-commit mode on queries for the database connection.

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

I<$mode>

Whether to turn on auto-commit or not.

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item begin_work ()

=item begin_work ( $linkid )

Turns off auto-commit mode for the database connection until transaction
is finished.

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item commit ()

=item commit ( $linkid )

Commits the current transaction for the database connection.

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item rollback ()

=item rollback ( $linkid )

Rollbacks the current transaction for the database.

B<Parameters>

I<$linkid>

A link identifier returned by L<connect()|PAB3::DB::Driver::Postgres/connect>.
If the link identifier is not specified, the last link is assumed.

B<Return Values>

Returns TRUE on success or FALSE on failure.

=back

=head2 Other Functions

=over 2

=item quote ( $value )

Quote a string literal for use as a literal value in an SQL statement,
by escaping any special characters (such as quotation marks) contained within
the string and adding the required type of outer quotation marks.

The quote() method should not be used with "Placeholders and Bind Values".

B<Parameters>

I<$value>

Value to be quoted.

B<Return Values>

The quoted value with adding the required type of outer quotation marks.


=item quote_id ( $field )

=item quote_id ( $table, $field )

=item quote_id ( $schema, $table, $field )

=item quote_id ( $catalog, $schema, $table, $field )

Quote an identifier (table name etc.) for use in an SQL statement, by escaping
any special characters it contains and adding the required type of outer
quotation marks.

B<Parameters>

One or more values to be quoted.

B<Return Values>

The quoted string with adding the required type of outer quotation marks.

B<Examples>

  $s = pg_quote_id( 'table' );
  # $s should be "table"
  
  $s = pg_quote_id( 'table', 'field' );
  # $s should be "table"."field"
  
  $s = pg_quote_id( 'table', '*' );
  # $s should be "table".*


=back

=head1 AUTHORS

Christian Mueller <christian_at_hbr1.com>

=head1 COPYRIGHT

The PAB3::DB::Driver::Postgres module is free software. You may distribute under
the terms of either the GNU General Public License or the Artistic License, as
specified in the Perl README file.

=cut
