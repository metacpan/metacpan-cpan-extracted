package MongoDBx::Class::ConnectionPool::Backup;

# ABSTARCT: A simple connection pool with a backup connection

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use Carp;

with 'MongoDBx::Class::ConnectionPool';

=head1 NAME

MongoDBx::Class::ConnectionPool::Backup - A simple connection pool with a backup connection

=head1 VERSION

version 1.030002

=head1 SYNOPSIS

	# create a MongoDBx::Class object normally:
	use MongoDBx::Class;
	my $dbx = MongoDBx::Class->new(namespace => 'MyApp::Model::DB');

	# instead of connection, create a pool
	my $pool = $dbx->pool(max_conns => 200, type => 'backup'); # max_conns defaults to 100

	# or, if you need to pass attributes to MongoDB::Connection->new():
	my $pool = $dbx->pool(max_conns => 200, type => 'backup', params => {
		host => $host,
		username => $username,
		password => $password,
	});

	# get a connection from the pool on a per-request basis
	my $conn = $pool->get_conn;

	# ... do stuff with $conn and return it when done ...

	$pool->return_conn($conn);

=head1 DESCRIPTION

MongoDBx::Class::ConnectionPool::Backup is an implementation of the
L<MongoDBx::Class::ConnectionPool> L<Moose role|Moose::Role>. In this
implementation, the pool has a maximum number of connections. Whenever
someone makes a request for a connection, an existing connection is taken
out of the pool and returned (or created if none are available and the
maximum has not been reached). When the requester is done with the connection,
they are expected to return the connection to the pool. If a connection
is not available for the requester (i.e. the maximum has been reached and
all connections are used), a backup connection is returned. This backup
connection can be shared by multiple requesters, but the pool's main connections
cannot.

This pool is most appropriate for larger pools where you do not wish to
share connections between clients, but want to ensure that on the rare
occasions that all connections are used, requests will still be honored.

=head1 CONSUMES

L<MongoDBx::Class::ConnectionPool>

=head1 ATTRIBUTES

The following attributes are added:

=head2 backup_conn

The backup L<MongoDBx::Class::Connection> object.

=cut

has 'backup_conn' => (
	is => 'ro',
	isa => 'MongoDBx::Class::Connection',
	writer => '_set_backup',
);

=head1 METHODS

=head2 get_conn()

Returns a connection from the pool to a requester. If a connection is not
available but the maximum has not been reached, a new connection is made,
otherwise the backup connection is returned.

=cut

sub get_conn {
	my $self = shift;

	# are there available connections in the pool?
	if (scalar @{$self->pool}) {
		return $self->_take_from_pool;
	}

	# there aren't any, can we create a new connection?
	if ($self->num_used < $self->max_conns) {
		# yes we can, let's create it
		return $self->_get_new_conn;
	}

	# no more connections, return backup conn
	return $self->backup_conn;
}

=head2 return_conn( $conn )

Returns a connection to the pool. If a client attempts to return the
backup connection, nothing will happen (the backup connection is always
saved).

=cut

sub return_conn {
	my ($self, $conn) = @_;

	# do not return the backup connection
	return if $conn->is_backup;

	# only add connection if pool isn't full, otherwise discard it
	if (scalar @{$self->pool} + $self->num_used - 1 < $self->max_conns) {
		$self->_add_to_pool($conn);
		$self->_inc_used(-1);
	}
}

=head1 INTERNAL METHODS

=head2 BUILD()

Called by Moose after object initiation.

=cut

sub BUILD {
	my $self = shift;

	my %params = %{$self->params};
	$params{is_backup} = 1;
	$self->_set_backup(MongoDBx::Class::Connection->new(%params));
}

sub _take_from_pool {
	my $self = shift;

	my $pool = $self->pool;
	my $conn = shift @$pool;
	$self->_set_pool($pool);
	$self->_inc_used;
	return $conn;
}

around 'get_conn' => sub {
	my ($orig, $self) = @_;

	return $self->$orig || $self->backup_conn;
};

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::ConnectionPool::Backup

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

__PACKAGE__->meta->make_immutable;
