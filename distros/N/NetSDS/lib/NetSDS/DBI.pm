#===============================================================================
#
#         FILE:  DBI.pm
#
#  DESCRIPTION:  DBI wrapper for NetSDS
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  31.07.2009 13:56:33 UTC
#===============================================================================

=head1 NAME

NetSDS::DBI - DBI wrapper for NetSDS

=head1 SYNOPSIS

	use NetSDS::DBI;

	$dbh = NetSDS::DBI->new(
		dsn    => 'dbi:Pg:dbname=test;host=127.0.0.1;port=5432',
		login  => 'user',
		passwd => 'topsecret',
	);

	print $db->call("select md5(?)", 'zuka')->fetchrow_hashref->{md5};

=head1 DESCRIPTION

C<NetSDS::DBI> module provides wrapper around DBI module.

=cut

package NetSDS::DBI;

use 5.8.0;
use strict;
use warnings;

use DBI;

use base 'NetSDS::Class::Abstract';

use version; our $VERSION = '1.301';

#===============================================================================

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

    $dbh = NetSDS::DBI->new(
		dsn    => 'dbi:Pg:dbname=test;host=127.0.0.1;port=5432',
		login  => 'user',
		passwd => 'topsecret',
	);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	# DBI handler attributes
	my $attrs = { $params{attrs} ? %{ $params{attrs} } : () };

	# Startup SQL queries
	my $sets = $params{sets} || [];

	# Prepare additional parameters
	if ( $params{dsn} ) {

		# Parse DSN to determine DBD driver and provide
		my $dsn_scheme   = undef;
		my $dsn_driver   = undef;
		my $dsn_attr_str = undef;
		my $dsn_attrs    = undef;
		my $dsn_dsn      = undef;
		if ( ( $dsn_scheme, $dsn_driver, $dsn_attr_str, $dsn_attrs, $dsn_dsn ) = DBI->parse_dsn( $params{dsn} ) ) {

			# Set PostgreSQL default init queries
			if ( 'Pg' eq $dsn_driver ) {
				unshift( @{$sets}, "SET CLIENT_ENCODING TO 'UTF-8'" );
				unshift( @{$sets}, "SET DATESTYLE TO 'ISO'" );
			}

			# Set UTF-8 support
			$attrs = {
				%{$attrs},
				pg_enable_utf8 => 1,
			};

		} else {
			return $class->error( "Can't parse DBI DSN: " . $params{dsn} );
		}

	} else {
		return $class->error("Can't initialize DBI connection without DSN");
	}

	# initialize parent class
	my $self = $class->SUPER::new(
		dbh    => undef,
		dsn    => $params{dsn},
		login  => $params{login},
		passwd => $params{passwd},
		attrs  => {},
		sets   => [],
		%params,
	);

	# Implement SQL debugging
	if ( $params{debug_sql} ) {
		$self->{debug_sql} = 1;
	}

	# Create object accessor for DBMS handler
	$self->mk_accessors('dbh');

	# Add initialization SQL queries
	$self->_add_sets( @{$sets} );

	$attrs->{PrintError} = 0;
	$self->_add_attrs( %{$attrs} );

	# Connect to DBMS
	$self->_connect();

	return $self;

} ## end sub new

#***********************************************************************

=item B<dbh()> - DBI connection handler accessor

Returns: DBI object 

This method provides accessor to DBI object and for low level access
to database specific methods.

Example (access to specific method):

	my $quoted = $db->dbh->quote_identifier(undef, 'auth', 'services');
	# $quoted contains "auth"."services" now

=cut 

#-----------------------------------------------------------------------

#***********************************************************************

=item B<call($sql, @bind_params)> - prepare and execute SQL query

Method C<call()> implements the following functionality:

	* check connection to DBMS and restore it
	* prepare chached SQL statement
	* execute statement with bind parameters

Parameters:

	* SQL query with placeholders
	* bind parameters

Return:

	* statement handler from DBI 

Example:

	$sth = $dbh->call("select * from users");
	while (my $row = $sth->fetchrow_hashref()) {
		print $row->{username};
	}

=cut 

#-----------------------------------------------------------------------

sub call {

	my ( $self, $sql, @params ) = @_;

	# Debug SQL
	if ( $self->{debug_sql} ) {
		$self->log( "debug", "SQL: $sql" );
	}

	# First check connection and try to restore if necessary
	unless ( $self->_check_connection() ) {
		return $self->error("Database connection error!");
	}

	# Prepare cached SQL query
	# FIXME my $sth = $self->dbh->prepare_cached($sql);
	my $sth = $self->dbh->prepare($sql);
	unless ($sth) {
		return $self->error("Can't prepare SQL query: $sql");
	}

	# Execute SQL query
	$sth->execute(@params);

	return $sth;

} ## end sub call

#***********************************************************************

=item B<fetch_call($sql, @params)> - call and fetch result

Paramters: SQL query, parameters

Returns: arrayref of records as hashrefs

Example:

	# SQL DDL script:
	# create table users (
	# 	id serial,
	# 	login varchar(32),
	# 	passwd varchar(32)
	# );

	# Now we fetch all data to perl structure
	my $table_data = $db->fetch_call("select * from users");

	# Process this data
	foreach my $user (@{$table_data}) {
		print "User ID: " . $user->{id};
		print "Login: " . $user->{login};
	}

=cut 

#-----------------------------------------------------------------------

sub fetch_call {

	my ( $self, $sql, @params ) = @_;

	# Try to prepare and execute SQL statement
	if ( my $sth = $self->call( $sql, @params ) ) {
		# Fetch all data as arrayref of hashrefs
		return $sth->fetchall_arrayref( {} );
	} else {
		return $self->error("Can't execute SQL: $sql");
	}

}

#***********************************************************************

=item B<begin()> - start transaction

=cut

sub begin {

	my ($self) = @_;

	return $self->dbh->begin_work();
}

#***********************************************************************

=item B<commit()> - commit transaction

=cut

sub commit {

	my ($self) = @_;

	return $self->dbh->commit();
}

#***********************************************************************

=item B<rollback()> - rollback transaction

=cut

sub rollback {

	my ($self) = @_;

	return $self->dbh->rollback();
}

#***********************************************************************

=item B<quote()> - quote SQL string

Example:

	# Encode $str to use in queries
	my $str = "some crazy' string; with (dangerous characters";
	$str = $db->quote($str);

=cut

sub quote {

	my ( $self, $str ) = @_;

	return $self->dbh->quote($str);
}

#***********************************************************************

=back

=head1 INTERNAL METHODS 

=over

=item B<_add_sets()> - add initial SQL query

Example:

    $obj->_add_sets("set search_path to myscheme");
    $obj->_add_sets("set client_encoding to 'UTF-8'");

=cut

#-----------------------------------------------------------------------
sub _add_sets {
	my ( $self, @sets ) = @_;

	push( @{ $self->{sets} }, @sets );

	return 1;
}

#***********************************************************************

=item B<_add_attrs()> - add DBI handler attributes

    $self->_add_attrs(AutoCommit => 1);

=cut

#-----------------------------------------------------------------------
sub _add_attrs {
	my ( $self, %attrs ) = @_;

	%attrs = ( %{ $self->{attrs} }, %attrs );
	return %attrs;
}

#***********************************************************************

=item B<_check_connection()> - ping and reconnect

Internal method checking connection and implement reconnect

=cut 

#-----------------------------------------------------------------------

sub _check_connection {

	my ($self) = @_;

	if ( $self->dbh ) {
		if ( $self->dbh->ping() ) {
			return 1;
		} else {
			return $self->_connect();
		}
	}
}

#***********************************************************************

=item B<_connect()> - connect to DBMS

Internal method starting connection to DBMS

=cut 

#-----------------------------------------------------------------------

sub _connect {

	my ($self) = @_;

	# Try to connect to DBMS
	$self->dbh( DBI->connect_cached( $self->{dsn}, $self->{login}, $self->{passwd}, $self->{attrs} ) );

	if ( $self->dbh ) {

		# All OK - drop error state
		$self->error(undef);

		# Call startup SQL queries
		foreach my $row ( @{ $self->{sets} } ) {
			unless ( $self->dbh->do($row) ) {
				return $self->error( $self->dbh->errstr || 'Set error in connect' );
			}
		}

	} else {
		return $self->error( "Can't connect to DBMS: " . $DBI::errstr );
	}

} ## end sub _connect

1;

__END__

=back

=head1 EXAMPLES

samples/testdb.pl

=head1 SEE ALSO

L<DBI>, L<DBD::Pg>

=head1 TODO

1. Make module less PostgreSQL specific.

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


