package Queue::DBI::Admin;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use Data::Validate::Type;
use Try::Tiny;

use Queue::DBI;


=head1 NAME

Queue::DBI::Admin - Manage Queue::DBI queues.


=head1 VERSION

Version 2.7.0

=cut

our $VERSION = '2.7.0';


=head1 SYNOPSIS

	use Queue::DBI::Admin;

	# Create the object which will allow managing the queues.
	my $queues_admin = Queue::DBI::Admin->new(
		database_handle => $dbh,
	);

	# Check if the tables required by Queue::DBI exist.
	if ( !$queues_admin->has_tables() )
	{
		# Create the tables required by Queue::DBI to store the queues and data.
		$queues_admin->create_tables();
	}

	# Create a new queue.
	my $queue = $queues_admin->create_queue( $queue_name );

	# Test if a queue exists.
	if ( $queues_admin->has_queue( $queue_name ) )
	{
		...
	}

	# Retrieve a queue.
	my $queue = $queues_admin->retrieve_queue( $queue_name );

	# Delete a queue.
	$queues_admin->delete_queue( $queue_name );


=head1 SUPPORTED DATABASES

This distribution currently supports:

=over 4

=item * SQLite

=item * MySQL

=item * PostgreSQL

=back

Please contact me if you need support for another database type, I'm always
glad to add extensions if you can help me with testing.


=head1 QUEUES ADMINISTRATION METHODS

=head2 new()

Create a new Queue::DBI::Admin object.

	my $queues_admin = Queue::DBI::Admin->new(
		database_handle => $database_handle,
	);

The 'database_handle' parameter is mandatory and must correspond to a
DBI connection handle object.

Optional parameters:

=over 4

=item * queues_table_name

By default, Queue::DBI uses a table named I<queues> to store the queue
definitions. This allows using your own name, if you want to support separate
queuing systems or legacy systems.

=item * queue_elements_table_name

By default, Queue::DBI uses a table named I<queue_elements> to store the queued
data. This allows using your own name, if you want to support separate queuing
systems or legacy systems.

=back

	my $queues_admin = Queue::DBI::Admin->new(
		database_handle           => $database_handle,
		queues_table_name         => $custom_queues_table_name,
		queue_elements_table_name => $custom_queue_elements_table_name,
	);

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $database_handle = delete( $args{'database_handle'} );
	my $queues_table_name = delete( $args{'queues_table_name'} );
	my $queue_elements_table_name = delete( $args{'queue_elements_table_name'} );

	croak 'Unrecognized arguments: ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Verify arguments.
	croak 'The argument "database_handle" must be a DBI connection handle object'
		if !Data::Validate::Type::is_instance( $database_handle, class => 'DBI::db' );

	my $self = bless(
		{
			database_handle => $database_handle,
			table_names     =>
			{
				'queues'         => $queues_table_name,
				'queue_elements' => $queue_elements_table_name,
			},
			tables_verified => 0,
		},
		$class
	);

	return $self;
}


=head2 create_queue()

Create a new queue.

	$queues_admin->create_queue( $queue_name );

=cut

sub create_queue
{
	my ( $self, $queue_name ) = @_;
	my $database_handle = $self->get_database_handle();

	# Verify parameters.
	croak 'The first parameter must be a queue name'
		if !defined( $queue_name ) || ( $queue_name eq '' );

	# Make sure the tables are correctly set up.
	$self->assert_tables_verified();

	my $queues_table_name = $database_handle->quote_identifier(
		$self->get_queues_table_name()
	);

	# Create the queue.
	$database_handle->do(
		sprintf(
			q|
				INSERT INTO %s ( name )
				VALUES ( ? )
			|,
			$queues_table_name,
		),
		{},
		$queue_name,
	) || croak 'Cannot execute SQL: ' . $database_handle->errstr();

	return;
}


=head2 has_queue()

Test if a queue exists.

	if ( $queues_admin->has_queue( $queue_name ) )
	{
		...
	}

=cut

sub has_queue
{
	my ( $self, $queue_name ) = @_;
	my $database_handle = $self->get_database_handle();

	# Verify parameters.
	croak 'The first parameter must be a queue name'
		if !defined( $queue_name ) || ( $queue_name eq '' );

	# Make sure the tables are correctly set up.
	$self->assert_tables_verified();

	return try
	{
		my $queue = $self->retrieve_queue( $queue_name );

		croak 'The queue does not exist'
			if !defined( $queue );

		return 1;
	}
	catch
	{
		return 0;
	};
}


=head2 retrieve_queue()

Retrieve a queue.

	my $queue = $queues_admin->retrieve_queue( $queue_name );

	# See Queue::DBI->new() for all the available options.
	my $queue = $queues_admin->retrieve_queue(
		$queue_name,
		'cleanup_timeout'   => 3600,
		'verbose'           => 1,
		'max_requeue_count' => 5,
	);

=cut

sub retrieve_queue
{
	my ( $self, $queue_name, %args ) = @_;
	my $database_handle = $self->get_database_handle();

	# Verify parameters.
	croak 'The first parameter must be a queue name'
		if !defined( $queue_name ) || ( $queue_name eq '' );

	# Make sure the tables are correctly set up.
	$self->assert_tables_verified();

	# Instantiate a Queue::DBI object.
	my $queue = Queue::DBI->new(
		database_handle           => $database_handle,
		queue_name                => $queue_name,
		queues_table_name         => $self->get_queues_table_name(),
		queue_elements_table_name => $self->get_queue_elements_table_name(),
		%args
	);

	return $queue;
}


=head2 delete_queue()

Delete a queue and all associated data, permanently. Use this function at your
own risk!

	$queues_admin->delete_queue( $queue_name );

=cut

sub delete_queue
{
	my ( $self, $queue_name ) = @_;
	my $database_handle = $self->get_database_handle();

	# Verify parameters.
	croak 'The first parameter must be a queue name'
		if !defined( $queue_name ) || ( $queue_name eq '' );

	# Make sure the tables are correctly set up.
	$self->assert_tables_verified();

	# Retrieve the queue object, to get the queue ID.
	my $queue = $self->retrieve_queue( $queue_name );

	# Delete queue elements.
	my $queue_elements_table_name = $database_handle->quote_identifier(
		$self->get_queue_elements_table_name()
	);

	$database_handle->do(
		sprintf(
			q|
				DELETE
				FROM %s
				WHERE queue_id = ?
			|,
			$queue_elements_table_name,
		),
		{},
		$queue->get_queue_id(),
	) || croak 'Cannot execute SQL: ' . $database_handle->errstr();

	# Delete the queue.
	my $queues_table_name = $database_handle->quote_identifier(
		$self->get_queues_table_name()
	);

	$database_handle->do(
		sprintf(
			q|
				DELETE
				FROM %s
				WHERE queue_id = ?
			|,
			$queues_table_name,
		),
		{},
		$queue->get_queue_id(),
	) || croak 'Cannot execute SQL: ' . $database_handle->errstr();

	return;
}


=head1 DATABASE SETUP METHODS

=head2 has_tables()

Determine if the tables required for L<Queue::DBI> to operate exist.

	my $tables_exist = $queues_admin->has_tables();

This method returns 1 if all tables exist, 0 if none exist, and croaks with
more information if some tables are missing or if the mandatory fields on some
of the tables are missing.

=cut

sub has_tables
{
	my ( $self ) = @_;
	my $database_handle = $self->get_database_handle();

	# Check the database type.
	$self->assert_database_type_supported();

	# Check if the queues table exists.
	my $queues_table_exists = $self->has_table( 'queues' );

	# Check if the queue elements table exists.
	my $queue_elements_table_exists = $self->has_table( 'queue_elements' );

	# If both tables don't exist, return 0.
	return 0
		if !$queues_table_exists && !$queue_elements_table_exists;

	# If one of the tables is missing, we want the user to know that there is
	# a problem to fix and that create_table() won't work.
	croak "The table '" . $self->get_queues_table_name() . "' exists, but '" . $self->get_queue_elements_table_name() . "' is missing"
		if $queues_table_exists && !$queue_elements_table_exists;
	croak "The table '" . $self->get_queue_elements_table_name() . "' exists, but '" . $self->get_queues_table_name() . "' is missing"
		if !$queues_table_exists && $queue_elements_table_exists;

	# Check if the queues table has the mandatory fields.
	my $queues_table_has_fields = $self->has_mandatory_fields( 'queues' );
	croak "The table '" . $self->get_queues_table_name() . "' exists, but is missing mandatory fields"
		if !$queues_table_has_fields;

	# Check if the queue elements table has the mandatory fields.
	my $queue_elements_table_has_fields = $self->has_mandatory_fields( 'queue_elements' );
	croak "The table '" . $self->get_queue_elements_table_name() . "' exists, but is missing mandatory fields"
		if !$queue_elements_table_has_fields;

	# Both tables exist and have the mandatory fields for Queue::DBI to
	# work, we can safely return 1.
	return 1;
}


=head2 create_tables()

Create the tables required by L<Queue::DBI> to store the queues and data.

	$queues_admin->create_tables(
		drop_if_exist => $boolean,
	);

By default, it won't drop any table but you can force that by setting
'drop_if_exist' to 1. See C<drop_tables()> for more information on how tables
are dropped.

=cut

sub create_tables
{
	my ( $self, %args ) = @_;
	my $drop_if_exist = delete( $args{'drop_if_exist'} ) || 0;
	croak 'Unrecognized arguments: ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	my $database_handle = $self->get_database_handle();

	# Check the database type.
	my $database_type = $self->assert_database_type_supported();

	# Prepare the name of the tables.
	my $queues_table_name = $self->get_queues_table_name();
	my $quoted_queues_table_name = $self->get_quoted_queues_table_name();

	my $queue_elements_table_name = $self->get_queue_elements_table_name();
	my $quoted_queue_elements_table_name = $self->get_quoted_queue_elements_table_name();

	# Drop the tables, if requested.
	$self->drop_tables()
		if $drop_if_exist;

	# Create the list of queues.
	if ( $database_type eq 'SQLite' )
	{
		$database_handle->do(
			sprintf(
				q|
					CREATE TABLE %s
					(
						queue_id INTEGER PRIMARY KEY AUTOINCREMENT,
						name VARCHAR(255) NOT NULL UNIQUE
					)
				|,
				$quoted_queues_table_name,
			)
		) || croak 'Cannot execute SQL: ' . $database_handle->errstr();
	}
	elsif ( $database_type eq 'Pg' )
	{
		my $unique_index_name = $database_handle->quote_identifier(
			'unq_' . $queues_table_name . '_name',
		);

		$database_handle->do(
			sprintf(
				q|
					CREATE TABLE %s
					(
						queue_id SERIAL,
						name VARCHAR(255) NOT NULL,
						PRIMARY KEY (queue_id),
						CONSTRAINT %s UNIQUE (name)
					)
				|,
				$quoted_queues_table_name,
				$unique_index_name,
			)
		) || croak 'Cannot execute SQL: ' . $database_handle->errstr();
	}
	else
	{
		my $unique_index_name = $database_handle->quote_identifier(
			'unq_' . $queues_table_name . '_name',
		);

		$database_handle->do(
			sprintf(
				q|
					CREATE TABLE %s
					(
						queue_id INT(11) NOT NULL AUTO_INCREMENT,
						name VARCHAR(255) NOT NULL,
						PRIMARY KEY (queue_id),
						UNIQUE KEY %s (name)
					)
					ENGINE=InnoDB
				|,
				$quoted_queues_table_name,
				$unique_index_name,
			)
		) || croak 'Cannot execute SQL: ' . $database_handle->errstr();
	}

	# Create the table that will hold the queue elements.
	if ( $database_type eq 'SQLite' )
	{
		$database_handle->do(
			sprintf(
				q|
					CREATE TABLE %s
					(
						queue_element_id INTEGER PRIMARY KEY AUTOINCREMENT,
						queue_id INTEGER NOT NULL,
						data TEXT,
						lock_time INT(10) DEFAULT NULL,
						requeue_count INT(3) DEFAULT '0',
						created INT(10) NOT NULL DEFAULT '0'
					)
				|,
				$quoted_queue_elements_table_name,
			)
		) || croak 'Cannot execute SQL: ' . $database_handle->errstr();
	}
	elsif ( $database_type eq 'Pg' )
	{
		$database_handle->do(
			sprintf(
				q|
					CREATE TABLE %s
					(
						queue_element_id SERIAL,
						queue_id INTEGER NOT NULL REFERENCES %s (queue_id),
						data TEXT,
						lock_time INTEGER DEFAULT NULL,
						requeue_count SMALLINT DEFAULT 0,
						created INTEGER NOT NULL DEFAULT 0,
						PRIMARY KEY (queue_element_id)
					)
				|,
				$quoted_queue_elements_table_name,
				$quoted_queues_table_name,
			)
		) || croak 'Cannot execute SQL: ' . $database_handle->errstr();

		my $queue_id_index_name = $database_handle->quote_identifier(
			'idx_' . $queue_elements_table_name . '_queue_id'
		);

		$database_handle->do(
			sprintf(
				q|
					CREATE INDEX %s
					ON %s (queue_id)
				|,
				$queue_id_index_name,
				$quoted_queue_elements_table_name,
			)
		) || croak 'Cannot execute SQL: ' . $database_handle->errstr();
	}
	else
	{
		my $queue_id_index_name = $database_handle->quote_identifier(
			'idx_' . $queue_elements_table_name . '_queue_id'
		);
		my $queue_id_foreign_key_name = $database_handle->quote_identifier(
			'fk_' . $queue_elements_table_name . '_queue_id'
		);

		$database_handle->do(
			sprintf(
				q|
					CREATE TABLE %s
					(
						queue_element_id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
						queue_id INT(11) NOT NULL,
						data TEXT,
						lock_time INT(10) UNSIGNED DEFAULT NULL,
						requeue_count INT(3) UNSIGNED DEFAULT '0',
						created INT(10) UNSIGNED NOT NULL DEFAULT '0',
						PRIMARY KEY (queue_element_id),
						KEY %s (queue_id),
						CONSTRAINT %s FOREIGN KEY (queue_id) REFERENCES %s (queue_id)
					)
					ENGINE=InnoDB
				|,
				$quoted_queue_elements_table_name,
				$queue_id_index_name,
				$queue_id_foreign_key_name,
				$quoted_queues_table_name,
			)
		) || croak 'Cannot execute SQL: ' . $database_handle->errstr();
	}

	return;
}


=head2 drop_tables()

Drop the tables used to store the queues and queue data.

Warning: there is no undo for this operation. Make sure you really want to drop
the tables before using this method.

	$queues_admin->drop_tables();

Note: due to foreign key constraints, the tables are dropped in the reverse
order in which they are created.

=cut

sub drop_tables
{
	my ( $self ) = @_;
	my $database_handle = $self->get_database_handle();

	# Check the database type.
	$self->assert_database_type_supported();

	# If the tables exist, make sure that they have the mandatory fields. This
	# prevents a user from deleting a random table using this function.
	if ( $self->has_table( 'queues' ) )
	{
		my $queues_table_name = $self->get_queues_table_name();
		croak "The table '$queues_table_name' is missing some or all mandatory fields, so we cannot safely determine that it is used by Queue::DBI and delete it"
			if !$self->has_mandatory_fields( 'queues' );
	}
	if ( $self->has_table( 'queue_elements' ) )
	{
		my $queue_elements_table_name = $self->get_queue_elements_table_name();
		croak "The table '$queue_elements_table_name' is missing some or all mandatory fields, so we cannot safely determine that it is used by Queue::DBI and delete it"
			if !$self->has_mandatory_fields( 'queue_elements' );
	}

	# Prepare the name of the tables.
	my $quoted_queues_table_name = $self->get_quoted_queues_table_name();
	my $quoted_queue_elements_table_name = $self->get_quoted_queue_elements_table_name();

	# Drop the tables.
	# Note: due to foreign key constraints, we need to drop the tables in the
	# reverse order in which they are created.
	$database_handle->do(
		sprintf(
			q|DROP TABLE IF EXISTS %s|,
			$quoted_queue_elements_table_name,
		)
	) || croak 'Cannot execute SQL: ' . $database_handle->errstr();

	$database_handle->do(
		sprintf(
			q|DROP TABLE IF EXISTS %s|,
			$quoted_queues_table_name,
		)
	) || croak 'Cannot execute SQL: ' . $database_handle->errstr();

	return;
}


=head1 INTERNAL METHODS

=head2 get_database_handle()

Return the database handle associated with the L<Queue::DBI::Admin> object.

	my $database_handle = $queue->get_database_handle();

=cut

sub get_database_handle
{
	my ( $self ) = @_;

	return $self->{'database_handle'};
}


=head2 get_queues_table_name()

Return the name of the table used to store queue definitions.

	my $queues_table_name = $queues_admin->get_queues_table_name();

=cut

sub get_queues_table_name
{
	my ( $self ) = @_;

	return defined( $self->{'table_names'}->{'queues'} ) && ( $self->{'table_names'}->{'queues'} ne '' )
		? $self->{'table_names'}->{'queues'}
		: $Queue::DBI::DEFAULT_QUEUES_TABLE_NAME;
}


=head2 get_queue_elements_table_name()

Return the name of the table used to store queue elements.

	my $queue_elements_table_name = $queues_admin->get_queue_elements_table_name();

=cut

sub get_queue_elements_table_name
{
	my ( $self ) = @_;

	return defined( $self->{'table_names'}->{'queue_elements'} ) && ( $self->{'table_names'}->{'queue_elements'} ne '' )
		? $self->{'table_names'}->{'queue_elements'}
		: $Queue::DBI::DEFAULT_QUEUE_ELEMENTS_TABLE_NAME;
}


=head2 get_quoted_queues_table_name()

Return the name of the table used to store queue definitions, quoted for
inclusion in SQL statements.

	my $quoted_queues_table_name = $queues_admin->get_quoted_queues_table_name();


=cut

sub get_quoted_queues_table_name
{
	my ( $self ) = @_;

	my $database_handle = $self->get_database_handle();
	my $queues_table_name = $self->get_queues_table_name();

	return defined( $queues_table_name )
		? $database_handle->quote_identifier( $queues_table_name )
		: undef;
}


=head2 get_quoted_queue_elements_table_name()

Return the name of the table used to store queue elements, quoted for inclusion
in SQL statements.

	my $quoted_queue_elements_table_name = $queues_admin->get_quoted_queue_elements_table_name();

=cut

sub get_quoted_queue_elements_table_name
{
	my ( $self ) = @_;

	my $database_handle = $self->get_database_handle();
	my $queue_elements_table_name = $self->get_queue_elements_table_name();

	return defined( $queue_elements_table_name )
		? $database_handle->quote_identifier( $queue_elements_table_name )
		: undef;
}


=head2 assert_database_type_supported()

Assert (i.e., die on failure) whether the database type specified by the
database handle passed to C<new()> is supported or not.

	my $database_type = $queues_admin->assert_database_type_supported();

Note: the type of the database handle associated with the current object is
returned when it is supported.

=cut

sub assert_database_type_supported
{
	my ( $self ) = @_;

	# Check the database type.
	my $database_type = $self->get_database_type();
	croak "This database type ($database_type) is not supported yet, please email the maintainer of the module for help"
		if $database_type !~ m/^(?:SQLite|MySQL|Pg)$/ix;

	return $database_type;
}


=head2 get_database_type()

Return the database type corresponding to the database handle associated
with the L<Queue::DBI::Admin> object.

	my $database_type = $queues_admin->get_database_type();

=cut

sub get_database_type
{
	my ( $self ) = @_;

	my $database_handle = $self->get_database_handle();

	return $database_handle->{'Driver'}->{'Name'} || '';
}


=head2 has_table()

Return if a table required by L<Queue::DBI> to operate exists.

	my $has_table = $queues_admin->has_table( $table_type );

Valid table types are:

=over 4

=item * 'queues'

=item * 'queue_elements'

=back

=cut

sub has_table
{
	my ( $self, $table_type ) = @_;

	# Check the table type.
	croak 'A table type must be specified'
		if !defined( $table_type );
	croak "The table type '$table_type' is not valid"
		if $table_type !~ /\A(?:queues|queue_elements)\Z/x;

	# Retrieve the table name.
	my $table_name = $table_type eq 'queues'
		? $self->get_quoted_queues_table_name()
		: $self->get_quoted_queue_elements_table_name();

	# Check if the table exists.
	my $database_handle = $self->get_database_handle();
	my $table_exists =
	try
	{
		# Disable printing errors out since we expect the statement to fail.
		local $database_handle->{'PrintError'} = 0;
		local $database_handle->{'RaiseError'} = 1;

		$database_handle->selectrow_array(
			sprintf(
				q|
					SELECT *
					FROM %s
				|,
				$table_name,
			)
		);

		return 1;
	}
	catch
	{
		return 0;
	};

	return $table_exists;
}


=head2 has_mandatory_fields()

Return if a table required by L<Queue::DBI> has the mandatory fields.

	my $has_mandatory_fields = $queues_admin->has_mandatory_fields( $table_type );

Valid table types are:

=over 4

=item * 'queues'

=item * 'queue_elements'

=back

=cut

sub has_mandatory_fields
{
	my ( $self, $table_type ) = @_;

	# Check the table type.
	croak 'A table type must be specified'
		if !defined( $table_type );
	croak "The table type '$table_type' is not valid"
		if $table_type !~ /\A(?:queues|queue_elements)\Z/x;

	# Retrieve the table name.
	my $table_name = $table_type eq 'queues'
		? $self->get_quoted_queues_table_name()
		: $self->get_quoted_queue_elements_table_name();

	# Retrieve the list of fields to check for.
	my $mandatory_fields = $table_type eq 'queues'
		? 'queue_id, name'
		: 'queue_element_id, queue_id, data, lock_time, requeue_count, created';

	# Check if the fields exist.
	my $database_handle = $self->get_database_handle();
	my $has_mandatory_fields =
	try
	{
		# Disable printing errors out since we expect the statement to fail.
		local $database_handle->{'PrintError'} = 0;
		local $database_handle->{'RaiseError'} = 1;

		$database_handle->selectrow_array(
			sprintf(
				q|
					SELECT %s
					FROM %s
				|,
				$mandatory_fields,
				$table_name,
			)
		);

		return 1;
	}
	catch
	{
		return 0;
	};

	return $has_mandatory_fields;
}


=head2 assert_tables_verified()

Assert that the tables exist and are defined correctly.

	$queues_admin->assert_tables_verified();

Note that this will perform the check only once per L<Queue::DBI::Admin>
object, as this is an expensive check that would otherwise slow down the
methods that use it.

=cut

sub assert_tables_verified
{
	my ( $self ) = @_;

	return if $self->{'tables_verified'};

	# If some tables are incorrectly set up, has_tables() will croak here.
	# It however also returns 0 if no tables are defined, and we need to
	# turn it into a croak here.
	$self->has_tables()
		|| croak 'The queues and queue elements tables need to be created, see Queue::DBI::Admin->create_tables()';

	$self->{'tables_verified'} = 1;

	return;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Queue-DBI/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Queue::DBI::Admin


You can also look for information at:

=over 4

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/Queue-DBI/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Queue-DBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Queue-DBI>

=item * MetaCPAN

L<https://metacpan.org/release/Queue-DBI>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 ACKNOWLEDGEMENTS

Thanks to Sergey Bond for suggesting this administration module to extend
and complete the features offered by L<Queue::DBI>.


=head1 COPYRIGHT & LICENSE

Copyright 2009-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
