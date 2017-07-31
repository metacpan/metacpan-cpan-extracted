package Pg::Queue;

use strict;
use warnings;

use DBI;
use Moo;

use version; our $VERSION = qv('1.0');

has dbh => (
	is => 'rw',
	required => 1,
);

has queuename => (
	is => 'rw',
	default => sub { "queuetest" },
);


sub create_queue_table {
	my( $self ) = @_;
	my $dbh = $self->dbh;
	my $name = $self->queuename;

	$dbh->do("DROP TABLE IF EXISTS $name");

	$dbh->do(<<SQL);
	CREATE TABLE $name (
		id SERIAL PRIMARY KEY,
		available BOOLEAN DEFAULT TRUE,
		processed TIMESTAMP,
		item TEXT
	)
SQL

	$dbh->do("CREATE INDEX ${name}_available_idx ON $name (id) WHERE available");
}

sub add_work_item {
	my( $self, $item ) = @_;

	$self->dbh->do("INSERT INTO ${\$self->queuename} (item) VALUES (?)",undef, $item);
}

sub pull_work_item {
	my( $self, $callback ) = @_;
	my $dbh = $self->dbh;
	my $name = $self->queuename;

	$dbh->do("BEGIN");

	my $row = $dbh->selectrow_arrayref( 
		"UPDATE $name SET available=false 
		WHERE id = (
			SELECT id FROM $name 
			WHERE available 
			ORDER BY id 
			LIMIT 1
			FOR UPDATE SKIP LOCKED
		) RETURNING id,item" 
	);

	if( $row and $callback->(@$row) ) {
		$dbh->do("UPDATE $name SET processed=NOW() where id = ?", undef, $row->[0]);
		$dbh->do("COMMIT");
		return 1; #TRUE
	}
	else {
		$dbh->do("ROLLBACK");
		return 0; #FALSE
	}
}

sub count_total {
	my( $self ) = @_;

	my $row = $self->dbh->selectrow_arrayref( "SELECT count(*) FROM ${\$self->queuename}" );

	return $row->[0];
}

sub count_available {
	my( $self ) = @_;

	my $row = $self->dbh->selectrow_arrayref( "SELECT count(*) FROM ${\$self->queuename} WHERE available" );

	return $row->[0];
}


1;
__END__

=head1 NAME

Pg::Queue - Simple SKIP LOCKED based Queue for Postgresql


=head1 VERSION

This document describes Pg::Queue version 1.0


=head1 SYNOPSIS

	use Pg::Queue;
	use DBI;

	my $dbh = DBI->connect("dbi:Pg:dbname=database", "", "", {AutoCommit=>1, RaiseError=>1})
		or die "DBI FAILURE $DBI::errstr";
	
	my $queue = Pg::Queue->new( dbh => $dbh, queuename => "myqueue" );

	$queue->create_queue_table;

	for( 0 .. 10 ) {
		$queue->add_work_item( "work item $_" );
	}

	while( 1 ) { # We don't know how many queue items are remaining
		my $processed = $queue->pull_work_item(sub{
			my($id,$item) =  @_;
			print "$item has id $id\n";
			return 1;
		});

		last unless $processed; #Exit when there's no more queue items
		                        # Or just sleep and try again
	}

  
=head1 DESCRIPTION

This module provides an OO interface to a Postgresql table which implements a simple yet highly 
concurrent queue via the new 9.5 feature "SKIP LOCKED". For further details on how SKIP LOCKED 
works, see L<https://www.postgresql.org/docs/current/static/sql-select.html#SQL-FOR-UPDATE-SHARE>. 
For information using it to implement a queue, see 
L<https://blog.2ndquadrant.com/what-is-select-skip-locked-for-in-postgresql-9-5/>.


=head1 INTERFACE 

=over

=item new( dbh => $dbh, queuename => NAME );

=over

=item C<$dbh> 

A connected DBI database handle to a postgresql database.

=item queuename 

The name of the table in the database to use as a queue.

This can be the name of an existing table or you can call c<create_queue_table> to create it.

=back

=item create_queue_table

Attempts to create a table for the queue using the c<queuename> set during construction.
B<WILL DROP TABLE IF IT EXISTS>

The queue table created will have the following columns:

=over

=item id (serial)

Auto-incrementing integer id

=item available (boolean)

Used to tell if the queue item is available to be fetched by a worker. This will only actually be 
set to false if the callback returns true. Must default to false. Note that the locking mechanism 
employed prevents concurrent workers from fetching the same item while it is being processed.

=item processed (timestamp)

Automatically set to C<NOW()> when the callback returns true and available is set to false.

=item item (text)

An opaque field containing data to be passed to the worker's callback.

=back

=item add_work_item($data)

Takes a single scalar to be used as the value of the C<item> column in the queue table and inserts 
a new row into the configured queue table.

=item pull_work_item($callback)

Takes a callback that will be called with two items, the C<id> of the row and the contents of the 
C<item> column. The callback must return true to signal that it has successfully processed the 
queue item and to prevent other workers from attempting to process it. 

The callback operates inside the transaction used to fetch the queue item so any database changes 
made will be lost if you return false or throw an exception unless you manually commit.

=item count_total

Returns the C<count(*)> from the queue table

=item count_available

Returns the C<count(*) WHERE available> from the queue table

=back

The created table will also have an index on id WHERE available; which utilizes PostgreSQL 
"partial" indexes to speed up finding an available queue item.

=head1 DEPENDENCIES

Requires PostgreSQL 9.5 for the SKIP LOCKED feature.

=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-<RT NAME>@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Robert Grimes  C<rmzgrimes@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017, Robert Grimes C<rmzgrimes@gmail.com>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
