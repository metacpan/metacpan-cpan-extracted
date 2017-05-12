package Queue::DBI;

use warnings;
use strict;

use Data::Dumper;
use Data::Validate::Type;
use Carp;
use Storable qw();
use MIME::Base64 qw();

use Queue::DBI::Element;


=head1 NAME

Queue::DBI - A queueing module with an emphasis on safety, using DBI as a storage system for queued data.


=head1 VERSION

Version 2.7.0

=cut

our $VERSION = '2.7.0';

our $DEFAULT_QUEUES_TABLE_NAME = 'queues';

our $DEFAULT_QUEUE_ELEMENTS_TABLE_NAME = 'queue_elements';

our $MAX_VALUE_SIZE = 65535;


=head1 SYNOPSIS

This module allows you to safely use a queueing system by preventing
backtracking, infinite loops and data loss.

An emphasis of this distribution is to provide an extremely reliable dequeueing
mechanism without having to use transactions.

	use Queue::DBI;
	my $queue = Queue::DBI->new(
		'queue_name'      => $queue_name,
		'database_handle' => $dbh,
		'cleanup_timeout' => 3600,
		'verbose'         => 1,
	);

	# Store a complex data structure.
	$queue->enqueue(
		{
			values => [ 1, 2, 3 ],
			data   => { key1 => 1, key2 => 2 },
		}
	);

	# Store a scalar, which must be passed by reference.
	$queue->enqueue( \"Lorem ipsum dolor sit amet" );

	# Process the queued elements one by one.
	while ( my $queue_element = $queue->next() )
	{
		# Skip elements that cannot be locked.
		next
			unless $queue_element->lock();

		eval {
			# Do some work
			process( $queue_element->{'email'} );
		};
		if ( $@ )
		{
			# Something failed, we clear the lock but don't delete the record in the
			# queue so that we can try again next time
			$queue_element->requeue();
		}
		else
		{
			# All good, remove definitively the element
			$queue_element->success();
		}
	}

	# Requeue items that have been locked for more than 6 hours
	$queue->cleanup( 6 * 3600 );


=head1 SUPPORTED DATABASES

This distribution currently supports:

=over 4

=item * SQLite

=item * MySQL

=item * PostgreSQL

=back

Please contact me if you need support for another database type, I'm always
glad to add extensions if you can help me with testing.


=head1 METHODS

=head2 new()

Create a new Queue::DBI object.

	my $queue = Queue::DBI->new(
		'queue_name'        => $queue_name,
		'database_handle'   => $dbh,
		'cleanup_timeout'   => 3600,
		'verbose'           => 1,
		'max_requeue_count' => 5,
	);

	# Custom table names (optional).
	my $queue = Queue::DBI->new(
		'queue_name'                => $queue_name,
		'database_handle'           => $dbh,
		'cleanup_timeout'           => 3600,
		'verbose'                   => 1,
		'max_requeue_count'         => 5,
		'queues_table_name'         => $custom_queues_table_name,
		'queue_elements_table_name' => $custom_queue_elements_table_name,
	);

Parameters:

=over 4

=item * 'queue_name'

Mandatory, the name of the queue elements will be added to / removed from.

=item * 'database handle'

Mandatory, a DBI object.

=item * 'cleanup_timeout'

Optional, if set to an integer representing a time in seconds, the module will
automatically make available again elements that have been locked longuer than
that time.

=item * 'verbose'

Optional, control the verbosity of the warnings in the code. 0 will not display
any warning; 1 will only give one line warnings about the current operation;
2 will also usually output the SQL queries performed.

=item * 'max_requeue_count'

By default, Queue:::DBI will retrieve again the queue elements that were
requeued without limit to the number of times they have been requeued. Use this
option to specify how many times an element can be requeued before it is
ignored when retrieving elements.

=item * 'queues_table_name'

By default, Queue::DBI uses a table named 'queues' to store the queue
definitions. This allows using your own name, if you want to support separate
queuing systems or legacy systems.

=item * 'queue_elements_table_name'

By default, Queue::DBI uses a table named 'queue_elements' to store the queued
data. This allows using your own name, if you want to support separate queuing
systems or legacy systems.

=item * 'lifetime'

By default, Queue:::DBI will fetch elements regardless of how old they are. Use
this option to specify how old (in seconds) an element can be and still be
retrieved for processing.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;

	# Check parameters.
	foreach my $arg ( qw( queue_name database_handle ) )
	{
		croak "Argument '$arg' is needed to create the Queue::DBI object"
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	croak 'Argument "cleanup_timeout" must be an integer representing seconds'
		if defined( $args{'cleanup_timeout'} ) && ( $args{'cleanup_timeout'} !~ m/^\d+$/ );
	croak 'Argument "lifetime" must be an integer representing seconds'
		if defined( $args{'lifetime'} ) && ( $args{'lifetime'} !~ m/^\d+$/ );
	croak 'Argument "serializer_freeze" must be a code reference'
		if defined( $args{'serializer_freeze'} ) && !Data::Validate::Type::is_coderef( $args{'serializer_freeze'} );
	croak 'Argument "serializer_thaw" must be a code reference'
		if defined( $args{'serializer_thaw'} ) && !Data::Validate::Type::is_coderef( $args{'serializer_thaw'} );
	croak 'Arguments "serializer_freeze" and "serializer_thaw" must be defined together'
		if defined( $args{'serializer_freeze'} ) xor defined( $args{'serializer_thaw'} );

	# Create the object.
	my $dbh = $args{'database_handle'};
	my $self = bless(
		{
			'dbh'         => $dbh,
			'queue_name'  => $args{'queue_name'},
			'table_names' =>
			{
				'queues'         => $args{'queues_table_name'},
				'queue_elements' => $args{'queue_elements_table_name'},
			},
			'serializer' =>
			{
				'freeze'	=> $args{'serializer_freeze'},
				'thaw'		=> $args{'serializer_thaw'},
			}
		},
		$class
	);

	# Find the queue id.
	my $queue_id;
	{
		local $dbh->{'RaiseError'} = 1;
		my $data = $dbh->selectrow_arrayref(
			sprintf(
				q|
					SELECT queue_id
					FROM %s
					WHERE name = ?
				|,
				$dbh->quote_identifier( $self->get_queues_table_name() ),
			),
			{},
			$args{'queue_name'},
		);

		$queue_id = defined( $data ) && scalar( @$data ) != 0
			? $data->[0]
			: undef;
	}

	croak "The queue >$args{'queue_name'}< doesn't exist in the lookup table."
		unless defined( $queue_id ) && ( $queue_id =~ m/^\d+$/ );
	$self->{'queue_id'} = $queue_id;

	# Set optional parameters.
	$self->set_verbose( $args{'verbose'} );
	$self->set_max_requeue_count( $args{'max_requeue_count'} );
	$self->set_lifetime( $args{'lifetime'} );

	# Perform queue cleanup if a timeout is specified.
	$self->cleanup( $args{'cleanup_timeout'} )
		if defined( $args{'cleanup_timeout'} );

	return $self;
}


=head2 get_queue_id()

Returns the queue ID corresponding to the current queue object.

	my $queue_id = $queue->get_queue_id();

=cut

sub get_queue_id
{
	my ( $self ) = @_;

	return $self->{'queue_id'};
}


=head2 count()

Returns the number of elements in the queue.

	my $elements_count = $queue->count();

Optional parameter:

=over 4

=item * exclude_locked_elements

Exclude locked elements from the count. Default 0.

=back

	my $unlocked_elements_count = $queue->count(
		exclude_locked_elements => 1
	);

=cut

sub count
{
	my ( $self, %args ) = @_;
	my $exclude_locked_elements = delete( $args{'exclude_locked_elements'} ) || 0;

	my $verbose = $self->get_verbose();
	my $dbh = $self->get_dbh();
	carp "Entering count()." if $verbose;

	# Prepare optional additional clause to exclude locked elements.
	my $exclude_locked_elements_sql = $exclude_locked_elements
		? 'AND lock_time IS NULL'
		: '';

	# Count elements.
	my $element_count;
	{
		local $dbh->{'RaiseError'} = 1;
		my $data = $dbh->selectrow_arrayref(
			sprintf(
				q|
					SELECT COUNT(*)
					FROM %s
					WHERE queue_id = ?
						%s
				|,
				$dbh->quote_identifier( $self->get_queue_elements_table_name() ),
				$exclude_locked_elements_sql,
			),
			{},
			$self->get_queue_id(),
		);
		$element_count = defined( $data ) && scalar( @$data ) != 0 && defined( $data->[0] )
			? $data->[0]
			: 0;
	}

	carp "Found $element_count elements, leaving count()." if $verbose;

	return $element_count;
}


=head2 enqueue()

Adds a new element at the end of the current queue.

	# Store a scalar by passing its reference.
	my $queue_element_id = $queue->enqueue( \$string );
	my $queue_element_id = $queue->enqueue( \"string" );

	# Store an array reference.
	my $queue_element_id = $queue->enqueue( [ 1, 2, 3 ] );

	# Store a hash reference.
	my $queue_element_id = $queue->enqueue( { key => 123 } );

	# Store a complex datastructure.
	my $queue_element_id = $queue->enqueue(
		{
			values => [ 1, 2, 3 ],
			data   => { key1 => 1, key2 => 2 },
		}
	);

The data passed should be a reference to a scalar or a reference to a complex
data structure, but you cannot pass a scalar directly. There is otherwise no
limitation on the type of data that can be stored as it is serialized for
storage in the database.

=cut

sub enqueue
{
	my ( $self, $data ) = @_;
	my $verbose = $self->get_verbose();
	my $dbh = $self->get_dbh();
	carp "Entering enqueue()." if $verbose;
	carp "Data is: " . Dumper( $data ) if $verbose > 1;

	# Make sure the data passed is a reference. We don't support scalars, as
	# trying to store both scalars and references results in a mess documented in
	# GH-3.
	croak 'The data passed must be a reference, not a scalar'
		if !ref( $data );

	my $encoded_data = $self->freeze( $data );
	croak 'The size of the data to store exceeds the maximum internal storage size available.'
		if length( $encoded_data ) > $MAX_VALUE_SIZE;

	$dbh->do(
		sprintf(
			q|
				INSERT INTO %s( queue_id, data, created )
				VALUES ( ?, ?, ? )
			|,
			$dbh->quote_identifier( $self->get_queue_elements_table_name() ),
		),
		{},
		$self->get_queue_id(),
		$encoded_data,
		time(),
	) || croak 'Cannot execute SQL: ' . $dbh->errstr();

	# We need to reset the internal cached value preventing infinite loops, other-
	# wise this new element will not be taken into account by the current queue
	# object.
	$self->{'max_id'} = undef;

	carp "Element inserted, leaving enqueue()." if $verbose;

	return $dbh->last_insert_id(
		undef,
		undef,
		$self->get_queue_elements_table_name(),
		'queue_element_id',
	);
}


=head2 next()

Retrieves the next element from the queue and returns it in the form of a
Queue::DBI::Element object.

	my $queue_element = $queue->next();

	while ( my $queue_element = $queue->next() )
	{
		# [...]
	}

Additionally, for testing purposes, a list of IDs to use when trying to retrieve
elements can be specified using 'search_in_ids':

	my $queue_item = $queue->next( 'search_in_ids' => [ 123, 124, 125 ] );

=cut

sub next ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
	my ( $self, %args ) = @_;
	my $verbose = $self->get_verbose();
	carp "Entering next()." if $verbose;

	my $elements = $self->retrieve_batch(
		1,
		'search_in_ids' => defined( $args{'search_in_ids'} )
			? $args{'search_in_ids'}
			: undef,
	);

	my $return = defined( $elements ) && ( scalar( @$elements ) != 0 )
		? $elements->[0]
		: undef;

	carp "Leaving next()." if $verbose;
	return $return;
}


=head2 retrieve_batch()

Retrieves a batch of elements from the queue and returns them in an arrayref.

This method requires an integer to be passed as parameter to indicate the
maximum size of the batch to be retrieved.

	my $queue_elements = $queue->retrieve_batch( 500 );

	foreach ( @$queue_elements )
	{
		# [...]
	}

Additionally, for testing purposes, a list of IDs to use when trying to retrieve
elements can be specified using 'search_in_ids':

	my $queue_items = $queue->retrieve_batch(
		10,
		'search_in_ids' => [ 123, 124, 125 ],
	);

=cut

sub retrieve_batch
{
	my ( $self, $number_of_elements_to_retrieve, %args ) = @_;
	my $verbose = $self->get_verbose();
	my $dbh = $self->get_dbh();
	carp "Entering retrieve_batch()." if $verbose;

	# Check parameters
	croak 'The number of elements to retrieve from the queue is not properly formatted'
		unless defined( $number_of_elements_to_retrieve ) && ( $number_of_elements_to_retrieve =~ m/^\d+$/ );

	# Prevent infinite loops
	unless ( defined( $self->{'max_id'} ) )
	{
		my $max_id;
		{
			local $dbh->{'RaiseError'} = 1;
			my $data = $dbh->selectrow_arrayref(
				sprintf(
					q|
						SELECT MAX(queue_element_id)
						FROM %s
						WHERE queue_id = ?
					|,
					$dbh->quote_identifier( $self->get_queue_elements_table_name() ),
				),
				{},
				$self->get_queue_id(),
			);

			$max_id = defined( $data ) && scalar( @$data ) != 0
				? $data->[0]
				: undef;
		}

		if ( defined( $max_id ) )
		{
			$self->{'max_id'} = $max_id;
		}
		else
		{
			# Empty queue
			carp "Detected empty queue, leaving." if $verbose;
			return;
		}
	}

	# Prevent backtracking in case elements are requeued
	$self->{'last_id'} = -1
		unless defined( $self->{'last_id'} );

	# Detect end of queue quicker
	if ( $self->{'last_id'} == $self->{'max_id'} )
	{
		carp "Finished processing queue, leaving." if $verbose;
		return [];
	}

	# Make sure we don't use requeued elements more times than specified.
	my $max_requeue_count = $self->get_max_requeue_count();
	my $sql_max_requeue_count = defined( $max_requeue_count )
		? 'AND requeue_count <= ' . $dbh->quote( $max_requeue_count )
		: '';

	# Make sure we don't use elements that exceed the specified lifetime.
	my $lifetime = $self->get_lifetime();
	my $sql_lifetime = defined( $lifetime )
		? 'AND created >= ' . ( time() - $lifetime )
		: '';

	# If specified, retrieve only those IDs.
	my $ids = defined( $args{'search_in_ids'} )
		? 'AND queue_element_id IN (' . join( ',', map { $dbh->quote( $_ ) } @{ $args{'search_in_ids' } } ) . ')'
		: '';

	# Retrieve the first available elements from the queue.
	carp "Retrieving data." if $verbose;
	carp "Parameters:\n\tLast ID: $self->{'last_id'}\n\tMax ID: $self->{'max_id'}\n" if $verbose > 1;
	my $data = $dbh->selectall_arrayref(
		sprintf(
			q|
				SELECT queue_element_id, data, requeue_count, created
				FROM %s
				WHERE queue_id = ?
					AND lock_time IS NULL
					AND queue_element_id >= ?
					AND queue_element_id <= ?
					%s
					%s
					%s
				ORDER BY queue_element_id ASC
				LIMIT ?
			|,
			$dbh->quote_identifier( $self->get_queue_elements_table_name() ),
			$ids,
			$sql_max_requeue_count,
			$sql_lifetime,
		),
		{},
		$self->get_queue_id(),
		$self->{'last_id'} + 1,
		$self->{'max_id'},
		$number_of_elements_to_retrieve,
	);
	croak 'Cannot execute SQL: ' . $dbh->errstr() if defined( $dbh->errstr() );

	# All the remaining elements are locked
	return []
		if !defined( $data ) || ( scalar( @$data) == 0 );

	# Create objects
	carp "Creating new Queue::DBI::Element objects." if $verbose;
	my @return = ();
	foreach my $row ( @$data )
	{
		push(
			@return,
			Queue::DBI::Element->new(
				'queue'         => $self,
				'data'          => $self->thaw( $row->[1] ),
				'id'            => $row->[0],
				'requeue_count' => $row->[2],
				'created'       => $row->[3],
			)
		);
	}

	# Prevent backtracking in case elements are requeued
	$self->{'last_id'} = $return[-1]->id();

	carp "Leaving retrieve_batch()." if $verbose;
	return \@return;
}


=head2 get_element_by_id()

Retrieves a queue element using a queue element ID, ignoring any lock placed on
that element.

This method is mostly useful when doing a lock on an element and then calling
success/requeue asynchroneously.

This method requires a queue element ID to be passed as parameter.

	my $queue_element = $queue->get_element_by_id( 123456 );

=cut

sub get_element_by_id
{
	my ( $self, $queue_element_id ) = @_;
	my $verbose = $self->get_verbose();
	my $dbh = $self->get_dbh();
	carp "Entering get_element_by_id()." if $verbose;

	# Check parameters.
	croak 'A queue element ID is required by this method'
		unless defined( $queue_element_id );

	# Retrieve the specified element from the queue.
	carp "Retrieving data." if $verbose;
	my $data = $dbh->selectrow_hashref(
		sprintf(
			q|
				SELECT *
				FROM %s
				WHERE queue_id = ?
					AND queue_element_id = ?
			|,
			$dbh->quote_identifier( $self->get_queue_elements_table_name() ),
		),
		{},
		$self->get_queue_id(),
		$queue_element_id,
	);
	croak 'Cannot execute SQL: ' . $dbh->errstr() if defined( $dbh->errstr() );

	# Queue element ID doesn't exist or belongs to another queue.
	return unless defined( $data );

	# Create the Queue::DBI::Element object.
	carp "Creating a new Queue::DBI::Element object." if $verbose;

	my $queue_element = Queue::DBI::Element->new(
		'queue'         => $self,
		'data'          => $self->thaw( $data->{'data'} ),
		'id'            => $data->{'queue_element_id'},
		'requeue_count' => $data->{'requeue_count'},
		'created'       => $data->{'created'},
	);

	carp "Leaving get_element_by_id()." if $verbose;
	return $queue_element;
}


=head2 cleanup()

Requeue items that have been locked for more than the time in seconds specified
as parameter.

Returns the items requeued so that a specific action can be taken on them.

	my $elements = $queue->cleanup( $time_in_seconds );
	foreach my $element ( @$elements )
	{
		# $element is a Queue::DBI::Element object
	}

=cut

sub cleanup
{
	my ( $self, $time_in_seconds ) = @_;
	my $verbose = $self->get_verbose();
	my $dbh = $self->get_dbh();
	carp "Entering cleanup()." if $verbose;

	$time_in_seconds ||= '';
	croak 'Time in seconds is not correctly formatted'
		unless $time_in_seconds =~ m/^\d+$/;

	# Find all the orphans
	carp "Retrieving data." if $verbose;
	my $rows = $dbh->selectall_arrayref(
		sprintf(
			q|
				SELECT queue_element_id, data, requeue_count, created
				FROM %s
				WHERE queue_id = ?
					AND lock_time < ?
			|,
			$dbh->quote_identifier( $self->get_queue_elements_table_name() ),
		),
		{},
		$self->get_queue_id(),
		time() - $time_in_seconds,
	);
	croak 'Cannot execute SQL: ' . $dbh->errstr() if defined( $dbh->errstr() );
	return []
		unless defined( $rows );

	# Create objects and requeue them
	carp "Creating new Queue::DBI::Element objects." if $verbose;
	my $queue_elements = [];
	foreach my $row ( @$rows )
	{
		my $queue_element = Queue::DBI::Element->new(
			'queue'         => $self,
			'data'          => $self->thaw( $row->[1] ),
			'id'            => $row->[0],
			'requeue_count' => $row->[2],
			'created'       => $row->[3],
		);
		# If this item was requeued by another process since its
		# being SELECTed a moment ago, requeue() will return failure
		# and this process will ignore it.
		push( @$queue_elements, $queue_element )
			if $queue_element->requeue();
	}
	carp "Found " . scalar( @$queue_elements ) . " orphaned element(s)." if $verbose;

	carp "Leaving cleanup()." if $verbose;
	return $queue_elements;
}


=head2 purge()

Remove (permanently, caveat emptor!) queue elements based on how many times
they've been requeued or how old they are, and return the number of elements
deleted.

	# Remove permanently elements that have been requeued more than 10 times.
	my $deleted_elements_count = $queue->purge( max_requeue_count => 10 );

	# Remove permanently elements that were created over an hour ago.
	my $deleted_elements_count = $queue->purge( lifetime => 3600 );

Important: locked elements are not purged even if they match the criteria, as
they are presumed to be currently in process and purging them would create
unexpected failures in the application processing them.

Also note that I<max_requeue_count> and I<lifetime> cannot be combined.

=cut

sub purge
{
	my ( $self, %args ) = @_;
	my $verbose = $self->get_verbose();
	my $dbh = $self->get_dbh();
	carp "Entering cleanup()." if $verbose;

	my $max_requeue_count = $args{'max_requeue_count'};
	my $lifetime = $args{'lifetime'};

	# Check parameters.
	croak '"max_requeue_count" must be an integer'
		if defined( $max_requeue_count ) && ( $max_requeue_count !~ m/^\d+$/ );
	croak '"lifetime" must be an integer representing seconds'
		if defined( $lifetime ) && ( $lifetime !~ m/^\d+$/ );
	croak '"max_requeue_count" and "lifetime" cannot be combined, specify one OR the other'
		if defined( $lifetime ) && defined( $max_requeue_count );
	croak '"max_requeue_count" or "lifetime" must be specified'
		if !defined( $lifetime ) && !defined( $max_requeue_count );

	# Prepare query clauses.
	my $sql_lifetime = defined( $lifetime )
		? 'AND created < ' . ( time() - $lifetime )
		: '';
	my $sql_max_requeue_count = defined( $max_requeue_count )
		? 'AND requeue_count > ' . $dbh->quote( $max_requeue_count )
		: '';

	# Purge the queue.
	my $rows_deleted = $dbh->do(
		sprintf(
			q|
				DELETE
				FROM %s
				WHERE queue_id = ?
					AND lock_time IS NULL
					%s
					%s
			|,
			$dbh->quote_identifier( $self->get_queue_elements_table_name() ),
			$sql_lifetime,
			$sql_max_requeue_count,
		),
		{},
		$self->get_queue_id(),
	) || croak 'Cannot execute SQL: ' . $dbh->errstr();

	carp "Leaving cleanup()." if $verbose;
	# Account for '0E0' which means no rows affected, and translates into no
	# rows deleted in our case.
	return $rows_deleted eq '0E0'
		? 0
		: $rows_deleted;
}


=head1 ACCESSORS

=head2 get_max_requeue_count()

Return how many times an element can be requeued before it is ignored when
retrieving elements.

	my $max_requeue_count = $queue->get_max_requeue_count();

=cut

sub get_max_requeue_count
{
	my ( $self ) = @_;

	return $self->{'max_requeue_count'};
}


=head2 set_max_requeue_count()

Set the number of time an element can be requeued before it is ignored when
retrieving elements. Set it to C<undef> to disable the limit.

	# Don't keep pulling the element if it has been requeued more than 5 times.
	$queue->set_max_requeue_count( 5 );+

	# Retry without limit.
	$queue->set_max_requeue_count( undef );

=cut

sub set_max_requeue_count
{
	my ( $self, $max_requeue_count ) = @_;

	croak 'max_requeue_count must be an integer or undef'
		if defined( $max_requeue_count ) && ( $max_requeue_count !~ /^\d+$/ );

	$self->{'max_requeue_count'} = $max_requeue_count;

	return;
}


=head2 get_lifetime()

Return how old an element can be before it is ignored when retrieving elements.

	# Find how old an element can be before the queue will stop retrieving it.
	my $lifetime = $queue->get_lifetime();

=cut

sub get_lifetime
{
	my ( $self ) = @_;

	return $self->{'lifetime'};
}


=head2 set_lifetime()

Set how old an element can be before it is ignored when retrieving elements.

Set it to C<undef> to reset Queue::DBI back to its default behavior of
retrieving elements without time limit.

	# Don't pull queue elements that are more than an hour old.
	$queue->set_lifetime( 3600 );

	# Pull elements without time limit.
	$queue->set_lifetime( undef );

=cut

sub set_lifetime
{
	my ( $self, $lifetime ) = @_;

	croak 'lifetime must be an integer or undef'
		if defined( $lifetime ) && ( $lifetime !~ /^\d+$/ );

	$self->{'lifetime'} = $lifetime;

	return;
}


=head2 get_verbose()

Return the verbosity level, which is used in the module to determine when and
what type of debugging statements / information should be warned out.

See C<set_verbose()> for the possible values this function can return.

	warn 'Verbose' if $queue->get_verbose();

	warn 'Very verbose' if $queue->get_verbose() > 1;

=cut

sub get_verbose
{
	my ( $self ) = @_;

	return $self->{'verbose'};
}


=head2 set_verbose()

Control the verbosity of the warnings in the code:

=over 4

=item * 0 will not display any warning;

=item * 1 will only give one line warnings about the current operation;

=item * 2 will also usually output the SQL queries performed.

=back

	$queue->set_verbose(1); # turn on verbose information

	$queue->set_verbose(2); # be extra verbose

	$queue->set_verbose(0); # quiet now!

=cut

sub set_verbose
{
	my ( $self, $verbose ) = @_;

	$self->{'verbose'} = ( $verbose || 0 );

	return;
}


=head1 INTERNAL METHODS

=head2 freeze()

Serialize an element to store it in a SQL "text" column.

	my $frozen_data = $queue->freeze( $data );

=cut

sub freeze
{
	my ( $self, $data ) = @_;

	return defined( $self->{'serializer'} ) && defined( $self->{'serializer'}->{'freeze'} )
		? $self->{'serializer'}->{'freeze'}($data)
		: MIME::Base64::encode_base64( Storable::freeze( $data ) );
}

=head2 thaw()

Deserialize an element which was stored a SQL "text" column.

	my $thawed_data = $queue->thaw( $frozen_data );

=cut

sub thaw
{
	my ( $self, $data ) = @_;

	return defined( $self->{'serializer'} ) && defined( $self->{'serializer'}->{'thaw'} )
		? $self->{'serializer'}->{'thaw'}($data)
		: Storable::thaw( MIME::Base64::decode_base64( $data ) );
}


=head1 DEPRECATED METHODS

=head2 create_tables()

Please use C<create_tables()> in L<Queue::DBI::Admin> instead.

Here is an example that shows how to refactor your call to this deprecated
function:

	# Load the admin module.
	use Queue::DBI::Admin;

	# Create the object which will allow managing the queues.
	my $queues_admin = Queue::DBI::Admin->new(
		database_handle => $dbh,
	);

	# Create the tables required by Queue::DBI to store the queues and data.
	$queues_admin->create_tables(
		drop_if_exist => $boolean,
	);

=cut

sub create_tables
{
	croak 'create_tables() in Queue::DBI has been deprecated, please use create_tables() in Queue::DBI::Admin instead.';
}


=head2 lifetime()

Please use C<get_lifetime()> and C<set_lifetime()> instead.

=cut

sub lifetime
{
	croak 'lifetime() has been deprecated, please use get_lifetime() / set_lifetime() instead.';
}


=head2 verbose()

Please use C<get_verbose()> and C<set_verbose()> instead.

=cut

sub verbose
{
	croak 'verbose() has been deprecated, please use get_verbose() / set_verbose() instead.';
}


=head2 max_requeue_count()

Please use C<get_max_requeue_count()> and C<set_max_requeue_count()> instead.

=cut

sub max_requeue_count
{
	croak 'max_requeue_count() has been deprecated, please use get_max_requeue_count() / set_max_requeue_count() instead.';
}


=head1 INTERNAL METHODS

=head2 get_dbh()

Returns the database handle used for this queue.

	my $dbh = $queue->get_dbh();

=cut

sub get_dbh
{
	my ( $self ) = @_;

	return $self->{'dbh'};
}


=head2 get_queues_table_name()

Returns the name of the table used to store queue definitions.

	my $queues_table_name = $queue->get_queues_table_name();

=cut

sub get_queues_table_name
{
	my ( $self ) = @_;

	return defined( $self->{'table_names'}->{'queues'} ) && ( $self->{'table_names'}->{'queues'} ne '' )
		? $self->{'table_names'}->{'queues'}
		: $DEFAULT_QUEUES_TABLE_NAME;
}


=head2 get_queue_elements_table_name()

Returns the name of the table used to store queue definitions.

	my $queue_elements_table_name = $queue->get_queue_elements_table_name();

=cut

sub get_queue_elements_table_name
{
	my ( $self ) = @_;

	return defined( $self->{'table_names'}->{'queue_elements'} ) && ( $self->{'table_names'}->{'queue_elements'} ne '' )
		? $self->{'table_names'}->{'queue_elements'}
		: $DEFAULT_QUEUE_ELEMENTS_TABLE_NAME;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Queue-DBI/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Queue::DBI


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

I originally developed this project for ThinkGeek
(L<http://www.thinkgeek.com/>). Thanks for allowing me to open-source it!


=head1 COPYRIGHT & LICENSE

Copyright 2009-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
