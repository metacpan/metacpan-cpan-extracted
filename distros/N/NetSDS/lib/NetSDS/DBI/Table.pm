#===============================================================================
#
#         FILE:  Table.pm
#
#  DESCRIPTION:  NetSDS::DBI::Table - CRUD implementation for NetSDS
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  25.07.2008 01:06:46 EEST
#===============================================================================

=head1 NAME

NetSDS::DBI::Table

=head1 SYNOPSIS

	use NetSDS::DBI::Table;

	my $q = NetSDS::DBI::Table->new(
		dsn    => 'dbi:Pg:dbname=netsdsdb;host=127.0.0.1',
		user   => 'netsds',
		passwd => 'test',
		table  => 'public.messages',
	) or warn NetSDS::DBI::Table->errstr();


=head1 DESCRIPTION

C<NetSDS::DBI::Table> module provides commonly used CRUD functionality for
data stored in single database.

Main idea was that we can agree about some limitations:

* every such table contains C<id> field that is primary key

* we use PostgreSQL DBMS with all it's features

=cut

package NetSDS::DBI::Table;

use 5.8.0;
use strict;
use warnings;

use base 'NetSDS::DBI';

use version; our $VERSION = '1.301';

#===============================================================================
#

=head1 CLASS API

=over

=item B<new([...])> - class constructor

	my $tbl = NetSDS::DBI::Table->new(
		dsn => 'dbi:Pg:dbname=content',
		login => 'netsds',
		passwd => 'topsecret,
		table => 'content.meta',
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	# Initialize base DBMS connector
	my $self = $class->SUPER::new(%params);

	# Set table name
	if ( $params{table} ) {
		$self->{table} = $params{table};
	} else {
		return $class->error('Table name is not specified to NetSDS::DBI::Table');
	}

	# 'fields' paramter is hash reference describing supported/allowed fields
	if ( $params{fields} ) {
	}

	return $self;

} ## end sub new

#***********************************************************************

=item B<fetch(%params)> - get records from table as array of hashrefs

Paramters (hash):

* fields - fetch fields by list

* filter - arrayref of SQL expressions like C<status = 'active'> for C<WHERE> clause

* order - arrayref of SQL expressions like C<id desc> for C<ORDER BY> clause

* limit - max number of records to fetch (LIMIT N)

* offset - records to skip from beginning (OFFSET N)

* for_update - records selected for further update within current transaction

Returns: message as array of hashrefs

Sample:

	my @messages = $q->fetch(
		fields => ['id', 'now() as time'],
		filter => ['msg_status = 5', 'date_received < now()'], # where msg_status=5 and date_received < now()
		order  => ['id desc', 'src_addr'], # order by id desc, src_addr
		limit => 3, # fetch 3 records
		offset => 5, # from 6-th record
		for_update => 1, # for update
	)

=cut 

#-----------------------------------------------------------------------

sub fetch {

	my ( $self, %params ) = @_;

	# Prepare expected fields list
	my $req_fields = $params{fields} ? join( ',', @{ $params{fields} } ) : '*';

	# Set default filter
	my $default_filter = $self->{default_filter} ? " where " . join( " and ", @{ $self->{default_filter} } ) : '';

	# Prepare WHERE filter
	my $req_filter = ($params{filter} and grep { $_ } @{ $params{filter} }) ? 
		" where " . join( " and ", grep { $_ } @{ $params{filter} } ) : $default_filter;

	# Prepare results order
	my $req_order = $params{order} ? " order by " . join( ", ", @{ $params{order} } ) : '';

	# Set limit and offset for fetching
	my $req_limit  = $params{limit}  ? " limit " . $params{limit}   : '';
	my $req_offset = $params{offset} ? " offset " . $params{offset} : '';

	# Request for messages
	my $sql = "select $req_fields from " . $self->{table} . " $req_filter $req_order $req_limit $req_offset";

	# Set FOR UPDATE if necessary
	if ( $params{for_update} ) {
		$sql .= " for update";
	}

	# Execute SQL query and fetch results
	my @ret = ();
	my $sth = $self->call($sql);
	while ( my $row = $sth->fetchrow_hashref() ) {
		push @ret, $row;
	}

	return @ret;

} ## end sub fetch

#***********************************************************************

=item B<insert_row(%key_val_pairs)> - insert record into table

Paramters: record fields as hash

Returns: id of inserted record 

	my $user_id = $tbl->insert_row(
		'login' => 'vasya',
		'password' => $encrypted_passwd,
	);

=cut 

#-----------------------------------------------------------------------

sub insert_row {

	my ( $self, %params ) = @_;

	my @fields = ();    # Fields list
	my @values = ();    # Values list

	# Prepare fields and values lists from input hash
	foreach my $key ( keys %params ) {
		push @fields, $key;
		push @values, $self->dbh->quote( $params{$key} );
	}

	my $return_value = $self->has_field('id') ? ' returning id' : '';
	# Prepare SQL statement from fields and values lists
	my $sql = 'insert into ' . $self->{table} . ' (' . join( ',', @fields ) . ')'    # fields list
	  . ' values (' . join( ',', @values ) . ')'                                     # values list
	  . $return_value;                                                               # return "id" field

	# Execute SQL query and fetch result
	my $sth = $self->call($sql);
	my ($row_id) = $return_value ? $sth->fetchrow_array : $sth->rows;

	# Return "id" field from inserted row
	return $row_id || $self->error( "Can't insert table record: " . $self->dbh->errstr );

} ## end sub insert_row

#***********************************************************************

=item B<insert(@records_list)> - mass insert

Paramters: list of records (as hashrefs)

Returns: array of inserted records "id"

This method allows mass insert of records.

	my @user_ids = $tbl->insert(
		{ login => 'vasya', password => $str1 },
		{ login => 'masha', password => $str2 },
		{ login => 'petya', password => $str3, active => 'false' },
	);

B<Warning!> This method use separate INSERT queries and in fact is only
wrapper for multiple C<insert_row()> calls. So it's not so fast as
one insert but allows to use different key-value pairs for different records.

=cut 

#-----------------------------------------------------------------------

sub insert {

	my ( $self, @rows ) = @_;

	my @ids = ();

	# Go through records and insert each one
	foreach my $rec (@rows) {
		push @ids, ( $self->insert_row( %{$rec} ) );
	}

	return @ids;

}

#***********************************************************************

=item B<update_row($id, %params)> - update record parameters

Paramters: id, new parameters as hash

Returns: updated record as hash

Example:


	my %upd = $table->update_row($msg_id,
		status => 'failed',
		dst_addr => '380121234567',
		);


After this %upd hash will contain updated table record.

=cut 

#-----------------------------------------------------------------------

sub update_row {

	my ( $self, $id, %params ) = @_;
	my @up = ();
	foreach my $key ( keys %params ) {
		push @up, "$key = " . $self->dbh->quote( $params{$key} );
	}

	my $sql = "update " . $self->{table} . " set " . join( ', ', @up ) . " where id=$id";

	my $res = $self->call($sql);

	if ($res) {
		return %{$res};
	} else {
		return $self->error( "Can't update table row: " . $self->dbh->errstr );
	}

}

#***********************************************************************

=item B<update(%params)> - update records by filter

Paramters: filter, new values

	$tbl->update(
		filter => ['active = true', 'created > '2008-01-01'],
		set => {
			info => 'Created after 2007 year',
		}
	);

=cut 

#-----------------------------------------------------------------------

sub update {

	my ( $self, %params ) = @_;

	# Prepare WHERE filter
	my $req_filter = $params{filter} ? " where " . join( " and ", @{ $params{filter} } ) : '';

	my @up = ();
	foreach my $key ( keys %{ $params{set} } ) {
		push @up, "$key = " . $self->dbh->quote( $params{set}->{$key} );
	}

	my $sql = "update " . $self->{table} . " set " . join( ', ', @up ) . $req_filter;
	my $res = $self->call($sql);
	
	if ($self->dbh->errstr) {
		$self->error( "Can't update table: " . $self->dbh->errstr );
		return;
	};

	return 1;
}

#***********************************************************************

=item B<get_count(%params)> - retrieve number of records

Just return total number of records by calling:

	# SELECT COUNT(id) FROM schema.table
	my $count = $tbl->get_count();

	my $count_active = $tbl->get_count(filter => ['active = true']);

=cut 

#-----------------------------------------------------------------------

## Returns number of records
sub get_count {

	my $self   = shift;
	my $filter = \@_;
	
	# Fetch number of records
	# SQL: select count(id) as c from $table where [filter]
	my @count = $self->fetch(
		fields => ['count(id) as c'],
		filter => $filter,
	);

	return $count[0]->{c};
}

#***********************************************************************

=item B<delete_by_id(@ids)> - delete records by identifier

Paramters: list of record id

Returns: 1 if ok, undef if error

Method deletes records from SQL table by it's identifiers.

	if ($tbl->remove(5, 8 ,19)) {
		print "Records successfully removed.";
	}

=cut 

#-----------------------------------------------------------------------

sub delete_by_id {

	my ( $self, @ids ) = @_;

	# TODO check for too long @id list

	# Prepare SQL condition
	my $in_cond = "id in (" . join( ", ", @ids ) . ")";
	my $sql     = "delete from " . $self->{table} . " where $in_cond";

	if ( $self->call($sql) ) {
		return 1;
	} else {
		return $self->error( "Can't delete records by Id: table='" . $self->{table} . "'" );
	}

}

#***********************************************************************

=item B<delete(@filters)> - delete records

Paramters: list of filters

Returns: 1 if ok, undef if error

	$tbl->delete(
		'active = false',
		'expire < now()',
	);

=cut 

#-----------------------------------------------------------------------

sub delete {

	my ( $self, @filter ) = @_;

	# Prepare WHERE filter
	my $req_filter = " where " . join( " and ", @filter );

	# Remove records
	$self->call( "delete from " . $self->{table} . $req_filter );

}

#***********************************************************************

=item B<get_fields()> - get list of fields

Example:

	my @fields = @{ $tbl->get_fields() };
	print "Table fields: " . join (', ', @fields);

=cut 

#-----------------------------------------------------------------------

sub get_fields {
	return [ keys %{ +shift->{'fields'} } ];
}


#***********************************************************************

=item B<has_field($field)> - check if field exists

Paramters: field name

Example:

	if ($tbl->has_field('uuid')) {
		$tbl->call("delete tbldata where uuid=?", $uuid);
	}

B<NOTE>: this method works only for restricted tables that
use C<fields> parameter at construction time.

=cut 

#-----------------------------------------------------------------------

sub has_field {

	# TODO 
	# - check if fields defined at all
	# - think about multiple values
	return $_[0]->{'fields'}{ $_[1] } 
}

1;

__END__

=back

=head1 EXAMPLES

See C<samples/test_db_table.pl> script

=head1 BUGS

Bad documentation

=head1 SEE ALSO

L<NetSDS::DBI>

L<http://en.wikipedia.org/wiki/Create,_read,_update_and_delete>

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Net Style Ltd.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


