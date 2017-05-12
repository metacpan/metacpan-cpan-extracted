package MongoDBx::Class::ConnectionPool;

# ABSTARCT: A simple connection pool for MongoDBx::Class

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose::Role;
use namespace::autoclean;
use Carp;

=head1 NAME

MongoDBx::Class::ConnectionPool - A simple connection pool for MongoDBx::Class

=head1 VERSION

version 1.030002

=head1 SYNOPSIS

	# create a MongoDBx::Class object normally:
	use MongoDBx::Class;
	my $dbx = MongoDBx::Class->new(namespace => 'MyApp::Model::DB');

	# instead of connection, create a rotated pool
	my $pool = $dbx->pool(max_conns => 200, type => 'rotated'); # max_conns defaults to 100

	# or, if you need to pass attributes to MongoDB::Connection->new():
	my $pool = $dbx->pool(max_conns => 200, type => 'rotated', params => {
		host => $host,
		username => $username,
		password => $password,
		...
	});

	# get a connection from the pool on a per-request basis
	my $conn = $pool->get_conn;

	# ... do stuff with $conn and return it when done ...

	$pool->return_conn($conn); # only relevant on backup pools but a good practice anyway

=head1 DESCRIPTION

WARNING: connection pooling via MongoDBx::Class is experimental. It is a
quick, simple implementation that may or may not work as expected.

MongoDBx::Class::ConnectionPool is a very simple interface for creating
MongoDB connection pools. The basic idea is: create a pool with a maximum
number of connections as a setting. Give connections from the pool on a per-request
basis. The pool is empty at first, and connections are created for each
request, until the maximum is reached. The behaviour of the pool when this
maximum is reached is dependant on the implementation. There are currently
two implementations:

=over

=item * Rotated pools (L<MongoDBx::Class::ConnectionPool::Rotated>) - these
pools hold at most the number of maximum connections defined. An index is
held, initially starting at zero. When a request for a connection is made,
the connection located at the current index is returned (if exists, otherwise
a new one is created), and the index is incremented. When the index reaches the
end of the pool, it returns to the beginning (i.e. zero), and the next
request will receive the first connection in the pool, and so on. This means
that every connection in the pool can be shared by an unlimited number of
requesters.

=item * Backup pools (L<MongoDBx::Class::ConnectionPool::Backup>) - these
pools expect the receiver of a connection to return it when they're done
using it. If no connections are available when a request is made (i.e.
all connections are being used), a backup connection is returned (there
can be only one backup connection). This means that every connection in
the pool can be used by one requester, except for the backup connection
which can be shared.

=back

The rotated pool makes more sense for pools with a relatively low number
of connections, while the backup pool is more fit for a larger number of
connections. The selection should be based, among other factors, on your
application's metrics: how many end-users (e.g. website visitors) use your
application concurrently? does your application experience larger loads
and usage numbers at certain points of the day/week? does it make more
sense for you to balance work between a predefined number of connections
(rotated pool) or do you prefer each end-user to get their own connection
(backup pool)?

At any rate, every end-user will receive a connection, shared or not.

=head1 ATTRIBUTES

=head2 max_conns

An integer defining the maximum number of connections a pool can hold.
Defaults to 100.

=head2 pool

An array-reference of L<MongoDBx::Class::Connection> objects, this is the
actual pool. Mostly used and populated internally.

=head2 num_used

For backup pools, this will be an integer indicating the number of connections
from the pool currently being used. For rotated pools, this will be the index
of the connection to be given to the next end-user.

=head2 params

A hash-ref of parameters to pass to C<< MongoDB::Connection->new() >> when
creating a new connection. See L<MongoDB::Connection/"ATTRIBUTES"> for
more information.

=cut

has 'max_conns' => (
	is => 'ro',
	isa => 'Int',
	default => 100,
);

has 'pool' => (
	is => 'ro',
	isa => 'ArrayRef[MongoDBx::Class::Connection]',
	writer => '_set_pool',
	default => sub { [] },
);

has 'num_used' => (
	is => 'ro',
	isa => 'Int',
	writer => '_set_used',
	default => 0,
);

has 'params' => (
	is => 'ro',
	isa => 'HashRef',
	required => 1,
);

=head1 REQUIRED METHODS

This L<Moose role|Moose::Role> requires consuming classes to implement
the following methods:

=over

=item * get_conn()

Returns a connection from the pool to a requester, possibly creating a
new one in the process if no connections are available and the maximum
has not been reached yet.

=item * return_conn( $conn )

Returns a connection (receievd via C<get_conn()>) to the pool, meant to
be called by the end-user after being done with the connection. Only relevant
when C<get_conn()> actually takes the connection out of the pool (so it
is not shared), like with backup pools. Otherwise this method may do nothing.

=back

=cut

requires 'get_conn';
requires 'return_conn';

=head1 PROVIDED METHODS

Meant to be used by consuming classes:

=head2 _get_new_conn()

Creates a new L<MongoDBx::Class::Connection> object, increments the C<num_used>
attribute, and returns the new connection. Should be used by C<get_conn()>.

=cut

sub _get_new_conn {
	my $self = shift;

	my $conn = MongoDBx::Class::Connection->new(%{$self->params});
	$self->_inc_used;
	return $conn;
}

=head2 _inc_used( [ $int ] )

Increases the C<num_used> attribute by C<$int> (which can be negative),
or by 1 if C<$int> is not supplied.

=cut

sub _inc_used {
	my ($self, $int) = @_;

	$int ||= 1;
	$self->_set_used($self->num_used + $int);
}

=head2 _add_to_pool( $conn )

Adds a connection object to the end of the pool (the C<pool> attribute).

=cut

sub _add_to_pool {
	my ($self, $conn) = @_;

	my $pool = $self->pool;
	push(@$pool, $conn);
	$self->_set_pool($pool);
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::ConnectionPool

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongoDBx::Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongoDBx::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongoDBx::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/MongoDBx::Class/>

=back

=head1 SEE ALSO

L<MongoDBx::Class>, L<MongoDB::Connection>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
