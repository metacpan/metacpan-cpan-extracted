package MongoDBx::Class::ConnectionPool::Rotated;

# ABSTARCT: A simple connection pool with rotated connections

our $VERSION = "1.030002";
$VERSION = eval $VERSION;

use Moose;
use namespace::autoclean;
use Carp;
use Try::Tiny;

with 'MongoDBx::Class::ConnectionPool';

=head1 NAME

MongoDBx::Class::ConnectionPool::Rotated - A simple connection pool with rotated connections

=head1 VERSION

version 1.030002

=head1 SYNOPSIS

	# create a MongoDBx::Class object normally:
	use MongoDBx::Class;
	my $dbx = MongoDBx::Class->new(namespace => 'MyApp::Model::DB');

	# instead of connection, create a pool
	my $pool = $dbx->pool(max_conns => 200, type => 'rotated'); # max_conns defaults to 100

	# or, if you need to pass attributes to MongoDB::Connection->new():
	my $pool = $dbx->pool(max_conns => 200, type => 'rotated', params => {
		host => $host,
		username => $username,
		password => $password,
	});

	# get a connection from the pool on a per-request basis
	my $conn = $pool->get_conn;

	# ... do stuff with $conn and return it when done ...

	$pool->return_conn($conn); # not really needed, but good practice for future proofing and quick pool type switching

=head1 DESCRIPTION

MongoDBx::Class::ConnectionPool::Rotated is an implementation of the
L<MongoDBx::Class::ConnectionPool> L<Moose role|Moose::Role>. In this
implementation, the pool has a maximum number of connections. An index is
kept, and whenever someone makes a request for a connection, the connection
at the current index is returned (but not taken out of the pool, as opposed
to L<backup pools|MongoDBx::Class::ConnectionPool::Backup>), and the index
is raised. If a connection does not exist yet at the current index and the
maximum has not been reached, a new connections is created, added to the
pool and returned. If the maximum has been reached and the index is at the
end, it is rotated to the beginning, and the first connection in the pool
is returned. Therefore, every connection in the pool can be shared by an
unlimited number of requesters.

This pool is most appropriate for smaller pools where you want to distribute
the workload between a set of connections and you don't mind sharing.

=head1 CONSUMES

L<MongoDBx::Class::ConnectionPool>

=head1 METHODS

=head2 get_conn()

Returns the connection at the current index and raises the index. If no
connection is available at that index and the maximum has not been reached
yet, a new connection will be created. If the index is at the end, it is
returned to the beginning and the first connection from the pool is returned.

=cut

sub get_conn {
	my $self = shift;

	# are there available connections in the pool?
	if (scalar @{$self->pool} == $self->max_conns && $self->num_used < $self->max_conns) {
		return $self->_take_from_pool;
	}

	# there aren't any, can we create a new connection?
	if ($self->num_used < $self->max_conns) {
		# yes we can, let's create it
		return $self->_get_new_conn;
	}

	# no more connections, rotate to the beginning
	$self->_set_used(0);
	return $self->_take_from_pool;
}

=head2 return_conn()

Doesn't do anything in this implementation but required by L<MongoDBx::Class::ConnectionPool>.

=cut

sub return_conn { return }

sub _take_from_pool {
	my $self = shift;

	my $conn = $self->pool->[$self->num_used];
	$self->_inc_used;
	return $conn;
}

around '_get_new_conn' => sub {
	my ($orig, $self) = @_;

	my $conn = $self->$orig;
	my $pool = $self->pool;
	push(@$pool, $conn);
	$self->_set_pool($pool);
	return $conn;
};

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongodbx-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongoDBx-Class>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MongoDBx::Class::ConnectionPool::Rotated

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
