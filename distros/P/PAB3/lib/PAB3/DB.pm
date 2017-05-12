package PAB3::DB;
# =============================================================================
# Perl Application Builder
# Module: PAB3::DB
# Common interface for database communication
# =============================================================================
use Carp ();
use Time::HiRes ();

use strict;
no strict 'refs';
use warnings;
no warnings 'uninitialized';
no warnings 'numeric';

use vars qw($VERSION);

BEGIN {
	$VERSION = '1.1.2';

	*fetch_array = \&fetch_row;
	*new = \&connect;
}

our $DB_TABLE_NAME		= 0;
our $DB_TABLE_SCHEMA	= 1;
our $DB_TABLE_DB		= 2;
our $DB_TABLE_TYPE		= 3;

our $DB_FIELD_NAME		= 0;
our $DB_FIELD_NULLABLE	= 1;
our $DB_FIELD_DEFAULT	= 2;
our $DB_FIELD_PRIKEY	= 3;
our $DB_FIELD_UNIKEY	= 4;
our $DB_FIELD_TYPENAME	= 5;
our $DB_FIELD_IDENTITY	= 6; # autoincrement

our $DB_INDEX_NAME		= 0;
our $DB_INDEX_COLUMN	= 1;
our $DB_INDEX_TYPE		= 2;

require Exporter;
our @EXPORT_CONST = qw(
	$DB_TABLE_NAME $DB_TABLE_SCHEMA $DB_TABLE_DB
	$DB_FIELD_NAME $DB_FIELD_NULLABLE $DB_FIELD_DEFAULT $DB_FIELD_PRIKEY
	$DB_FIELD_UNIKEY $DB_FIELD_TYPENAME $DB_FIELD_IDENTITY
	$DB_INDEX_NAME $DB_INDEX_COLUMN $DB_INDEX_TYPE
);
our @EXPORT_OK = ( @EXPORT_CONST );
require Exporter;
*import = \&Exporter::import;

our $DB_ARGV		= 0;
our $DB_LINKID		= 1;
our $DB_QUERYID		= 2;
our $DB_LASTQUERY	= 3;
our $DB_PKG			= 4;
our $DB_LOGGER		= 5;
our $DB_WARN		= 6;
our $DB_DIE			= 7;
our $DB_ERROR		= 8;
our $DB_ERRNO		= 9;

our $DB_LASTINDEX	= 9;

our $LastError = '';
our $LastErrno = 0;

1;

sub DESTROY {
	my $this = shift or return;
	$this->close();
#	my $pkg = $this->[$DB_PKG];
#	&{"$${pkg}::close"}( $this->[$DB_LINKID] );
}

sub CLONE_SKIP {
	return 1;
}

sub connect {
	my $proto = shift;
	my( $class, $this, $pkg, $info, %arg );
	$class = ref( $proto ) || $proto;
	$this  = [];
	bless( $this, $class );
	%arg = @_;
	$arg{'driver'} ||= 'Mysql';
	$pkg = __PACKAGE__ . '::Driver::' .
		uc( substr( $arg{'driver'}, 0, 1 ) ) . lc( substr( $arg{'driver'}, 1 ) )
	;
	if( ! ${$pkg . '::VERSION'} ) {
		eval( "require $pkg;" );
		die $@ if $@;
	}
	$this->[$DB_PKG] = \$pkg;
	$this->[$DB_LOGGER] ||= $arg{'logger'};
	$this->[$DB_DIE] = defined $arg{'die'} ? $arg{'die'} : 1;
	$this->[$DB_WARN] = defined $arg{'warn'} ? $arg{'warn'} : 1;
	$this->[$DB_ARGV] = \%arg;
	if( $this->[$DB_LOGGER] ) {
		$info = ( $arg{'user'} ? $arg{'user'} . '@' : '' );
		$info .=
			( $arg{'socket'} || $arg{'host'} || $arg{'db'} )
		;
		$this->[$DB_LOGGER]->info(
			'Connecting to [' . $arg{'driver'} . '] ' . $info
		);
	}
	$this->[$DB_LINKID] = &{"${pkg}::db_connect"}( %arg );
	if( ! $this->[$DB_LINKID] ) {
		$LastError = $this->error();
		$LastErrno = $this->errno();
		&Carp::croak( $LastError ) if $this->[$DB_DIE];
		&Carp::carp( $LastError ) if $this->[$DB_WARN];
		return undef;
	}
	return $this;
}

sub close {
	my( $this ) = @_;
	my $pkg = $this->[$DB_PKG];
	if( $this->[$DB_LOGGER] ) {
		my $arg = $this->[$DB_ARGV];
		my $info = ( $arg->{'user'} ? $arg->{'user'} . '@' : '' );
		$info .=
			( $arg->{'socket'} || $arg->{'host'} || $arg->{'db'} )
		;
		$this->[$DB_LOGGER]->info(
			'Closing connection to [' . $arg->{'driver'} . '] ' . $info
		);
	}
	&{"$${pkg}::close"}( $this->[$DB_LINKID] ) or return 0;
	$this->[$DB_LINKID] = 0;
	return 1;
}

sub reconnect {
	my( $this ) = @_;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::reconnect"}( $this->[$DB_LINKID] );
}

sub clone {
	my( $this ) = @_;
	return PAB3::DB->connect( %{$this->[$DB_ARGV]} );
}

sub query {
	my( $this ) = @_;
	my( $pkg, $retval, $res, $ts );
	$pkg = $this->[$DB_PKG];
	if( $this->[$DB_LOGGER] ) {
		$this->[$DB_LOGGER]->send( 'SQL: ' . $_[1], 4 );
	}
	if( $PAB3::Statistic::VERSION ) {
		$ts = &microtime();
	}
	$this->[$DB_LASTQUERY] = $_[1];
	if( $GLOBAL::DEBUG ) {
		my $rt = &microtime();
		$retval = &{"$${pkg}::query"}( $this->[$DB_LINKID], $_[1] );
		$rt = &microtime() - $rt;
		$rt = sprintf( '%0.3f', $rt * 1000 );
		if( $PAB3::CGI::VERSION ) {
			print "<p><code>$_[1]\</code><br>"
				. "<i><font color=gray>($rt ms)</font></i></p>\n";
		}
		else {
			print "$_[1]\n($rt ms)\n";
		}
	}
	else {
		$retval = &{"$${pkg}::query"}( $this->[$DB_LINKID], $_[1] );
	}
	if( ! $retval ) {
		return &_set_db_error( $this );
	}
	if( $PAB3::Statistic::VERSION ) {
		&PAB3::Statistic::send( 'SQLQ|' . ( $GLOBAL::MPREQ || $$ )
			. '|' . time . '|' . $ts . '|' . &microtime() . '|' . $_[1]
		);
	}
	return 1 if $retval == 1;
	$res = $this->_create_item( 'PAB3::DB::RES_' );
	$res->[$DB_QUERYID] = $this->[$DB_QUERYID] = $retval;
	return $res;
}

sub prepare {
	my( $this ) = @_;
	my( $pkg, $stmtid, $stmt, $ts );
	$pkg = $this->[$DB_PKG];
	if( $this->[$DB_LOGGER] ) {
		$this->[$DB_LOGGER]->send( 'SQL: ' . $_[1], 4 );
	}
	if( $PAB3::Statistic::VERSION ) {
		$ts = &microtime();
	}
	$this->[$DB_LASTQUERY] = $_[1];
	if( $GLOBAL::DEBUG ) {
		my $rt = &microtime();
		$stmtid = &{"$${pkg}::prepare"}( $this->[$DB_LINKID], $_[1] );
		$rt = sprintf( '%0.3f', ( &microtime() - $rt ) * 1000 );
		if( $PAB3::CGI::VERSION ) {
			print "<p><code>$_[1]\</code><br>"
				. "<i><font color=gray>($rt ms)</font></i></p>\n";
		}
		else {
			print "$_[1]\n($rt ms)\n";
		}
	}
	else {
		$stmtid = &{"$${pkg}::prepare"}( $this->[$DB_LINKID], $_[1] );
	}
	if( ! $stmtid ) {
		return &_set_db_error( $this );
	}
	$stmt = $this->_create_item( 'PAB3::DB::STMT_' );
	$stmt->[$DB_QUERYID] = $stmtid;
	if( $PAB3::Statistic::VERSION ) {
		&PAB3::Statistic::send( 'SQLP|' . ( $GLOBAL::MPREQ || $$ )
			. '|' . time . '|' . $stmt . '|' . $ts . '|' . &microtime()
			. '|' . $_[1]
		);
	}
	return $stmt;
}

sub fetch_row {
	my( $this, $query_id ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::fetch_row"}( $query_id || $this->[$DB_QUERYID] );
}

sub fetch_col {
	my( $this, $query_id ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::fetch_col"}( $query_id || $this->[$DB_QUERYID] );
}

sub fetch_hash {
	my( $this, $query_id ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::fetch_hash"}( $query_id || $this->[$DB_QUERYID] );
}

sub num_rows {
	my( $this, $query_id ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::num_rows"}( $query_id || $this->[$DB_QUERYID] );
}

sub num_fields {
	my( $this, $query_id ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::num_fields"}( $query_id || $this->[$DB_QUERYID] );
}

sub fetch_names {
	my( $this, $query_id ) = @_;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::fetch_names"}( $query_id || $this->[$DB_QUERYID] );
}

sub fetch_lengths {
	my( $this, $query_id ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::fetch_lengths"}( $query_id || $this->[$DB_QUERYID] );
}

sub fetch_field {
	my( $this, $query_id, $offset ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::fetch_field"}( $query_id || $this->[$DB_QUERYID], $offset );
}

sub field_seek {
	my( $this, $query_id, $offset ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::field_seek"}( $query_id || $this->[$DB_QUERYID], $offset );
}

sub field_tell {
	my( $this, $query_id ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::field_tell"}( $query_id || $this->[$DB_QUERYID] );
}

sub row_seek {
	my( $this, $query_id, $offset ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::row_seek"}( $query_id || $this->[$DB_QUERYID], $offset );
}

sub row_tell {
	my( $this, $query_id ) = @_;
	my $pkg = $this->[$DB_PKG];
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	return &{"$${pkg}::row_tell"}( $query_id || $this->[$DB_QUERYID] );
}

sub quote {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::quote"}( $_[0] || '' );
}

sub quote_id {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::quote_id"}( @_ );
}

sub set_charset {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::set_charset"}( $this->[$DB_LINKID], $_[0] );
}

sub get_charset {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::get_charset"}( $this->[$DB_LINKID] );
}

sub insert_id {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::insert_id"}( $this->[$DB_LINKID], @_ );
}

sub affected_rows {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::affected_rows"}( $this->[$DB_LINKID] );
}

sub errno {
	my $this = shift;
	return $LastErrno if ! ref( $this );
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::errno"}( $this->[$DB_LINKID] ) || $this->[$DB_ERRNO];
}

sub error {
	my $this = shift;
	return $LastError if ! ref( $this );
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::error"}( $this->[$DB_LINKID] ) || $this->[$DB_ERROR];
}

sub auto_commit {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::auto_commit"}( $_[0], $this->[$DB_LINKID] );
}

sub begin_work {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::begin_work"}( $this->[$DB_LINKID] );
}

sub commit {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::commit"}( $this->[$DB_LINKID] );
}

sub rollback {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::rollback"}( $this->[$DB_LINKID] );
}

sub show_catalogs {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::show_catalogs"}( $this->[$DB_LINKID], $_[0] );
}

sub show_tables {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::show_tables"}(
		$this->[$DB_LINKID], $_[0], $_[1], $_[2]
	);
}

sub show_fields {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::show_fields"}(
		$this->[$DB_LINKID], $_[0], $_[1], $_[2], $_[3]
	);
}

sub show_index {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::show_index"}(
		$this->[$DB_LINKID], $_[0], $_[1], $_[2]
	);
}

sub show_drivers {
	my( $i, $search, $path, $dir, @files );
	$search = '/PAB3/DB/Driver/';
	for $i( 0 .. $#INC ) {
		if( -d $INC[$i] . $search ) {
			$path = $INC[$i] . $search;
			last;
		}
	}
	return undef if ! $path;
	opendir( $dir, $path );
	@files = grep { /\.pm$/i } readdir( $dir );
	closedir( $dir );
	s/(.+)\.pm$/$1/i foreach @files;
	return @files;
}

sub sql_limit {
	my $this = shift;
	#my( $sql, $limit, $offset ) = @_;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::sql_limit"}(
		$_[0], length( $_[0] ), $_[1], defined $_[2] ? $_[2] : -1
	);
}

sub sql_pre_calc_rows {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::sql_pre_calc_rows"}( @_ );
}

sub sql_calc_rows {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::sql_calc_rows"}( @_ );
}

sub microtime {
	my( $sec, $usec ) = &Time::HiRes::gettimeofday();
	return $sec + $usec / 1000000;
}

sub _create_item {
	my( $this, $class ) = @_;
	my $item = [];
	$item->[$DB_LINKID] = $this->[$DB_LINKID];
	$item->[$DB_PKG] = $this->[$DB_PKG];
	$item->[$DB_DIE] = $this->[$DB_DIE];
	$item->[$DB_WARN] = $this->[$DB_WARN];
	$item->[$DB_LOGGER] = $this->[$DB_LOGGER];
#	$item->[$DB_LASTQUERY] = $this->[$DB_LASTQUERY];
	bless( $item, $class );
	return $item;
}

sub _set_db_error {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	if( $_[0] ) {
		$this->[$DB_ERROR] = $_[0];
		$this->[$DB_ERRNO] = -1;
	}
	else {
		$this->[$DB_ERROR] = &{"$${pkg}::error"}( $this->[$DB_LINKID] );
		$this->[$DB_ERRNO] = &{"$${pkg}::errno"}( $this->[$DB_LINKID] );
	}
	if( $this->[$DB_ERROR] ) {
		&Carp::croak(
			'(Code ' . $this->[$DB_ERRNO] . ') ' . $this->[$DB_ERROR] )
				if $this->[$DB_DIE];
		&Carp::carp(
			'(Code ' . $this->[$DB_ERRNO] . ') ' . $this->[$DB_ERROR] )
				if $this->[$DB_WARN];
	}
	return $_[1];
}

package PAB3::DB::RES_;

BEGIN {
	*fetch_row = \&PAB3::DB::fetch_row;
	*fetch_array = \&PAB3::DB::fetch_row;
	*fetch_hash = \&PAB3::DB::fetch_hash;
	*fetch_lengths = \&PAB3::DB::fetch_lengths;
	*num_rows = \&PAB3::DB::num_rows;
	*row_seek = \&PAB3::DB::row_seek;
	*row_tell = \&PAB3::DB::row_tell;

	*fetch_names = \&PAB3::DB::fetch_names;
	*fetch_field = \&PAB3::DB::fetch_field;
	*num_fields = \&PAB3::DB::num_fields;
	*field_seek = \&PAB3::DB::field_seek;
	*field_tell = \&PAB3::DB::field_tell;

	*error = \&PAB3::DB::error;
	*errno = \&PAB3::DB::errno;
}

1;

sub DESTROY {
	my $this = shift or return;
	my $pkg = $this->[$DB_PKG];
	&{"$${pkg}::free_result"}( $this->[$DB_QUERYID] );
}


package PAB3::DB::STMT_;

BEGIN {
	our @ISA = qw(PAB3::DB::RES_);
	#*_set_db_error = \&PAB3::DB::_set_db_error;
}

1;

sub DESTROY {
	my $this = shift or return;
	my $pkg = $this->[$DB_PKG];
	&{"$${pkg}::free_result"}( $this->[$DB_QUERYID] );
}

sub bind_param {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::bind_param"}( $this->[$DB_QUERYID], @_ );
}

sub execute {
	my $this = shift;
	my( $pkg, $resid, $res, $ts );
	$pkg = $this->[$DB_PKG];
	#print "params: ", $this->[$DB_QUERYID], '|', join( '|', @_ ), "\n";
	if( $PAB3::Statistic::VERSION ) {
		$ts = &PAB3::DB::microtime();
	}
	$resid = &{"$${pkg}::execute"}( $this->[$DB_QUERYID], @_ );
	if( ! $resid ) {
		return &_set_db_error( $this );
	}
	if( $PAB3::Statistic::VERSION ) {
		&PAB3::Statistic::send( 'SQLE|' . ( $GLOBAL::MPREQ || $$ )
			. '|' . time . '|' . $this
			. '|'  . $ts . '|' . &PAB3::DB::microtime()
		);
	}
	return $this if $resid == $this->[$DB_QUERYID];
	$res = &PAB3::DB::_create_item( $this, 'PAB3::DB::RES_' );
	$res->[$DB_QUERYID] = $resid;
	return $res;
}

sub insert_id {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::insert_id"}( $this->[$DB_QUERYID], @_ );
}

sub affected_rows {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	return &{"$${pkg}::affected_rows"}( $this->[$DB_QUERYID] );
}

sub _set_db_error {
	my $this = shift;
	my $pkg = $this->[$DB_PKG];
	if( $_[0] ) {
		$this->[$DB_ERROR] = $_[0];
		$this->[$DB_ERRNO] = -1;
	}
	else {
		$this->[$DB_ERROR] = &{"$${pkg}::error"}( $this->[$DB_LINKID] );
		$this->[$DB_ERRNO] = &{"$${pkg}::errno"}( $this->[$DB_LINKID] );
	}
	if( $this->[$DB_ERROR] ) {
		&Carp::croak(
			'(Code ' . $this->[$DB_ERRNO] . ') ' . $this->[$DB_ERROR] )
				if $this->[$DB_DIE];
		&Carp::carp(
			'(Code ' . $this->[$DB_ERRNO] . ') ' . $this->[$DB_ERROR] )
				if $this->[$DB_WARN];
	}
	return $_[1];
}


__END__

=head1 NAME

PAB3::DB - Common interface for database communication

=head1 SYNOPSIS

  use PAB3::DB;
  
  $db = PAB3::DB->connect( %arg );
  
  $res = $db->query( $sql );
  
  $stmt = $db->prepare( $sql );
  $stmt->bind_param( $p_num, $value );
  
  $res = $stmt->execute();
  $res = $stmt->execute( @bind_values );
  
  @row = $res->fetch_row();
  @row = $stmt->fetch_row();
  
  @row = $res->fetch_array();
  @row = $stmt->fetch_array();
  
  %row = $res->fetch_hash();
  %row = $stmt->fetch_hash();
  
  @col = $res->fetch_col();
  @col = $stmt->fetch_col();
  
  @name = $res->fetch_names();
  @name = $stmt->fetch_names();
  
  @len = $res->fetch_lengths();
  @len = $stmt->fetch_lengths();
  
  $num_rows = $res->num_rows();
  $num_rows = $stmt->num_rows();
  
  $row_index = $res->row_tell();
  $row_index = $stmt->row_tell();
  
  $res->row_seek( $row_index );
  $stmt->row_seek( $row_index );
  
  $num_fields = $res->num_fields();
  $num_fields = $stmt->num_fields();
  
  $res->field_seek( $row_index );
  $stmt->field_seek( $row_index );
  
  @field = $res->fetch_field();
  @field = $stmt->fetch_field();
  
  $hr = $db->begin_work();
  $hr = $db->commit();
  $hr = $db->rollback();
  
  $str   = $db->error();
  $errno = $db->errno();
  
  $hr = $db->set_charset( $charset );
  $charset = $db->get_charset();
  
  $quoted = $db->quote( $arg );
  $quoted = $db->quote_id( ... );
  
  # for query method
  $uv = $db->insert_id();
  $uv = $db->insert_id( $field );
  $uv = $db->insert_id( $field, $table );
  $uv = $db->insert_id( $field, $table, $schema );
  
  # for execute method
  $uv = $stmt->insert_id();
  $uv = $stmt->insert_id( $field );
  $uv = $stmt->insert_id( $field, $table );
  $uv = $stmt->insert_id( $field, $table, $schema );
  
  @drivers = PAB3::DB->show_drivers();
  
  @catalogs = $db->show_catalogs();
  @catalogs = $db->show_catalogs( $wild );
  
  @tables = $db->show_tables();
  @tables = $db->show_tables( $schema );
  @tables = $db->show_tables( $schema, $catalog );
  @tables = $db->show_tables( $schema, $catalog, $wild );
  
  @fields = $db->show_fields( $table );
  @fields = $db->show_fields( $table, $schema );
  @fields = $db->show_fields( $table, $schema, $catalog );
  @fields = $db->show_fields( $table, $schema, $catalog, $wild );
  
  @index = $db->show_index( $table );
  @index = $db->show_index( $table, $schema );
  @index = $db->show_index( $table, $schema, $catalog );
  
  $rv = $db->reconnect();
  
  $rv = $db->close();

=head1 DESCRIPTION

PAB3::DB provides an interface for database communication.

SQL statements can be submitted in two different ways, with 'query' method or
with 'prepare' and 'execute' methods.
The 'query' method is more simple and should run faster for a single call.
The 'prepare' and 'execute' methods are more secure and can speed up the
execution time if 'execute' is called more times on the same statement. It
also makes available sending binary data to along with the statement.

Most functions may be used in different ways. The documentation uses the
following variables to define different classes.
I<$db> defines a database class, I<$res> defines a result class and I<$stmt>
defines a statement class. 

=head2 EXAMPLES

=head3 Using "query" method

  use PAB3::DB;
  
  $db = PAB3::DB->connect(
      'driver' => 'Mysql',
      'host' => 'localhost',
      'user' => 'root',
      'auth' => '',
      'db' => 'test',
  );
  
  $db->set_charset( 'utf8' );
  
  $res = $db->query( 'select * from table' );
  
  @names = $res->fetch_names();
  print join( '|', @names ), "\n";
  
  while( @row = $res->fetch_row() ) {
      print join( '|', @row ), "\n";
  }


=head3 Using "prepare" and "execute" methods

  use PAB3::DB;
  
  $db = PAB3::DB->connect(
      'driver' => 'Mysql',
      'host' => 'localhost',
      'user' => 'root',
      'auth' => '',
      'db' => 'test',
  );
  
  $db->set_charset( 'utf8' );
  
  $stmt = $db->prepare( 'select * from table where field = ?' );
  # bind "foo" to parameter 1 and execute
  $res = $stmt->execute( 'foo' );
  
  @names = $res->fetch_names();
  print join( '|', @names ), "\n";
  
  while( @row = $res->fetch_row() ) {
      print join( '|', @row ), "\n";
  }


=head1 METHODS

=head2 Connection Control Methods

=over 2

=item $db = connect ( %arg )

=item $db = new ( %arg )

Opens a connection to a database server and returns a new class.

B<Parameters>

I<%arg>

A combination of the following parameters:

  driver     => drivername, default is Mysql
  host       => database server
  user       => authorized username
  auth       => authorization password
  db         => database
  port       => port for tcp/ip connection
  options    => hashref with driver specific options, like {reconnect => 1}
  warn       => warns on error, default is ON
  die        => dies on error, default is ON

A concrete definition of these and additional parameters could by found in the
drivers documentation.

B<Return Values>

Returns a PAB3::DB class (I<$db>) on success or FALSE on failure. 

B<Examples>

  # loading the driver on startup will speed up the connection process
  # use PAB3::DB::Driver::Postgres ();
  
  $db = PAB3::DB->connect(
      'driver' => 'Postgres',
      'host' => 'localhost',
      'user' => 'postgres',
      'auth' => 'postgres',
      'db' => 'mydb',
  );


=item $db -> reconnect ()

Reconnect to the database server.


=item $db -> close ()

Closes the currently active connection


=item $db -> set_charset ( $charset )

Sets the default character set to be used when sending data from and to the
database server.

B<Parameters>

I<$charset>

The charset to be set as default.

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item $db -> get_charset ()

Gets the default character.

B<Return Values>

Returns the default charset or NULL on error.


=item $db -> errno ()

Returns the last error code for the most recent function call that can
succeed or fail.

B<Return Values>

An error code value for the last call, if it failed. zero means no error
occurred.


=item $db -> error ()

Returns the last error message for the most recent function call that can
succeed or fail.

B<Return Values>

A string that describes the error. An empty string if no error occurred.


=back

=head2 Command Execution Methods

=over 2

=item $res = $db -> query ( $statement )

Sends a SQL statement to the currently active database on the server. 

B<Parameters>

I<$statement>

The query, as a string. 

B<Return Values>

For selectives queries query() returns a result class (I<$res>) on success,
or FALSE on error. 

For other type of SQL statements, UPDATE, DELETE, DROP, etc,
query() returns TRUE on success or FALSE on error. 


=item $stmt = $db -> prepare ( $statement )

Prepares the SQL query pointed to by the null-terminated string query, and
returns a statement handle to be used for further operations on the statement.
The query must consist of a single SQL statement. 

B<Parameters>

I<$statement>

The query, as a string. 

This parameter can include one or more parameter markers in the SQL statement
by embedding question mark (?) characters at the appropriate positions. 

B<Return Values>

Returns a statement class (I<$stmt>) or FALSE if an error occured.

B<See Also>

L<execute()|PAB3::DB/execute>, L<bind_param()|PAB3::DB/bind_param>

=item $stmt -> bind_param ( $p_num )

=item $stmt -> bind_param ( $p_num, $value )

=item $stmt -> bind_param ( $p_num, $value, $type )

Binds a value to a prepared statement as parameter

B<Parameters>

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


=item $res = $stmt -> execute ()

=item $res = $stmt -> execute ( @bind_values )

Executes a query that has been previously prepared using the prepare() function.
When executed any parameter markers which exist will automatically be replaced
with the appropiate data. 

B<Parameters>

I<@bind_values>

An array of values to bind. Values bound in this way are usually treated as
"string" types unless the driver can determine the correct type, or unless
bind_param() has already been used to specify the type.

B<Return Values>

For SELECT, SHOW, DESCRIBE, EXPLAIN and other statements returning resultset,
query returns a result class (I<$res>) on success, or FALSE on error. 
The result class is bound to the statement. If the result class is not used,
it will be freed when the statement is freed. Some drivers do not support
different results in a statement. In this case the return value could be
the statement class.

For other type of SQL statements, UPDATE, DELETE, DROP, etc, query returns
TRUE on success or FALSE on error. 


=back

=head3 Retrieving Query Result Information

=over 2

=item $db -> affected_rows ()

=item $stmt -> affected_rows ()

Gets the number of affected rows in a previous SQL operation
After executing a statement with L<query()|PAB3::DB/query> or
L<execute()|PAB3::DB/execute>, returns the number
of rows changed (for UPDATE), deleted (for DELETE), or inserted (for INSERT).
For SELECT statements, affected_rows() works like
L<num_rows()|PAB3::DB/num_rows>. 

B<Return Values>

An integer greater than zero indicates the number of rows affected or retrieved.
Zero indicates that no records where updated for an UPDATE statement,
no rows matched the WHERE clause in the query or that no query has yet
been executed.


=item $db -> insert_id ()

=item $db -> insert_id ( $field )

=item $db -> insert_id ( $field, $table )

=item $db -> insert_id ( $field, $table, $schema )

=item $db -> insert_id ( $field, $table, $schema, $catalog )

=item $stmt -> insert_id ()

=item $stmt -> insert_id ( $field )

=item $stmt -> insert_id ( $field, $table )

=item $stmt -> insert_id ( $field, $table, $schema )

=item $stmt -> insert_id ( $field, $table, $schema, $catalog )

Returns the auto generated id used in the last query or statement. 

B<Parameters>

I<$field>

The field to retrieve the generated id from.

I<$table>

The table where the field is located.

I<$schema>

The schema where the table is located.

I<$catalog>

The catalog where the table is located.

B<Return Values>

The value of an AUTO_INCREMENT (IDENDITY,SERIAL) field that was updated by the
previous query.
Returns NULL if there was no previous query on the connection or if the query
did not update an AUTO_INCREMENT value. 


=back

=head4 Accessing Rows in a Result Set

=over 2

=item $res -> fetch_row ()

=item $res -> fetch_array ()

=item $stmt -> fetch_row ()

=item $stmt -> fetch_array ()

Get a result row as an enumerated array.
fetch_array() is a synonym for fetch_row().

B<Paramters>

None

B<Return Values>

Returns an array of values that corresponds to the fetched row or NULL if there
are no more rows in result set.


=item $res -> fetch_hash ()

=item $stmt -> fetch_hash ()

Fetch a result row as an associative array (hash).

B<Paramters>

None

B<Return Values>

Returns an associative array (hash) of values representing the fetched row in
the result set, where each key in the hash represents the name of one of the
result set's columns or NULL if there are no more rows in resultset. 

If two or more columns of the result have the same field names, the last
column will take precedence. To access the other columns of the same name,
you either need to access the result with numeric indices by using
L<fetch_row()|PAB3::DB/fetch_row> or add alias names.


=item $res -> fetch_col ()

=item $stmt -> fetch_col ()

Fetch the first column of each row in the result set a an array.

B<Paramters>

None

B<Return Values>

Returns an array of values that corresponds to the first column of each row
in the result set or FALSE if no data is available.


=item $res -> fetch_lengths ()

=item $res -> fetch_lengths ()

Returns the lengths of the columns of the current row in the result set.

B<Paramters>

None

B<Return Values>

An array of integers representing the size of each column (not including
terminating null characters). FALSE if an error occurred.


=item $res -> num_rows ()

=item $stmt -> num_rows ()

Gets the number of rows in a result.

B<Paramters>

None

B<Return Values>

Returns number of rows in the result set.


=item $res -> row_tell ()

=item $res -> row_tell ()

Gets the actual position of row cursor in a result (Starting at 0).

B<Paramters>

None

B<Return Values>

Returns the actual position of row cursor in a result.


=item $res -> row_seek ( $offset )

=item $stmt -> row_seek ( $offset )

Sets the actual position of row cursor in a result (Starting at 0).

B<Paramters>

I<$offset>

Absolute row position. Valid between 0 and L<num_rows()|PAB3::DB/num_rows> - 1.

B<Return Values>

Returns the previous position of row cursor in a result.


=back

=head4 Accessing Fields (Columns) in a Result Set

=over 2

=item $res -> fetch_names ()

=item $stmt -> fetch_names ()

Returns an array of field names representing in a result set.

B<Paramters>

None

B<Return Values>

Returns an array of field names or FALSE if no field information is available. 


=item $res -> num_fields ()

=item $stmt -> num_fields ()

Gets the number of fields (columns) in a result.

B<Paramters>

None

B<Return Values>

Returns number of fields in the result set.


=item $res -> fetch_field ()

=item $res -> fetch_field ( $offset )

=item $stmt -> fetch_field ()

=item $stmt -> fetch_field ( $offset )

Returns the next field in the result.

B<Paramters>

I<$offset>

If set, moves the field cursor to this position.

B<Return Values>

Returns a hash which contains field definition information or FALSE if no
field information is available. 


=item $res -> field_tell ()

=item $stmt -> field_tell ()

Gets the actual position of field cursor in a result (Starting at 0).

B<Paramters>

None

B<Return Values>

Returns the actual position of field cursor in the result.


=item $res -> field_seek ( $offset )

=item $stmt -> field_seek ( $offset )

Sets the actual position of field cursor in the result (Starting at 0).

B<Paramters>

I<$offset>

Absolute field position. Valid between 0 and
L<num_fields()|PAB3::DB/num_fields> - 1.

B<Return Values>

Returns the previous position of field cursor in the result.


=back

=head3 Freeing Results or Statements

Results and Statements will freed when its classes are destroying.
To free I<$res> or I<$stmt>, just undefine the variables.

Example

  $res = $db->query( 'select 1' );
  # free the result
  undef $res;

=head2 Transaction Methods

=over 2

=item $db -> auto_commit ( $mode )

Turns on or off auto-commit mode on queries for the database connection.

B<Parameters>

I<$mode>

Whether to turn on auto-commit or not.

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item $db -> begin_work ()

Turns off auto-commit mode for the database connection until transaction
is finished.

B<Parameters>

None

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item $db -> commit ()

Commits the current transaction for the database connection.

B<Parameters>

None

B<Return Values>

Returns TRUE on success or FALSE on failure.


=item $db -> rollback ()

Rollbacks the current transaction for the database.

B<Parameters>

None

B<Return Values>

Returns TRUE on success or FALSE on failure.

=back

=head2 Information Retrieval Functions

=over 2

=item show_drivers ()

Returns an array with names of drivers found.

Example

  @drivers = PAB3::DB->show_drivers();


=item $db -> show_catalogs ()

=item $db -> show_catalogs ( $wild )

Gets an array with names of catalogs found.

B<Parameters>

I<$wild>

The argument may accept search patterns according to the database/driver, for
example: $wild = '%FOO%'.

B<Return Values>

An array with names of catalogs.


=item $db -> show_tables ()

=item $db -> show_tables ( $schema )

=item $db -> show_tables ( $schema, $catalog )

=item $db -> show_tables ( $schema, $catalog, $type )

Gets an array with information about tables and views that exist in the
database.

B<Parameters>

I<$schema>

The schema to search in.

I<$catalog>

The catalog to search in.

I<$type>

The value of $type is a comma-separated list of one or more types of tables to
be returned in the result set.

  $type = 'table';
  $type = 'table,view';

B<Return Values>

An array with information about tables and views.

The array should contain the following fields in the order shown below.

  TABLE | SCHEMA | CATALOG | TYPE

B<TABLE>

Name of the table (or view, synonym, etc).

B<SCHEMA>

The name of the schema containing the TABLE value. This field can be NULL if
not applicable.

B<CATALOG>

Table catalog identifier. This field can be NULL if not applicable.

B<TYPE>

One of the following: "table", "view" or a type identifier that is specific to
the data source.


=item $db -> show_fields ( $table )

=item $db -> show_fields ( $table, $schema )

=item $db -> show_fields ( $table, $schema, $catalog )

=item $db -> show_fields ( $table, $schema, $catalog, $field )

Gets an array with information about fields (columns) in a specified table.

B<Parameters>

I<$table>

The table to search in.

I<$schema>

The schema to search in.

I<$catalog>

The catalog to search in.

I<$field>

The value of I<$field> may accept search patterns according to the
database/driver, for example: $field = '%FOO%';

B<Return Values>

An array with information about fields in the specified table.

The array should contain the following fields in the order shown below.

  COLUMN | NULLABLE | DEFAULT | IS_PRIMARY | IS_UNIQUE | TYPENAME | AUTOINC

B<COLUMN>

The field identifier.

B<NULLABLE>

Indicates that the field does accept 'NULL'.

B<DEFAULT>

The default value of the column.

B<IS_PRIMARY>

Indicates that the field is part of the primary key.

B<IS_UNIQUE>

Indicates that the field is part of a unique key.

B<TYPENAME>

A data source dependent data type name.

B<AUTOINC>

Indicates that the field will automatically be incremented.


=item $db -> show_index ( $table )

=item $db -> show_index ( $table, $schema )

=item $db -> show_index ( $table, $schema, $catalog )

Gets an array with information about indexes (keys) in a specified table.

B<Parameters>

I<$table>

The table to search in.

I<$schema>

The schema to search in.

I<$catalog>

The catalog to search in.

B<Return Values>

An array with information about indexes in the specified table.

The array should contain the following fields in the order shown below.

  NAME | COLUMN | TYPE

B<NAME>

The name of the index.

B<COLUMN>

The field identifier.

B<TYPE>

The type of the key. Possible values are:

  1 - Primary key
  2 - Unique key
  3 - Other Index

=back

=head2 Other Functions

=over 2

=item $db -> quote ( $value )

Quote a value for use as a literal value in an SQL statement,
by escaping any special characters (such as quotation marks) contained within
the string and adding the required type of outer quotation marks.

The quote() method should not be used with "Placeholders and Bind Values".

B<Parameters>

I<$value>

Value to be quoted.

B<Return Values>

The quoted value with adding the required type of outer quotation marks.

B<Examples>

  $s = $db->quote( "It's our time" );
  # $s should be something like this: 'It''s our time'

=item $db -> quote_id ( $field )

=item $db -> quote_id ( $table, $field )

=item $db -> quote_id ( $schema, $table, $field )

=item $db -> quote_id ( $catalog, $schema, $table, $field )

Quote an identifier (table name etc.) for use in an SQL statement, by escaping
any special characters it contains and adding the required type of outer
quotation marks.

B<Parameters>

One or more values to be quoted.

B<Return Values>

The quoted string with adding the required type of outer quotation marks.

B<Examples>

  # using driver 'Postgres'
  
  $s = $db->quote_id( 'table' );
  # $s should be "table"
  
  $s = $db->quote_id( 'table', 'field' );
  # $s should be "table"."field"
  
  $s = $db->quote_id( 'table', '*' );
  # $s should be "table".*


=back

=head1 SEE ALSO

For additional database functions look at L<PAB3::DB::Max>.

=head1 AUTHORS

Christian Mueller <christian_at_hbr1.com>

=head1 COPYRIGHT

The PAB3::DB module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=cut

