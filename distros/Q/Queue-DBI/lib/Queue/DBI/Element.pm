package Queue::DBI::Element;

use warnings;
use strict;

use Data::Dumper;
use Carp;


=head1 NAME

Queue::DBI::Element - An object representing an element pulled from the queue.


=head1 VERSION

Version 2.7.0

=cut

our $VERSION = '2.7.0';


=head1 SYNOPSIS

Please refer to the documentation for Queue::DBI.

=head1 METHODS

=head2 new()

Create a new Queue::DBI::Element object.

	my $element = Queue::DBI::Element->new(
		'queue'         => $queue,
		'data'          => $data,
		'id'            => $id,
		'requeue_count' => $requeue_count,
		'created'       => $created,
	);

All parameters are mandatory and correspond respectively to the Queue::DBI
object used to pull the element's data, the data, the ID of the element
in the database and the number of times the element has been requeued before.

It is not recommended for direct use. You should be using the following to get
Queue::DBI::Element objects:

	my $queue = $queue->next();

=cut

sub new
{
	my ( $class, %args ) = @_;

	# Check parameters
	foreach my $arg ( qw( data id requeue_count created ) )
	{
		croak "Argument '$arg' is needed to create the Queue::DBI object"
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	croak 'Pass a Queue::DBI object to create an Queue::DBI::Element object'
		unless defined( $args{'queue'} ) && $args{'queue'}->isa( 'Queue::DBI' );

	# Create the object
	my $self = bless(
		{
			'queue'         => $args{'queue'},
			'data'          => $args{'data'},
			'id'            => $args{'id'},
			'requeue_count' => $args{'requeue_count'},
			'created'       => $args{'created'},
		},
		$class
	);

	return $self;
}


=head2 lock()

Locks the element so that another process acting on the queue cannot get a hold
of it

	if ( $element->lock() )
	{
		print "Element successfully locked.\n";
	}
	else
	{
		print "The element has already been removed or locked.\n";
	}

=cut

sub lock ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
	my ( $self ) = @_;
	my $queue = $self->get_queue();
	my $verbose = $queue->get_verbose();
	my $dbh = $queue->get_dbh();
	carp "Entering lock()." if $verbose;

	my $rows = $dbh->do(
		sprintf(
			q|
				UPDATE %s
				SET lock_time = ?
				WHERE queue_element_id = ?
					AND lock_time IS NULL
			|,
			$dbh->quote_identifier( $queue->get_queue_elements_table_name() ),
		),
		{},
		time(),
		$self->id(),
	) || croak 'Cannot lock element: ' . $dbh->errstr;

	my $success = ( defined( $rows ) && ( $rows == 1 ) ) ? 1 : 0;
	carp "Element locked: " . ( $success ? 'success' : 'already locked or gone' ) . "." if $verbose;

	carp "Leaving lock()." if $verbose;
	return $success;
}


=head2 requeue()

In case the processing of an element has failed

	if ( $element->requeue() )
	{
		print "Element successfully requeued.\n";
	}
	else
	{
		print "The element has already been removed or been requeued.\n";
	}

=cut

sub requeue
{
	my ( $self ) = @_;
	my $queue = $self->get_queue();
	my $verbose = $queue->get_verbose();
	my $dbh = $queue->get_dbh();
	carp "Entering requeue()." if $verbose;

	my $rows = $dbh->do(
		sprintf(
			q|
				UPDATE %s
				SET
					lock_time = NULL,
					requeue_count = requeue_count + 1
				WHERE queue_element_id = ?
					AND lock_time IS NOT NULL
			|,
			$dbh->quote_identifier( $queue->get_queue_elements_table_name() ),
		),
		{},
		$self->id(),
	);

	# Since Queue::DBI does not enclose the SELECTing of a queue_element
	# to be requeued, and this actual requeueing, it is possible for the
	# element to be requeued by another process in-between. It may even
	# be requeued, relocked, and successfully removed in-between. In either
	# case, the number of rows affected would be 0, and do() would return
	# 0E0, perl's "0 but true" value. This is not an error. However, if
	# -1 or undef is returned, DBI.pm encountered some sort of error.
	if ( ! defined( $rows ) || $rows == -1 )
	{
		# Always carp the information, since it is an error that
		# most likely doesn't come from this module.
		my $error = $dbh->errstr();
		carp 'Cannot requeue element: ' . ( defined( $error ) ? $error : 'no error returned by DBI' );
		return 0;
	}

	my $requeued = ( $rows == 1 ) ? 1 : 0;
	carp "Element requeued: " . ( $requeued ? 'done' : 'already requeued or gone' ) . "." if $verbose;

	# Update the requeue_count on the object as well if the database update was
	# successful.
	$self->{'requeue_count'}++
		if $requeued;

	carp "Leaving requeue()." if $verbose;
	return $requeued;
}


=head2 success()

Removes the element from the queue after its processing has successfully been
completed.

	if ( $element->success() )
	{
		print "Element successfully removed from queue.\n";
	}
	else
	{
		print "The element has already been removed.\n";
	}

=cut

sub success
{
	my ( $self ) = @_;
	my $queue = $self->get_queue();
	my $verbose = $queue->get_verbose();
	my $dbh = $queue->get_dbh();
	carp "Entering success()." if $verbose;

	# Possible improvement:
	# Add $self->{'lock_time'} in lock() and insist that it matches that value
	# when trying to delete the element here.

	# First, we try to delete the LOCKED element.
	my $rows = $dbh->do(
		sprintf(
			q|
				DELETE
				FROM %s
				WHERE queue_element_id = ?
					AND lock_time IS NOT NULL
			|,
			$dbh->quote_identifier( $queue->get_queue_elements_table_name() ),
		),
		{},
		$self->id(),
	);

	if ( ! defined( $rows ) || $rows == -1 )
	{
		croak 'Cannot remove element: ' . $dbh->errstr();
	}

	my $success = 0;
	if ( $rows == 1 )
	{
		# A LOCKED element was found and deleted, this is a success.
		carp "Found a LOCKED element and deleted it. Element successfully processed." if $verbose;
		$success = 1;
	}
	else
	{
		# No LOCKED element found to delete, try to find an UNLOCKED one in case it
		# got requeued by a parallel process.
		my $deleted_rows = $dbh->do(
			sprintf(
				q|
					DELETE
					FROM %s
					WHERE queue_element_id = ?
				|,
				$dbh->quote_identifier( $queue->get_queue_elements_table_name() ),
			),
			{},
			$self->id(),
		);

		if ( ! defined( $deleted_rows ) || $deleted_rows == -1 )
		{
			croak 'Cannot remove element: ' . $dbh->errstr;
		}

		if ( $deleted_rows == 1 )
		{
			# An UNLOCKED element was found and deleted. It probably means that
			# another process is still working on that element as well (possibly
			# because this element's lock timed-out, got cleaned up and picked by
			# another process).
			# Always carp for those, technically we processed the element successfully
			# so deleting it is the correct step to take, but we still want to throw
			# some warning for the user.
			carp 'Another process is probably working on the same element, as it was found UNLOCKED when we deleted it. '
				. 'Check parallelization issues in your code!';
			$success = 1;
		}
		else
		{
			# No element found at all. It probably means that another process had been
			# working on that element, but completed successfully its run and deleted
			# it.
			carp 'Another process has probably worked on this element and already deleted it after completing its operations. '
				. 'Check parallelization issues in your code!' if $verbose;
			$success = 0;
		}
	}

	carp "Leaving success()." if $verbose;
	return $success;
}


=head2 data()

Returns the data initially queued.

	my $data = $element->data();

=cut

sub data
{
	my ( $self ) = @_;

	return $self->{'data'};
}


=head2 requeue_count()

Returns the number of times that the current element has been requeued.

	my $requeue_count = $element->requeue_count();

=cut

sub requeue_count
{
	my ( $self ) = @_;

	return $self->{'requeue_count'};
}


=head2 id()

Returns the ID of the current element

	my $id = $element->id();

=cut

sub id
{
	my ( $self ) = @_;

	return $self->{'id'};
}


=head2 get_created_time()

Returns the unixtime at which the element was originally created.

	my $created = $element->get_created_time();

=cut

sub get_created_time
{
	my ( $self ) = @_;

	return $self->{'created'};
}


=head2 is_over_lifetime()

Returns a boolean indicating whether the current element is over the lifetime
specified when instanciating the queue. This is especially helpful if you
retrieve a large batch of elements and do long processing operations on each
of them.

	my $is_over_lifetime = $element->is_over_lifetime();

=cut

sub is_over_lifetime
{
	my ( $self ) = @_;
	my $queue = $self->get_queue();
	my $lifetime = $queue->get_lifetime();

	# If the queue doesn't a lifetime, an element will never "expire".
	return 0 if !defined( $lifetime );

	# Check the time the element was created.
	my $created_time = $self->get_created_time();
	return time() - $created_time > $lifetime;
}


=head1 INTERNAL METHODS

=head2 get_queue()

Returns the Queue::DBI object used to pull the current element.

	my $queue = $element->get_queue();

=cut

sub get_queue
{
	my ( $self ) = @_;

	return $self->{'queue'};
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Queue-DBI/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Queue::DBI::Element


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
