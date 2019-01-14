use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver;
# ABSTRACT: Perl implementation of the Neo4j Driver API
$Neo4j::Driver::VERSION = '0.11';

use Carp qw(croak);
use Module::Load;

use URI 1.25;
use Neo4j::Driver::Transport::HTTP;
use Neo4j::Driver::Session;


my %NEO4J_DEFAULT_PORT = (
	bolt => 7687,
	http => 7474,
);


sub new {
	my ($class, $uri) = @_;
	
	if ($uri) {
		$uri =~ s|^|http://| if $uri !~ m{:|/};
		$uri = URI->new($uri);
		
		if ($uri->scheme eq 'bolt') {
			eval { load 'Neo4j::Bolt' };
			croak "Only the 'http' URI scheme is supported [$uri] (you may need to install the Neo4j::Bolt module)" if $@;
		}
		else {
			croak "Only the 'http' URI scheme is supported [$uri]" if $uri->scheme ne 'http';
		}
		
		croak "Hostname is required [$uri]" if ! $uri->host;
	}
	else {
		$uri = URI->new("http://localhost");
	}
	$uri->port( $NEO4J_DEFAULT_PORT{ $uri->scheme } ) if ! $uri->_port;
	
	my @defaults = (
		die_on_error => 1,
		http_timeout => 6,  # seconds
	);
	
	return bless { uri => $uri, @defaults }, $class;
}


sub basic_auth {
	my ($self, $username, $password) = @_;
	
	$self->{auth} = {
		scheme => 'basic',
		principal => $username,
		credentials => $password,
	};
	
	return $self;
}


sub session {
	my ($self) = @_;
	
	my $transport;
	if ($self->{uri}->scheme eq 'bolt') {
		load 'Neo4j::Driver::Transport::Bolt';
		$transport = Neo4j::Driver::Transport::Bolt->new($self);
	}
	else {
		$transport = Neo4j::Driver::Transport::HTTP->new($self);
	}
	
	return Neo4j::Driver::Session->new($transport);
}


sub close {
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver - Perl implementation of the Neo4j Driver API

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 use Neo4j::Driver;
 my $uri = 'http://localhost';
 my $driver = Neo4j::Driver->new($uri)->basic_auth('neo4j', 'password');
 
 sub say_friends_of {
   my $query = 'MATCH (a:Person)-[:KNOWS]->(f) '
             . 'WHERE a.name = {name} RETURN f.name';
   my $records = $driver->session->run($query, name => shift)->list;
   forach my $record ( @$records ) {
     say $record->get('f.name');
   }
 }
 
 say_friends_of 'Alice';

=head1 DESCRIPTION

This is an unofficial Perl implementation of the
L<Neo4j Driver API|https://neo4j.com/docs/developer-manual/current/drivers/#driver-use-the-driver>.
It enables interacting with a Neo4j database server using more or
less the same classes and method calls as the official Neo4j drivers
do. Responses from the Neo4j server are passed through to the client
as-is.

This driver extends the uniformity across languages, which is a
stated goal of the Neo4j Driver API, to Perl. The downside is that
this driver doesn't offer fully-fledged object bindings like the
existing L<REST::Neo4p> module does. Nor does it offer any L<DBI>
integration. However, it avoids the legacy C<cypher> endpoint,
assuring compatibility with future Neo4j versions.

B<This software has pre-release quality. There is no schedule for
further development. The interface is not yet stable.>

=head1 METHODS

L<Neo4j::Driver> implements the following methods.

=head2 basic_auth

 $driver->basic_auth('neo4j', 'password');

Set basic auth credentials with a given user and password. This
method returns the modified L<Neo4j::Driver> object, so that method
chaining is possible.

 my $session = $driver->basic_auth('neo4j', 'password')->session;

=head2 new

 my $driver = Neo4j::Driver->new('http://localhost');

Construct a new L<Neo4j::Driver> object. This object holds the
details required to establish connections with a Neo4j database,
including server URIs, credentials and other configuration.

The URI passed to this method determines the type of driver created. 
Only the C<http> URI scheme is currently supported.

If a part of the URI or even the entire URI is missing, suitable
default values will be substituted. In particular, the host name
C<localhost> will be used as default, along with the default port
of the selected protocol. The default protocol might change to
C<https> in future.

 # all of these are semantically equal
 my $driver = Neo4j::Driver->new;
 my $driver = Neo4j::Driver->new('localhost');
 my $driver = Neo4j::Driver->new('http://localhost');
 my $driver = Neo4j::Driver->new('http://localhost:7474');

=head2 session

 my $session = $driver->session;

Creates and returns a new L<Session|Neo4j::Driver::Session>.

=head1 EXPERIMENTAL FEATURES

L<Neo4j::Driver> implements the following experimental features.
These are subject to unannounced modification or removal in future
versions. Expect your code to break if you depend upon these
features.

=head2 Bolt support

 my $driver = Neo4j::Driver->new('bolt://localhost');

Thanks to L<Neo4j::Bolt>, there is now skeletal support for the
L<Bolt Protocol|https://boltprotocol.org/>, which can be used as
an alternative to HTTP to connect to the Neo4j server.

The design goal is for this driver to eventually offer equal support
for Bolt and HTTP. At this time, using Bolt with this driver is not
recommended, although it sorta-kinda works. The biggest issues
include: Explicit transactions are not yet implemented, there is
no proper error handling, and summary information is completely
unavailable. Additionally, there are certain problems with Unicode,
incompatibilities with other "experimental" features of this driver,
and parts of the documentation still assume that HTTP is the only
option.

=head2 Close method

 $driver->close;  # no-op

This driver does not support persistent connections at present. All
connections are closed automatically. There is no need for explicit
calls to `close` at this time.

=head2 HTTP Timeout

 $driver->{http_timeout} = 10;  # seconds

A timeout in seconds for making HTTP connections to the Neo4j server.
If a connection cannot be established before timeout, a local error
will be triggered by this client.

The default timeout currently is 6 seconds.

=head2 Mutability

 my $session1 = $driver->basic_auth('user1', 'password')->session;
 my $session2 = $driver->basic_auth('user2', 'password')->session;
 
 my $session1 = $driver->session;
 $driver->{http_timeout} = 30;
 $driver->{die_on_error} = 0;
 my $session2 = $driver->session;

The official Neo4j drivers are explicitly designed to be immutable.
As this driver currently has a much simpler design, it can afford
mutability, but applications shouldn't depend upon it.

The modifications will not be picked up by existing sessions. Only
sessions that are newly created after making the changes will be
affected.

=head2 Suppress exceptions

 my $driver = Neo4j::Driver->new;
 $driver->{die_on_error} = 0;
 my $result = $driver->session->run('...');

The default value of the C<die_on_error> attribute is C<1>. Setting
this to C<0> causes the driver to no longer die on I<server> errors.

This is much less useful than it sounds. Not only is the
L<StatementResult|Neo4j::Driver::StatementResult> structure not
well-defined for such situations, but also the internal state of the
L<Transaction|Neo4j::Driver::Transaction> object may be corrupted.
For example, when a minor server error occurs on the first request
(which would normally establish the connection), the expected
C<Location> header may be missing from the error message and the
transaction may therefore be marked as closed, even though it still
is open.

Additionally, I<client> errors (such as trying to call C<single()> on
a result with multiple result records) currently still will cause the
driver to die.

This feature will likely be removed in a future version. Use C<eval>,
L<Try::Tiny> or similar instead.

=head1 ENVIRONMENT

This software currently targets Neo4j versions 2.3, 3.x and 4.x. The
latter doesn't exist yet, but is expected to continue support for the
Transactional HTTP endpoint that this driver uses (as opposed to the
Legacy Cypher HTTP endpoint, which is expected to be discontinued
starting in Neo4j 4.0 along with direct REST access to the graph
entities).

This software requires at least Perl 5.10, though you should consider
using Perl 5.16 or newer if you can.

=head1 DIAGNOSTICS

Neo4j::Driver currently dies as soon as an error condition is
discovered. Use C<eval>, L<Try::Tiny> or similar to catch this.

=head1 BUGS

See the L<TODO.pod> document and Github for known issues and planned
improvements. Please report new issues and other feedback on Github.

Just like the official Neo4j drivers, this driver has been designed to strike
a balance between an idiomatic API for Perl and a uniform surface across all
languages. Differences between this driver and the official Neo4j drivers in
either the API or the behaviour are generally to be regarded as bugs unless
there is a compelling reason for a different approach in Perl.

Due to lack of resources, only the Neo4j community edition is targeted by this
driver at present.

=head1 SEE ALSO

L<Neo4j::Driver::Session>,
L<Neo4j Developer Manual: Drivers|https://neo4j.com/docs/developer-manual/current/drivers/#driver-use-the-driver>,
L<Neo4j Transactional Cypher HTTP API|https://neo4j.com/docs/developer-manual/current/http-api/>,
L<REST::Neo4p>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2019 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
