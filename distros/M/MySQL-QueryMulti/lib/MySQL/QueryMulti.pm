package MySQL::QueryMulti;

use 5.006;
use Carp;
use DBI;
use Moose;
use namespace::autoclean;
use SQL::Statement;
use Data::Dumper;

=head1 NAME

MySQL::QueryMulti - module for querying multiple MySQL databases in parallel

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

 my $qm = MySQL::QueryMulti->new;
 $qm->connect(
		[ get_dsn('pet1'), $ENV{DBI_USER}, $pass ],
		[ get_dsn('pet2'), $ENV{DBI_USER}, $pass ],
		... repeat as necessary ...,
		{ AutoInactiveDestroy => 0 }
 );

 $qm->prepare( "select * from pet order by owner" );  
 my $sth = $qm->execute; 

 while ( my @row = $sth->fetchrow_array ) {
	 print "@row\n";
 } 

=cut

=head1 DESCRIPTION

MySQL::QueryMulti is a module that allows the user to query multiple MySQL 
databases in parallel and get an aggregated/concatentated result set back.  

Requirements:
 * must have "create temporary table" privileges across all databases
 * schemas must be identical 

MySQL::QueryMulti is built using DBI and hence has nearly identical method 
calls (connect, prepare, and execute).  See method descriptions below.

The primary use case for this is when you have a sharded database environment.

See link for more info on sharding:

=over

L<http://en.wikipedia.org/wiki/Shard_%28database_architecture%29>

=back

=cut 

my $TEMP_TABLE_NAME = 'mytemp';

has '_dbh_list' => (
	is       => 'rw',
	isa      => 'ArrayRef',
	required => 0,
	init_arg => undef,
);

has '_sth_list' => (
	is       => 'rw',
	isa      => 'ArrayRef',
	required => 0,
	default  => sub { [] }
);

has '_temp_dbh' => (
	is       => 'rw',
	isa      => 'Object',
	required => 0,
	init_arg => undef,
);

has '_temp_prepare_stmt' => (
	is       => 'rw',
	isa      => 'Str',
	required => 0,
	init_arg => undef,
);

has '_prepare_args' => (
	is       => 'rw',
	isa      => 'ArrayRef',
	required => 0,
	init_arg => undef,
);

has '_execute_args' => (
	is       => 'rw',
	isa      => 'ArrayRef',
	required => 0,
	init_arg => undef,
);

has '_sql_stmt' => (
	is       => 'rw',
	isa      => 'Object',
	required => 0,
	init_arg => undef,
);

has 'raise_error' => (
	is       => 'rw',
	isa      => 'Int',
	required => 0,
	default  => 1,
);

has 'err' => (
	is       => 'rw',
	isa      => 'Str',
	required => 0,
	init_arg => undef,

);

has 'errstr' => (
	is       => 'rw',
	isa      => 'Str',
	required => 0,
	init_arg => undef,

);

has 'state' => (
	is       => 'rw',
	isa      => 'Str',
	required => 0,
	init_arg => undef,

);

has '_sql_parser' => (
	is       => 'rw',
	isa      => 'Object',
	required => 0,
	init_arg => undef
);

sub BUILD {
	my $self = shift;

	my $parser = SQL::Parser->new();
	$parser->{RaiseError} = 1;
	$parser->{PrintError} = 0;
	$parser->parse("CREATE FUNCTION database");
	$parser->feature( 'function', 'database' );
	$self->_sql_parser($parser);
}

=head1 SUBROUTINES/METHODS

=head2 new( %hash );

Object constructor.  Accepts an optional hash of arguments.  

Arguments:

=head3 raise_error( 0|1 )

Allows you to change the behavior of error handling.  The default is to throw 
an exception.  Pass true or false to modify behavior as necessary.

=head2 connect ( [ $dsn, $user, $pass ], [ $dsn2, $user, $pass ], ..., 
{ DBI attributes } )

Method for establishing a connection to a set of databases.  The arguments are
similar to DBI::connect except you pass an array of array references that each 
contain their respective DBI::connect arguments (dsn, user, password).  
Attributes are only specified once (as the last arg) and applied to each 
connection automatically. 

Passing the attributes "RaiseError" and "PrintError" will have no effect.  The
"raise_error" attribute of MySQL::QueryMulti controls that behavior.
 
Returns true on success or false on error.

example:

=over

$qm->connect(
		[ get_dsn('pet1'), $ENV{DBI_USER}, $pass ],
		[ get_dsn('pet2'), $ENV{DBI_USER}, $pass ],
		... repeat as necessary ...,
		{ AutoInactiveDestroy => 0 }
);

=back
   
=cut

sub connect {
	my $self = shift;
	my @args = @_;      # each element is an array ref that contains arguments
						# to pass to DBI::connect

	if ( @args < 1 ) {
		$self->_err_handler( 1,
			"must provide connection info for at least one database", '' );
		return 0;
	}

	my $last_arg = scalar(@args) - 1;
	my $attr;

	if ( ref( $args[$last_arg] ) eq 'HASH' ) {
		$attr = pop(@args);
	}
	else {
		$attr = {};
	}

	$attr->{RaiseError} = 0;
	$attr->{PrintError} = 0;

	my @dbhs;

	foreach my $aref (@args) {
		if ( @$aref > 3 ) {

			#
			# don't allow attributes to be specified differently per connection
			#
			my $args;
			if ( @$aref > 0 ) {
				no warnings;
				$args = join( ', ', @$aref );
			}
			else {
				$args = '';
			}

			$self->_err_handler(
				1,
				"too many arguments detected for connection\n"
				  . "\t[ $args ]\n",
				''
			);
			return 0;
		}

		my $dbh = eval { DBI->connect( @$aref, $attr ) };
		if ($@) {
			$self->_err_handler( 1, $@, '' );
			return 0;
		}
		elsif ( !defined($dbh) ) {
			print "connected to $aref->[0]\n" if $ENV{VERBOSE};
			$self->_err_handler( $DBI::err, $DBI::errstr, $DBI::state );
			return 0;
		}

		# TODO: verify 'create temporary table' priv is enabled

		push( @dbhs, $dbh );
	}

	# randomly pick one to be the designated temp table owner
	my $i = int( rand(@dbhs) );

	my $temp_dbh = eval { DBI->connect( @{ $args[$i] }, $attr ) };
	if ($@) {
		$self->_err_handler( 1, $@, '' );
		return 0;
	}
	elsif ($DBI::err) {
		$self->_err_handler( $DBI::err, $DBI::errstr, $DBI::state );
		return 0;
	}

	$self->_temp_dbh($temp_dbh);
	$self->_dbh_list( \@dbhs );

	return 1;
}

sub _err_handler {
	my $self = shift;
	$self->err(shift);
	$self->errstr(shift);
	$self->state(shift);

	if ( $self->raise_error ) {
		confess "ERROR: " . $self->errstr;
	}
}

sub _give_database_func_alias {
	my $self = shift;
	my $sql  = shift;

	print STDERR "orig sql:\n$sql\n" if $ENV{DEBUG};

	if ( $sql =~ /database\(\s*\)/ ) {
		if ( $sql !~ /database\(\s*\)\s+as\s+/ ) {
			$sql =~ s/database\(\s*\)/database() as database_name/;
		}
	}

	print STDERR "new sql:\n$sql\n" if $ENV{DEBUG};

	return $sql;
}

=head2 prepare

Identical to DBI::prepare except it does the prepare for all databases in the 
set.  

Returns true on success or false on error.

=cut

around 'prepare' => sub {
	my $orig = shift;
	my $self = shift;

	my @args = @_;
	my $sql  = shift @args;
	$sql = $self->_give_database_func_alias($sql);
	unshift @args, $sql;

	$self->$orig(@args);
};

sub prepare {
	my $self = shift;
	my @args = @_;      # ($statement, \%attr)

	if ( @args < 1 ) {
		$self->_err_handler( 1, "must provide prepare args", '' );
		return 0;
	}

	my ( $sql, $attr ) = @args;
	$self->_prepare_args( [ $sql, @args ] );  # store prepare args for later use
	$attr->{async} = 1;

	my $parser = $self->_sql_parser;

	my $stmt = SQL::Statement->new( $sql, $parser );
	if ( $stmt->command eq 'CALL' or $stmt->command eq 'LOAD' ) {
		$self->_err_handler( 1, $stmt->command . " is not implemented", '' );
		return 0;
	}

	foreach my $col_def ( @{ $stmt->column_defs } ) {
		next unless exists( $col_def->{name} );
		my $name = $col_def->{name};

		if ( $name eq 'COUNT' or $name eq 'AVG' ) {
			$self->_err_handler( 1,
				"$name aggregate function is not implemented", '' );
			return 0;
		}
	}

	#
	# cleanup for any errors that may have occurred on the last execute
	#
	foreach my $sth ( @{ $self->_sth_list } ) {
		if ( !defined( $sth->mysql_async_ready ) ) {

			# no outstanding query
		}
		elsif ( $sth->mysql_async_ready ) {

			# async query done, harvest and discard result
			$sth->mysql_async_result;
		}
		else {
			# async query still running
			while ( !$sth->mysql_async_ready ) {

				# wait for it
				sleep 1;
			}

			# async query done, harvest and discard result
			$sth->mysql_async_result;
		}
	}

	my @sths;
	foreach my $dbh ( @{ $self->_dbh_list } ) {
		my $sth = $dbh->prepare( $sql, $attr );
		if ( !$sth ) {
			$self->_err_handler( $DBI::err, $DBI::errstr, $DBI::state );
			return 0;
		}

		push( @sths, $sth );
	}

	$self->_sth_list( \@sths );
	$self->_sql_stmt($stmt);

	return 1;
}

=head2 execute

Identical to DBI::execute except it returns either a statement handle or the 
number of rows affected depending on the type of query.  A statement handle is 
returned for select queries.  The number of affected rows for all others.

Returns a statement handle or the number of affected rows on success.  Returns
undef on error.

=cut

sub execute {
	my $self = shift;
	my @args = @_;

	$self->_execute_args( [@args] );

	my @pending;
	my @results;

	foreach my $sth ( @{ $self->_sth_list } ) {
		$sth->execute(@args);
		if ( $sth->err ) {
			$self->_err_handler( $sth->err, $sth->errstr, $sth->state );
			return undef;
		}

		push( @pending, $sth );
	}

	my $select_query  = 0;
	my $rows_affected = 0;

	while (@pending) {
		my @temp;
		foreach my $sth (@pending) {
			if ( $sth->mysql_async_ready ) {
				my $ret = $sth->mysql_async_result;
				if ( $sth->err ) {
					$self->_err_handler( $sth->err, $sth->errstr, $sth->state );
					return undef;
				}

				if ( $sth->{NUM_OF_FIELDS} ) {

					#
					# we have a select query
					#
					if ( !$select_query ) {
						$self->_create_temp_table();
						$select_query = 1;
					}

					while ( my $aref = $sth->fetchrow_arrayref ) {
						$self->_add_row_to_temp_table($aref);
					}
				}
				else {

					#
					# we have an insert, update, or delete query
					#
					$rows_affected += $ret;
				}
			}
			else {
				push( @temp, $sth );
			}
		}

		@pending = @temp;
		sleep 1;
	}

	if ($select_query) {
		my $select = $self->_get_select_clause( $self->_sql_stmt );
		my $sql    = "$select from $TEMP_TABLE_NAME\n";

		# skip the where clause because it is redundant
		$sql .= $self->_get_group_by( $self->_sql_stmt );
		$sql .= $self->_get_order_by( $self->_sql_stmt );
		$sql .= $self->_get_limit( $self->_sql_stmt );

		my $dbh = $self->_get_temp_dbh;

		my $sth = $dbh->prepare($sql);
		if ( $dbh->err ) {
			$self->_err_handler( $dbh->err, $dbh->errstr, $dbh->state );
			return undef;
		}

		$sth->execute();
		if ( $dbh->err ) {
			$self->_err_handler( $dbh->err, $dbh->errstr, $dbh->state );
			return undef;
		}

		return $sth;
	}

	return $rows_affected;
}

sub _get_select_clause {
	my $self = shift;
	my $stmt = shift;

	my @cols;

	foreach my $col_def ( @{ $stmt->column_defs } ) {
		my $col;

		if ( $col_def->{type} eq 'function' and $col_def->{name} eq 'database' )
		{
			$col = $col_def->{alias};
		}
		else {
			if ( $col_def->{type} ne 'column' ) {
				$col = $col_def->{fullorg};
				$col =~ s/\s//g;
			}
			else {
				$col =
				  defined( $col_def->{fullorg} )
				  ? $col_def->{fullorg}
				  : $col_def->{value};
			}

			if ( defined( $col_def->{alias} ) ) {
				$col .= " as $col_def->{alias}";
			}
		}

		push( @cols, $col );
	}

	my $distinct = '';
	if ( defined( $stmt->{set_quantifier} )
		and $stmt->{set_quantifier} eq 'DISTINCT' )
	{
		$distinct = 'distinct';
	}

	return "select $distinct " . join( ', ', @cols );
}

sub _get_limit {
	my $self = shift;
	my $stmt = shift;

	my $limit = $stmt->limit;
	if ( defined($limit) ) {
		return "limit $limit\n";
	}

	return '';
}

sub _get_order_by {
	my $self = shift;
	my $stmt = shift;

	my @order = $stmt->order();
	my @cols;

	foreach my $o (@order) {
		my $col  = ( keys(%$o) )[0];
		my $sort = $o->{$col};

		push( @cols, "$col $sort" );
	}

	if (@cols) {
		return 'order by ' . join( ', ', @cols ) . "\n";
	}

	return '';
}

sub _get_group_by {
	my $self = shift;
	my $stmt = shift;

	if ( defined( $stmt->{group_by} ) ) {
		my @cols = @{ $stmt->{group_by} };

		return 'group by ' . join( ', ', @cols ) . "\n";
	}

	return '';
}

sub _get_temp_dbh {
	my $self = shift;

	return $self->_temp_dbh;
}

sub _create_temp_table {
	my $self = shift;

	$self->_drop_temp_table;

	my $dbh = $self->_get_temp_dbh;

	my ( $sql, $attr ) = @{ $self->_prepare_args };

	if ( $sql =~ /limit \d+/i ) {
		$sql =~ s/limit \d+/limit 0/;
	}
	else {
		$sql .= ' limit 0';
	}

	my $create_sql = "create temporary table $TEMP_TABLE_NAME as $sql";
	my $sth        = $dbh->prepare($create_sql);
	if ( $sth->err ) {
		$self->_err_handler( $sth->err, $sth->errstr, $sth->state );
		return 0;
	}

	$sth->execute( @{ $self->_execute_args } );
	if ( $sth->err ) {
		$self->_err_handler( $sth->err, $sth->errstr, $sth->state );
		return 0;
	}

	$sql = qq{
		select * from $TEMP_TABLE_NAME
	};
	$sth = $dbh->prepare($sql);
	$sth->execute;

	my @placeholders;
	for ( my $i = 0 ; $i < $sth->{NUM_OF_FIELDS} ; $i++ ) {
		push( @placeholders, '?' );
	}

	my $placeholders = join( ', ', @placeholders );

	my $tmp_prepare_stmt = qq{
		insert into $TEMP_TABLE_NAME values ($placeholders)
	};

	$self->_temp_prepare_stmt($tmp_prepare_stmt);
}

sub _drop_temp_table {
	my $self = shift;

	my $dbh = $self->_get_temp_dbh;

	my $sql = qq{
		drop temporary table if exists $TEMP_TABLE_NAME
	};
	$dbh->do($sql);
	if ( $dbh->err ) {
		$self->_err_handler( $dbh->err, $dbh->errstr, $dbh->state );
		return 0;
	}
}

sub _add_row_to_temp_table {
	my $self = shift;
	my $aref = shift;

	my $dbh = $self->_get_temp_dbh;

	my $sth = $dbh->prepare( $self->_temp_prepare_stmt );
	$sth->execute(@$aref);
}

=head1 LIMITATIONS

 * This does not provide true parallelism in that it leverages the 
   "async" feature of DBD::MySQL.  You could accomplish true parallelism with 
   threads or the heavier fork/exec, but that adds extra complexity (especially
   if you have to recompile the mysql client libs with threading enabled).  
   This keeps things simple and still provides reasonable performance.
   
 * Does not work with count or sum aggregate functions.
 
 * Stored procedures have not been tested so use them at your own risk.
 
=head1 AUTHOR

John Gravatt, C<< <gravattj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mysql-querymulti at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MySQL-QueryMulti>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MySQL::QueryMulti


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MySQL-QueryMulti>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MySQL-QueryMulti>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MySQL-QueryMulti>

=item * Search CPAN

L<http://search.cpan.org/dist/MySQL-QueryMulti/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 John Gravatt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable;    # moose stuff

1;
