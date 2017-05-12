package PAB3::DB::Max;
# =============================================================================
# Perl Application Builder
# Module: PAB3::DB::Max
# Additional functionality to PAB3::DB
# =============================================================================
use strict;

use vars qw($VERSION);

use PAB3::DB ();

BEGIN {
	$VERSION = $PAB3::DB::VERSION;
}

package PAB3::DB;

no strict 'refs';
no strict 'vars';

BEGIN {
	*fetchrow_array = \&fetch_row;
	*fetchrow_hash = \&fetch_hash;
}

1;

sub fetchall_hashref {
	my( $this, $key ) = @_;
	my( @row, @names, %names, @key, $pkg, $i, @index, $ref, $rows, $query_id );
	$query_id = $this->[$DB_QUERYID];
	$pkg = $this->[$DB_PKG];
	@key = ref( $key ) ? @$key : ( $key );
	@names = &{"$${pkg}::fetch_names"}( $query_id )
		or return $this->_set_db_error();
	$i = 0;
	%names = map{ $_ => $i ++ } @names;
	foreach( @key ) {
		$i = $names{$_};
		if( ! defined $i ) {
			return $this->_set_db_error(
				"Field '$_' does not exist (not one of @names)"
			);
		}
		push @index, $i;
	}
	$rows = {};
	&{"$${pkg}::row_seek"}( $query_id, 0 );
	while( @row = &{"$${pkg}::fetch_row"}( $query_id ) ) {
	    $ref = $rows;
	    $ref = $ref->{$row[$_]} ||= {} foreach @index;
	    @{$ref}{@names} = @row;
	}
	return $rows;
}

sub fetchall_arrayref {
	my( $this ) = @_;
	my( $pkg, @rows, $i, $query_id );
	$query_id = $this->[$DB_QUERYID];
	@rows = ();
	$pkg = $this->[$DB_PKG];
	&{"$${pkg}::row_seek"}( $query_id, 0 );
	$i = 0;
	if( ref( $_[1] ) eq 'HASH' ) {
		my %row;
		while( %row = &{"$${pkg}::fetch_hash"}( $query_id ) ) {
			push @rows, { %row };
			$i ++;
		}
	}
	else {
		my @row;
		while( @row = &{"$${pkg}::fetch_row"}( $query_id ) ) {
			push @rows, [ @row ];
			$i ++;
		}
	}
	return $i ? \@rows : undef;
}

sub fetchrow_hashref {
	my( $this, $query_id ) = @_;
	my( $pkg, %row );
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	$query_id ||= $this->[$DB_QUERYID];
	$pkg = $this->[$DB_PKG];
	%row = &{"$${pkg}::fetch_hash"}( $query_id ) or return undef;
	return \%row;
}

sub fetchrow_arrayref {
	my( $this, $query_id ) = @_;
	my( $pkg, @row );
	$query_id = $query_id->[$DB_QUERYID] if ref( $query_id );
	$query_id ||= $this->[$DB_QUERYID];
	$pkg = $this->[$DB_PKG];
	@row = &{"$${pkg}::fetch_row"}( $query_id ) or return undef;
	return \@row;
}

sub selectrow_array {
	my( $this, $sql ) = ( shift, shift );
	my( $pkg, @row, $res, $stmt );
	$pkg = $this->[$DB_PKG];
	if( @_ ) {
		$stmt = $this->prepare( $sql )
			or return undef;
		$res = $stmt->execute( @_ )
			or return undef;
	}
	else {
		$res = $this->query( $sql )
			or return undef;
	}
	return &{"$${pkg}::fetch_row"}( $res->[$DB_QUERYID] );
}

sub selectrow_arrayref {
	my( $this, $sql ) = ( shift, shift );
	my( $pkg, @row, $res, $stmt );
	$pkg = $this->[$DB_PKG];
	if( @_ ) {
		$stmt = $this->prepare( $sql )
			or return undef;
		$res = $stmt->execute( @_ )
			or return undef;
	}
	else {
		$res = $this->query( $sql )
			or return undef;
	}
	return &{"$${pkg}::fetch_row"}( $res->[$DB_QUERYID] );
}

sub selectrow_hash {
	my( $this, $sql ) = ( shift, shift );
	my( $pkg, $query_id, %row, $res, $stmt );
	$pkg = $this->[$DB_PKG];
	if( @_ ) {
		$stmt = $this->prepare( $sql )
			or return undef;
		$res = $stmt->execute( @_ )
			or return undef;
	}
	else {
		$res = $this->query( $sql )
			or return undef;
	}
	return &{"$${pkg}::fetch_hash"}( $res->[$DB_QUERYID] );
}

sub selectrow_hashref {
	my( $this, $sql ) = ( shift, shift );
	my( $pkg, %row, $res, $stmt );
	$pkg = $this->[$DB_PKG];
	if( @_ ) {
		$stmt = $this->prepare( $sql )
			or return undef;
		$res = $stmt->execute( @_ )
			or return undef;
	}
	else {
		$res = $this->query( $sql )
			or return undef;
	}
	%row = &{"$${pkg}::fetch_hash"}( $res->[$DB_QUERYID] ) or return undef;
	return \%row;
}

sub selectall_arrayref {
	my( $this, $sql ) = ( shift, shift );
	my( $res, $rows, $stmt, $st1 );
	$st1 = shift if ref( $_[0] );
	if( @_ ) {
		$stmt = $this->prepare( $sql )
			or return undef;
		$res = $stmt->execute( @_ )
			or return undef;
	}
	else {
		$res = $this->query( $sql )
			or return undef;
	}
	return $res->fetchall_arrayref( $st1 );
}

sub selectall_hashref {
	my( $this, $sql, $key ) = ( shift, shift, shift );
	my( $res, $rows, $stmt );
	if( @_ ) {
		$stmt = $this->prepare( $sql )
			or return undef;
		$res = $stmt->execute( @_ )
			or return undef;
	}
	else {
		$res = $this->query( $sql )
			or return undef;
	}
	return $res->fetchall_hashref( $key );
}

sub selectcol_arrayref {
	my( $this, $sql ) = ( shift, shift );
	my( $res, @col, $stmt );
	if( @_ ) {
		$stmt = $this->prepare( $sql )
			or return undef;
		$res = $stmt->execute( @_ )
			or return undef;
	}
	else {
		$res = $this->query( $sql )
			or return undef;
	}
	@col = $res->fetch_col( $res ) or return undef;
	return \@col;
}

package PAB3::DB::RES_;

BEGIN {
	*fetchall_arrayref = \&PAB3::DB::fetchall_arrayref;
	*fetchall_hashref = \&PAB3::DB::fetchall_hashref;
	*fetchrow_arrayref = \&PAB3::DB::fetchrow_arrayref;
	*fetchrow_hashref = \&PAB3::DB::fetchrow_hashref;
	*fetchrow_array = \&PAB3::DB::fetch_row;
	*fetchrow_hash = \&PAB3::DB::fetch_hash;
}

__END__

=head1 NAME

PAB3::DB::Max - Additional functions to PAB3::DB

=head1 SYNOPSIS

  use PAB3::DB::Max;
  
  $data = $res->fetchall_arrayref();
  $data = $res->fetchall_arrayref( {} );
  $data = $stmt->fetchall_arrayref();
  $data = $stmt->fetchall_arrayref( {} );
  
  $data = $res->fetchall_hashref( $key );
  $data = $stmt->fetchall_hashref( $key );
  
  @row = $res->fetchrow_array();
  @row = $stmt->fetchrow_array();
  
  %row = $res->fetchrow_hash();
  %row = $stmt->fetchrow_hash();
  
  $row = $res->fetchrow_arrayref();
  $row = $stmt->fetchrow_arrayref();
  
  $row = $res->fetchrow_hashref();
  $row = $stmt->fetchrow_hashref();
  
  $data = $db->selectall_arrayref( $statement );
  $data = $db->selectall_arrayref( $statement, @bind_values );
  $data = $db->selectall_arrayref( $statement, {} );
  $data = $db->selectall_arrayref( $statement, {}, @bind_values );
  
  $data = $db->selectall_hashref( $statement, $key );
  $data = $db->selectall_hashref( $statement, $key, @bind_values );
  
  @row = $db->selectrow_array( $statement );
  @row = $db->selectrow_array( $statement, @bind_values );
  
  $row = $db->selectrow_arrayref( $statement );
  $row = $db->selectrow_arrayref( $statement, @bind_values );
  
  %row = $db->selectrow_hash( $statement );
  %row = $db->selectrow_hash( $statement, @bind_values );
  
  $row = $db->selectrow_hashref( $statement );
  $row = $db->selectrow_hashref( $statement, @bind_values );


=head1 DESCRIPTION

C<PAB3::DB::Max> provides additional functions to L<PAB3::DB|PAB3::DB>.
Once it has been loaded all functions becomes available to I<PAB3::DB>. 

=head2 EXAMPLES

  use PAB3::DB::Max;
  
  $db = PAB3::DB->connect( ... );
  
  $row = $db->selectrow_hashref( 'select * from table' );
  print $row->{'foo'}, "\n";

=head1 METHODS

=over 2

=item $res -> fetchrow_array ()

=item $stmt -> fetchrow_array ()

fetchrow_array() is a synonym for L<fetch_row()|PAB3::DB/fetch_row>


=item $res -> fetchrow_hash ()

=item $stmt -> fetchrow_hash ()

fetchrow_hash() is a synonym for L<fetch_hash()|PAB3::DB/fetch_hash>


=item $res -> fetchrow_arrayref ()

=item $stmt -> fetchrow_arrayref ()

Fetches the next row of data and returns a reference to an array holding the
field values or NULL if there are no more rows in result set. Null fields are
returned as undef values in the array.


=item $res -> fetchrow_hashref ()

=item $stmt -> fetchrow_hashref ()

Fetches the next row of data and returns it as a reference to a hash containing
field name and field value pairs or NULL if there are no more rows in result
set. Null fields are returned as undef values in the hash.


=item $res -> fetchall_arrayref ()

=item $res -> fetchall_arrayref ( {} )

=item $stmt -> fetchall_arrayref ()

=item $stmt -> fetchall_arrayref ( {} )

Fetch all the data to be returned from a result or statement.

B<Parameters>

I<{}>

Fetch all fields of every row as a hash ref.

B<Return Values>

It returns a reference to an array that contains one reference per row or NULL
if there is no data.


=item $res -> fetchall_hashref ( $key )

=item $stmt -> fetchall_hashref ( $key )

Fetch all the data to be returned from a result or statement class as a
reference to a hash containing a key for each distinct value of the I<$key>
column that was fetched.

B<Parameters>

I<$key>

Provides the name of the field that holds the value to be used for the key for
the returned hash. For example:

  $res = $db->query( 'select id, name from table' );
  $data = $res->fetchall_hashref( 'id' );
  # print name of id = 2
  print $data->{2}->{'name'};

For queries returing more than one 'key' column, you can specify multiple column
names by passing I<$key> as a reference to an array containing one or more key
column names. For example:

  $res = $db->query( 'select id1, id2, name from table' );
  $data = $res->fetchall_hashref( [ qw(id1 id2) ] );
  # print name of id1 = 2 and id2 = 10
  print $data->{2}->{10}->{'name'};


=item $db -> selectrow_array ( $statement )

=item $db -> selectrow_array ( $statement, @bind_values )

If I<@bind_values> are not used, this method combines
L<query()|PAB3::DB/query> and
L<fetchrow_array()|PAB3::DB::Max/fetchrow_array> into a single call.

If I<@bind_values> are used, it combines L<prepare()|PAB3::DB/prepare>,
L<execute()|PAB3::DB/execute> and L<fetchrow_array()|PAB3::DB::Max/fetchrow_array>.


=item $db -> selectrow_hash ( $statement )

=item $db -> selectrow_hash ( $statement, @bind_values )

If I<@bind_values> are not used, this method combines
L<query()|PAB3::DB/query> and L<fetchrow_hash()|PAB3::DB::Max/fetchrow_hash>
into a single call.

If I<@bind_values> are used, it combines L<prepare()|PAB3::DB/prepare>,
L<execute()|PAB3::DB/execute> and L<fetchrow_hash()|PAB3::DB::Max/fetchrow_hash>.


=item $db -> selectrow_arrayref ( $statement )

=item $db -> selectrow_arrayref ( $statement, @bind_values )

If I<@bind_values> are not used, this method combines
L<query()|PAB3::DB/query> and
L<fetchrow_arrayref()|PAB3::DB::Max/fetchrow_arrayref> into a single call.

If I<@bind_values> are used, it combines L<prepare()|PAB3::DB/prepare>,
L<execute()|PAB3::DB/execute> and
L<fetchrow_arrayref()|PAB3::DB::Max/fetchrow_arrayref>.


=item $db -> selectrow_hashref ( $statement )

=item $db -> selectrow_hashref ( $statement, @bind_values )

If I<@bind_values> are not used, this method combines
L<query()|PAB3::DB/query> and
L<fetchrow_hashref()|PAB3::DB::Max/fetchrow_hashref> into a single call.

If I<@bind_values> are used, it combines L<prepare()|PAB3::DB/prepare>,
L<execute()|PAB3::DB/execute> and
L<fetchrow_hashref()|PAB3::DB::Max/fetchrow_hashref>.


=item $db -> selectall_arrayref ( $statement )

=item $db -> selectall_arrayref ( $statement, {} )

=item $db -> selectall_arrayref ( $statement, @bind_values )

=item $db -> selectall_arrayref ( $statement, {}, @bind_values )

If I<@bind_values> are not used, this method combines
L<query()|PAB3::DB/query> and
L<fetchall_arrayref()|PAB3::DB::Max/fetchall_arrayref> into a single call.

If I<@bind_values> are used, it combines L<prepare()|PAB3::DB/prepare>,
L<execute()|PAB3::DB/execute> and
L<fetchall_arrayref()|PAB3::DB::Max/fetchall_arrayref>.


=item $db -> selectall_arrayref ( $statement, $key )

=item $db -> selectall_arrayref ( $statement, $key, @bind_values )

If I<@bind_values> are not used, this method combines
L<query()|PAB3::DB/query> and
L<fetchall_hashref()|PAB3::DB::Max/fetchall_hashref> into a single call.

If I<@bind_values> are used, it combines L<prepare()|PAB3::DB/prepare>,
L<execute()|PAB3::DB/execute> and
L<fetchall_hashref()|PAB3::DB::Max/fetchall_hashref>.

=back

=head1 SEE ALSO

Interface for database communication L<PAB3::DB|PAB3::DB>.

=head1 AUTHORS

Christian Mueller <christian_at_hbr1.com>

=head1 COPYRIGHT

The PAB3::DB module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=cut
