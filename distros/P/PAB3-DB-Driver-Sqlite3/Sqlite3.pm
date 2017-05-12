package PAB3::DB::Driver::Sqlite3;
# =============================================================================
# Perl Application Builder
# Module: PAB::DB::Driver::Sqlite3
# Wrapper to libsqlite3 and driver for PAB::DB class
# =============================================================================

use strict;
no strict 'refs';
use warnings;
no warnings 'uninitialized';

use vars qw($VERSION @EXPORT_FNC @EXPORT_CONST $MODPERL $SessionCleanup);

BEGIN {
	$VERSION = '1.07';
	
	require XSLoader;
	XSLoader::load( __PACKAGE__, $VERSION );
	
	*fetch_array = \&fetch_row;

	@EXPORT_FNC = qw(
		open connect close query prepare bind_param execute
		num_fields num_rows fetch_names fetch_row fetch_col fetch_array
		fetch_hash fetch_field fetch_lengths field_seek free_result insert_id
		row_seek row_tell affected_rows
		set_charset get_charset quote quote_id escape
		auto_commit begin_work commit rollback
		errno error
	);
	@EXPORT_CONST = qw();
	
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
	if( $_[0] and $pkg eq __PACKAGE__ and $_[0] eq 'import' ) {
		*{$callpkg.'::import'} = \&import;
		return;
	}
	# export symbols
	*{"$callpkg\::sqlite3\_$_"} = \&{"$pkg\::$_"} foreach @EXPORT_FNC;
	*{"$callpkg\::SQLITE3\_$_"} = \&{"$pkg\::$_"} foreach @EXPORT_CONST;
}

sub open {
	$SessionCleanup or set_session_cleanup();
	&_open( @_ );
}

sub connect {
	$SessionCleanup or set_session_cleanup();
	&_open( @_ );
}

sub db_connect {
	my %arg = @_;
	$SessionCleanup or set_session_cleanup();
	&_open( $arg{'db'} );
}

sub sql_pre_calc_rows {
	return $_[0];
}

sub sql_calc_rows {
	my( $sql ) = @_;
	# SELECT ... FROM ...
	$sql =~ s!^\s*SELECT.+?FROM!SELECT COUNT(*) FROM!si; 
	$sql =~ s!\s*LIMIT\s+.*$!!si;
	return $sql;
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
		$SessionCleanup = 1;
	}
}

sub session_cleanup {
	return if ! $SessionCleanup;
	$SessionCleanup = 0;
	&_session_cleanup();
}

1;

__END__

=head1 NAME

PAB3::DB::Driver::Sqlite3 - Perl5 wrapper to the libsqlite3 and driver for the
PAB3::DB class

See more at L<the PAB3::DB manpage|PAB3::DB>

=head1 SYNOPSIS

  use PAB3::DB::Driver::Sqlite3;
  # functions and constants are exported by default
  
  $linkid = sqlite3_open( $db );
  
  $resid = sqlite3_query( $statement );
  $resid = sqlite3_query( $linkid, $statement );
  
  $stmtid = sqlite3_prepare( $statement );
  $stmtid = sqlite3_prepare( $linkid, $statement );
  
  $rv = sqlite3_bind_param( $stmtid, $p_num );
  $rv = sqlite3_bind_param( $stmtid, $p_num, $value );
  $rv = sqlite3_bind_param( $stmtid, $p_num, $value, $type );
  
  $stmtid = $resid = sqlite3_execute( $stmtid );
  $stmtid = $resid = sqlite3_execute( $stmtid, @bind_values );
  
  @row = sqlite3_fetch_row( $resid );
  @row = sqlite3_fetch_row( $stmtid );
  @row = sqlite3_fetch_array( $resid );
  @row = sqlite3_fetch_array( $stmtid );
  
  @col = sqlite3_fetch_col( $resid );
  @col = sqlite3_fetch_col( $stmtid );
  
  %row = sqlite3_fetch_hash( $resid );
  %row = sqlite3_fetch_hash( $stmtid );
  
  @names = sqlite3_fetch_names( $resid );
  @names = sqlite3_fetch_names( $stmtid );
  
  @lengths = sqlite3_fetch_lengths( $resid );
  @lengths = sqlite3_fetch_lengths( $stmtid );
  
  $num_rows = sqlite3_num_rows( $resid );
  $num_rows = sqlite3_num_rows( $stmtid );
  
  $row_index = sqlite3_row_tell( $resid );
  $row_index = sqlite3_row_tell( $stmtid );
  
  sqlite3_row_seek( $resid, $row_index );
  sqlite3_row_seek( $stmtid, $row_index );
  
  $num_fields = sqlite3_num_fields( $resid );
  $num_fields = sqlite3_num_fields( $stmtid );
  
  %field = sqlite3_fetch_field( $resid );
  %field = sqlite3_fetch_field( $resid, $offset );
  %field = sqlite3_fetch_field( $stmtid );
  %field = sqlite3_fetch_field( $stmtid, $offset );
  
  $field_index = sqlite3_field_tell( $resid );
  $field_index = sqlite3_field_tell( $stmtid );
  
  $hr = sqlite3_field_seek( $resid );
  $hr = sqlite3_field_seek( $resid, $offset );
  $hr = sqlite3_field_seek( $stmtid );
  $hr = sqlite3_field_seek( $stmtid, $offset );
  
  sqlite3_free_result( $resid );
  sqlite3_free_result( $stmtid );
  
  $affected_rows = sqlite3_affected_rows();
  $affected_rows = sqlite3_affected_rows( $linkid );
  $affected_rows = sqlite3_affected_rows( $stmtid );
  
  $id = sqlite3_insert_id();
  $id = sqlite3_insert_id( $linkid );
  $id = sqlite3_insert_id( $stmtid );
  
  $quoted = sqlite3_quote( $str );
  $quoted = sqlite3_quote_id( ... );
  
  sqlite3_auto_commit( $mode );
  sqlite3_auto_commit( $linkid, $mode );
  sqlite3_begin_work();
  sqlite3_begin_work( $linkid );
  sqlite3_commit();
  sqlite3_commit( $linkid );
  sqlite3_rollback();
  sqlite3_rollback( $linkid );
  
  $str   = sqlite3_error();
  $str   = sqlite3_error( $linkid );
  $errno = sqlite3_errno();
  $errno = sqlite3_errno( $linkid );
  
  sqlite3_close();
  sqlite3_close( $linkid );
  sqlite3_close( $stmtid );
  sqlite3_close( $resid );

=head1 DESCRIPTION

C<PAB3::DB::Driver::Sqlite3> provides an interface to the sqlite3 library.

How to get this module threadsafe?

from the SQLite3 authors:

In order to be thread-safe, SQLite must be compiled with the THREADSAFE
preprocessor macro set to 1. In the default distribution, the windows binaries
are compiled to be threadsafe but the linux binaries are not. If you want to
change this, you will have to recompile.

"Threadsafe" in the previous paragraph means that two or more threads can run
SQLite at the same time on different "sqlite3" structures returned from separate
calls to sqlite3_open(). B<It is never safe to use the same sqlite3 structure
pointer in two or more threads.>

--

Under ModPerl or PerlEx environment several scripts may take access to the same
instance of the perl interpreter. All functions are thread local but global
to the interpreter!
If you plan using several connections in your scripts which may access to
the same interpreter you should explicitly set $linkid in all expected
functions.
An alternative for this is the C<PAB3::DB> class. It takes care of it.
See more at L<the PAB3::DB manpage|PAB3::DB>.

=head2 Examples

=head3 Using "query" method

  use PAB3::DB::Driver::Sqlite3;
  
  # make a connection
  $linkid = sqlite3_open( '/path/to/db' )
      or die sqlite3_error();
  
  # send a query and store the result
  $resid = sqlite3_query( 'SELECT * FROM my_table' )
      or die sqlite3_error();
  
  # fetch rows from the result
  while( @row = sqlite3_fetch_row( $resid ) ) {
      print join( ', ', @row ), "\n";
  }
  
  # free the result
  sqlite3_free_result( $result );
  
  # close the connection
  sqlite3_close( $linkid );

=head3 Using "prepare" and "execute" methods

  use PAB3::DB::Driver::Sqlite3;
  
  # make a connection
  $linkid = sqlite3_open( '/path/to/db' )
      or die sqlite3_error();
  
  # prepare statement
  $stmtid = sqlite3_prepare( 'SELECT * FROM my_table WHERE my_field = ?' )
      or die mysql_error();
  
  # bind "foo" to parameter 1 as string
  sqlite3_bind_param( $stmtid, 1, 'foo', 's' );
      or die sqlite3_error();
  
  # execute statement and store the result
  $resid = sqlite3_execute( $stmtid )
      or die sqlite3_error();
  
  # fetch rows from the result
  while( @row = sqlite3_fetch_row( $resid ) ) {
      print join( ', ', @row ), "\n";
  }

=head2 Exports

By default all functions are exported. Exported functions get the
prefix "sqlite3_".

=head1 METHODS

=head2 Connection Control Methods

=over 2

=item $linkid = open ( $db )

Opens a connection to a SQLite3 database.

B<Paramters>

I<$db>

Path to database file. Creates a new database if it not exists.

B<Return Values>

Returns connection identifier ($linkid) on success or FALSE if an error occurs.


=item db_connect ( %arg )

Wrapper to open() used by L<PAB3::DB::connect()|PAB3::DB/connect>.

Following arguments are supported:

  db         => path to database file

B<Return Values>

Returns a connection link identifier ($linkid) on success, or NULL on failure. 


=item close ()

=item close ( $linkid )

Closes a previously opened database connection

B<Parameters>

I<$linkid>

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
If the link identifier is not specified, the last link is assumed.

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item errno ()

=item errno ( $linkid )

Returns the last error code for the most recent function call that can
succeed or fail.

B<Parameters>

I<$linkid>

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
If the link identifier is not specified, the last link is assumed.

B<Return Values>

An error code value for the last call, if it failed. zero means no error
occurred.


=item error ()

=item error ( $linkid )

Returns the last error message for the most recent function call that can
succeed or fail.

B<Parameters>

I<$linkid>

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
If the link identifier is not specified, the last link is assumed.

B<Return Values>

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

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
If the link identifier is not specified, the last link is assumed.

I<$query>

The query, as a string. 

B<Return Values>

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

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
If the link identifier is not specified, the last link is assumed.

I<$query>

The query, as a string. 

This parameter can include one or more parameter markers in the SQL statement
by embedding question mark (?) characters at the appropriate positions. 

B<Return Values>

Returns a statement identifier ($stmtid) or FALSE if an error occured.

B<See Also>

L<execute|PAB3::DB::Driver::Sqlite3/execute>,
L<bind_param|PAB3::DB::Driver::Sqlite3/bind_param>


=item bind_param ( $stmtid, $p_num )

=item bind_param ( $stmtid, $p_num, $value )

=item bind_param ( $stmtid, $p_num, $value, $type )

Binds a value to a prepared statement as parameter

B<Parameters>

I<$stmtid>

A statement identifier returned by L<prepare()|PAB3::DB::Driver::Sqlite3/prepare>.

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
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare>.

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
After executing a statement with L<query()|PAB3::DB::Driver::Sqlite3/query> or
L<execute()|PAB3::DB::Driver::Sqlite3/execute>, returns the number
of rows changed (for UPDATE), deleted (for DELETE), or inserted (for INSERT).
For SELECT statements, affected_rows() works like
L<num_rows()|PAB3::DB::Driver::Sqlite3/num_rows>. 

B<Parameters>

I<$linkid>

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
If the link identifier is not specified, the last link is assumed.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare>.

B<Return Values>

An integer greater than zero indicates the number of rows affected or retrieved.
Zero indicates that no records where updated for an UPDATE statement,
no rows matched the WHERE clause in the query or that no query has yet
been executed.


=item insert_id ()

=item insert_id ( $linkid )

=item insert_id ( $stmtid )

Returns the auto generated id used in the last query or statement. 

B<Parameters>

I<$linkid>

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
If the link identifier is not specified, the last link is assumed.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare>.

B<Return Values>

The value of the AUTO_INCREMENT field that was updated by the previous query.
Returns zero if there was no previous query on the connection or if the query
did not update an AUTO_INCREMENT value. 


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

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

B<Return Values>

Returns an array of values that corresponds to the fetched row or NULL if there
are no more rows in result set.


=item fetch_hash ( $resid )

=item fetch_hash ( $stmtid )

Fetch a result row as an associative array (hash).

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

B<Return Values>

Returns an associative array (hash) of values representing the fetched row in
the result set, where each key in the hash represents the name of one of the
result set's columns or NULL if there are no more rows in resultset. 

If two or more columns of the result have the same field names, the last
column will take precedence. To access the other column(s) of the same name,
you either need to access the result with numeric indices by using
L<fetch_row()|PAB3::DB::Driver::Sqlite3/fetch_row> or add alias names.


=item fetch_col ( $resid )

=item fetch_col ( $stmtid )

Fetch the first column of each row in the result set a an array.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

B<Return Values>

Returns an array of values that corresponds to the first column of each row
in the result set or FALSE if no data is available.


=item fetch_lengths ( $resid )

=item fetch_lengths ( $stmtid )

Returns the lengths of the columns of the current row in the result set.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

B<Return Values>

An array of integers representing the size of each column (not including
terminating null characters). FALSE if an error occurred.


=item num_rows ( $resid )

=item num_rows ( $stmtid )

Gets the number of rows in a result.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

B<Return Values>

Returns number of rows in the result set.


=item row_tell ( $resid )

=item row_tell ( $stmtid )

Gets the actual position of row cursor in a result (Starting at 0).

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

B<Return Values>

Returns the actual position of row cursor in a result.


=item row_seek ( $resid, $offset )

=item row_seek ( $stmtid, $offset )

Sets the actual position of row cursor in a result (Starting at 0).

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

I<$offset>

Absolute row position. Valid between 0 and
L<num_rows()|PAB3::DB::Driver::Sqlite3/num_rows> - 1.

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

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

B<Return Values>

Returns an array of field names or FALSE if no field information is available. 


=item num_fields ( $resid )

=item num_fields ( $stmtid )

Gets the number of fields (columns) in a result.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

B<Return Values>

Returns number of fields in the result set.


=item fetch_field ( $resid )

=item fetch_field ( $resid, $offset )

=item fetch_field ( $stmtid )

=item fetch_field ( $stmtid, $offset )

Returns the next field in the result.

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

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

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

B<Return Values>

Returns the actual position of field cursor in the result.


=item field_seek ( $resid, $offset )

=item field_seek ( $stmtid, $offset )

Sets the actual position of field cursor in the result (Starting at 0).

B<Paramters>

I<$resid>

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

I<$offset>

Absolute field position. Valid between 0 and
L<num_fields()|PAB3::DB::Driver::Sqlite3/num_fields> - 1.

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

A result set identifier returned by L<query()|PAB3::DB::Driver::Sqlite3/query>
or L<execute()|PAB3::DB::Driver::Sqlite3/execute>.

I<$stmtid>

A statement identifier returned by
L<prepare()|PAB3::DB::Driver::Sqlite3/prepare> which has been executed.

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

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
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

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
If the link identifier is not specified, the last link is assumed.

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item commit ()

=item commit ( $linkid )

Commits the current transaction for the database connection.

B<Parameters>

I<$linkid>

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
If the link identifier is not specified, the last link is assumed.

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item rollback ()

=item rollback ( $linkid )

Rollbacks the current transaction for the database.

B<Parameters>

I<$linkid>

A link identifier returned by L<open()|PAB3::DB::Driver::Sqlite3/open>.
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

  $s = sqlite3_quote_id( 'table' );
  # $s should be "table"
  
  $s = sqlite3_quote_id( 'table', 'field' );
  # $s should be "table"."field"
  
  $s = sqlite3_quote_id( 'table', '*' );
  # $s should be "table".*


=back

=head1 AUTHORS

Christian Mueller <christian_at_hbr1.com>

=head1 COPYRIGHT

The PAB3::DB::Driver::Sqlite3 module is free software. You may distribute under
the terms of either the GNU General Public License or the Artistic License, as
specified in the Perl README file.

=cut
