use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver;
# ABSTRACT: Perl implementation of the Neo4j Driver API
$Neo4j::Driver::VERSION = '0.09';

use Carp qw(croak);

use URI 1.25;
use REST::Client 134;
use Neo4j::Driver::Session;


our $CONTENT_TYPE = 'application/json; charset=UTF-8';


sub new {
	my ($class, $uri) = @_;
	
	if ($uri) {
		$uri =~ s|^|http://| if $uri !~ m{:|/};
		$uri = URI->new($uri);
		croak "Only the 'http' URI scheme is supported [$uri]" if $uri->scheme ne 'http';
		croak "Hostname is required [$uri]" if ! $uri->host;
		$uri->port(7474) if ! $uri->port;
	}
	else {
		$uri = URI->new("http://localhost:7474");
	}
	
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
	$self->{client} = undef;  # ensure the next call to _client picks up the new credentials
	
	return $self;
}


# at the moment, every session uses the same REST::Client instance
# this is a bug: two different sessions should use two different TCP connections
sub _client {
	my ($self) = @_;
	
	# lazy initialisation
	if ( ! $self->{client} ) {
		my $uri = $self->{uri};
		if ($self->{auth}) {
			croak "Only HTTP Basic Authentication is supported" if $self->{auth}->{scheme} ne 'basic';
			$uri = $uri->clone;
			$uri->userinfo( $self->{auth}->{principal} . ':' . $self->{auth}->{credentials} );
		}
		
		$self->{client} = REST::Client->new({
			host => "$uri",
			timeout => $self->{http_timeout},
			follow => 1,
		});
		$self->{client}->addHeader('Accept', $CONTENT_TYPE);
		$self->{client}->addHeader('Content-Type', $CONTENT_TYPE);
		$self->{client}->addHeader('X-Stream', 'true');
	}
	
	return $self->{client};
}


sub session {
	my ($self) = @_;
	
	return Neo4j::Driver::Session->new($self);
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

version 0.09

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
of the specified protocol. The default protocol might change to
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

=head2 Close method

C<close> is currently a no-op in this class.

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

Module use may give the following errors.

=over

# =item Weak references are not implemented in the version of perl
# 
# The version of perl that you are using does not implement weak references, to
# use L</isweak> or L</weaken> you will need to use a newer release of perl.
# 
# =item Vstrings are not implemented in the version of perl
# 
# The version of perl that you are using does not implement Vstrings, to use
# L</isvstring> you will need to use a newer release of perl.

=back

=head1 BUGS

This software has pre-release quality. There is no schedule for
further development. The interface is not yet stable.

See the F<TODO> document and Github for known issues and planned
improvements. Please report new issues and other feedback on Github.

Just like the official Neo4j drivers, this driver has been designed to strike
a balance between an idiomatic API for Perl and a uniform surface across all
languages. Differences between this driver and the official Neo4j drivers in
either the API or the behaviour are generally to be regarded as bugs unless
there is a compelling reason for a different approach in Perl.

This driver does not support the Bolt protocol of Neo4j version 3 and
there are currently no plans of supporting Bolt in the future. The
Transactional HTTP API is used for communicating with the server
instead. This also means that Casual Clusters are not supported.

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

This software is Copyright (c) 2016-2018 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
