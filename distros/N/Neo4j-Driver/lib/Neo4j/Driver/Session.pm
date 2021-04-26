use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Session;
# ABSTRACT: Context of work for database interactions
$Neo4j::Driver::Session::VERSION = '0.23';

use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver);
use URI 1.25;

use Neo4j::Driver::Net::Bolt;
use Neo4j::Driver::Net::HTTP;
use Neo4j::Driver::Transaction;


sub new {
	my ($class, $driver) = @_;
	
	return Neo4j::Driver::Session::Bolt->new($driver) if $driver->{uri}->scheme eq 'bolt';
	return Neo4j::Driver::Session::HTTP->new($driver);
}


# Connect and get ServerInfo (via Bolt HELLO or HTTP Discovery API),
# then determine the default database name for Neo4j >= 4.
sub _connect {
	my ($self, $database) = @_;
	
	my $neo4j_version = $self->server->version;  # ensure contact with the server has been made
	return $self if $neo4j_version =~ m{^Neo4j/[123]\.};  # nothing more to do
	
	if (! defined $database) {
		# discover default database on Neo4j >= 4
		eval {
			my $sys = $self->{driver}->session(database => 'system');
			$database = $sys->run('SHOW DEFAULT DATABASE')->single->get('name');
		};
		croak $@ . "Session creation failed because the default database"
		         . " of $neo4j_version at " . $self->server->address
		         . " could not be determined" unless defined $database;
	}
	
	$self->{net}->_set_database($database);
	return $self;
}


sub begin_transaction {
	my ($self) = @_;
	
	return $self->new_tx->_begin;
}


sub run {
	my ($self, $query, @parameters) = @_;
	
	return $self->new_tx->_run_autocommit($query, @parameters);
}


sub close {
	warnings::warnif deprecated => __PACKAGE__ . "->close() is deprecated";
}


sub server {
	my ($self) = @_;
	
	return $self->{net}->_server;
}




package # private
        Neo4j::Driver::Session::Bolt;
use parent -norequire => 'Neo4j::Driver::Session';


sub new {
	my ($class, $driver) = @_;
	
	return bless {
		driver => $driver,
		net => Neo4j::Driver::Net::Bolt->new($driver),
	}, $class;
}


sub new_tx {
	return Neo4j::Driver::Transaction::Bolt->new(shift);
}




package # private
        Neo4j::Driver::Session::HTTP;
use parent -norequire => 'Neo4j::Driver::Session';


sub new {
	my ($class, $driver) = @_;
	
	return bless {
		driver => $driver,
		net => Neo4j::Driver::Net::HTTP->new($driver),
	}, $class;
}


sub new_tx {
	return Neo4j::Driver::Transaction::HTTP->new(shift);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Session - Context of work for database interactions

=head1 VERSION

version 0.23

=head1 SYNOPSIS

 use Neo4j::Driver;
 $session = Neo4j::Driver->new->basic_auth(...)->session;
 
 # explicit transaction
 $transaction = $session->begin_transaction;
 
 # autocommit transaction
 $result = $session->run('MATCH (m:Movie) RETURN m.name, m.year');

=head1 DESCRIPTION

Provides a context of work for database interactions.

A Session hosts a series of transactions carried out against a
database. Within the database, all statements are carried out within
a transaction. Within application code, however, it is not always
necessary to explicitly begin a transaction. If a statement is run
directly against a Session, the server will automatically C<BEGIN>
and C<COMMIT> that statement within its own transaction. This type
of transaction is known as an I<autocommit transaction>.

I<Explicit transactions> allow multiple statements to be committed
as part of a single atomic operation and can be rolled back if
necessary.

Only one open transaction per session at a time is supported. To
work with multiple concurrent transactions, simply use more than
one session.

=head1 METHODS

L<Neo4j::Driver::Session> implements the following methods.

=head2 begin_transaction

 $transaction = $session->begin_transaction;

Begin a new explicit L<Transaction|Neo4j::Driver::Transaction>.

=head2 run

 $result = $session->run('...');

Run and commit a statement using an autocommit transaction and return
the L<Result|Neo4j::Driver::Result>.

This method is semantically exactly equivalent to the following code,
but is faster because it doesn't require an extra server roundtrip to
commit the transaction.

 $transaction = $session->begin_transaction;
 $result = $transaction->run('...');
 $transaction->commit;

=head2 server

 $address = $summary->server->address;
 $version = $summary->server->version;

Obtain the L<ServerInfo|Neo4j::Driver::ServerInfo>, consisting of
the host, port and Neo4j version.

=head1 EXPERIMENTAL FEATURES

L<Neo4j::Driver::Session> implements the following experimental
features. These are subject to unannounced modification or removal
in future versions. Expect your code to break if you depend upon
these features.

=head2 Calling in list context

 @records = $session->run('...');
 @results = $session->run([...]);

The C<run> method tries to Do What You Mean if called in list
context.

=head2 Concurrent transactions

 $session = Neo4j::Driver->new('http://...')->basic_auth(...)->session;
 $tx1 = $session->begin_transaction;
 $tx2 = $session->begin_transaction;
 $tx3 = $session->run(...);

Since HTTP is a stateless protocol, the Neo4j HTTP API effectively
allows multiple concurrently open transactions without special
client-side considerations. This driver exposes this feature to the
client and will continue to do so, but the interface is not yet
finalised.

The Bolt protocol does not support concurrent transactions (also
known as "nested transactions") within the same session.

=head1 SECURITY CONSIDERATIONS

Both L<Session|Neo4j::Driver::Session> as well as
L<Transaction|Neo4j::Driver::Transaction> objects internally hold
references to the authentication credentials used to contact the
Neo4j server. Objects of these classes should therefore not be
passed to untrusted modules. However, objects of the
L<ServerInfo|Neo4j::Driver::ServerInfo> class and the
L<Result|Neo4j::Driver::Result> class do not
contain a reference to these credentials and are safe in this
regard.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Driver::B<Transaction>>,
L<Neo4j::Driver::B<ServerInfo>>,
L<Neo4j::Driver::B<Result>>

=item * Equivalent documentation for the official Neo4j drivers:
L<Session (Java)|https://neo4j.com/docs/api/java-driver/current/index.html?org/neo4j/driver/Session.html>,
L<Session (JavaScript)|https://neo4j.com/docs/api/javascript-driver/current/class/src/session.js~Session.html>,
L<ISession (.NET)|https://neo4j.com/docs/api/dotnet-driver/4.0/html/6bcf5d8c-98e7-b521-03e7-210cd6155850.htm>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
