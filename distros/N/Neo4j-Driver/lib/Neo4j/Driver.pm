use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver;
# ABSTRACT: Perl implementation of the Neo4j Driver API
$Neo4j::Driver::VERSION = '0.13';

use Carp qw(croak);
use Module::Load;

use URI 1.25;
use Neo4j::Driver::Transport::HTTP;
use Neo4j::Driver::Session;

# The following packages are never used directly anywhere. We mention them
# here so that a simple `use Neo4j::Driver;` will make them available.
use Neo4j::Driver::Type::Node;
use Neo4j::Driver::Type::Relationship;
use Neo4j::Driver::Type::Path;
use Neo4j::Driver::Type::Point;
use Neo4j::Driver::Type::Temporal;


my %NEO4J_DEFAULT_PORT = (
	bolt => 7687,
	http => 7474,
	https => 7473,
);

my %DEFAULTS = (
	die_on_error => 1,
	http_timeout => 6,  # seconds
	ca_file => undef,
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
			croak "Only the 'http' URI scheme is supported [$uri]" if $uri->scheme !~ m/^https?$/;
		}
		
		croak "Hostname is required [$uri]" if ! $uri->host;
	}
	else {
		$uri = URI->new("http://localhost");
	}
	$uri->port( $NEO4J_DEFAULT_PORT{ $uri->scheme } ) if ! $uri->_port;
	
	return bless { uri => $uri, %DEFAULTS }, $class;
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


sub config {
	my ($self, $key, $value) = @_;
	
	croak "Config option '$key' unsupported" unless grep m/^$key$/, keys %DEFAULTS;
	$self->{$key} = $value;
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

version 0.13

=head1 SYNOPSIS

 use Neo4j::Driver;
 my $uri = 'http://localhost';
 my $driver = Neo4j::Driver->new($uri)->basic_auth('neo4j', 'password');
 
 sub say_friends_of {
   my $query = 'MATCH (a:Person)-[:KNOWS]->(f) '
             . 'WHERE a.name = {name} RETURN f.name';
   my $records = $driver->session->run($query, name => shift)->list;
   foreach my $record ( @$records ) {
     say $record->get('f.name');
   }
 }
 
 say_friends_of 'Alice';

=head1 DESCRIPTION

This is an unofficial Perl implementation of the
L<Neo4j Driver API|https://neo4j.com/docs/driver-manual/current/>.
It enables interacting with a Neo4j database server using the
same classes and method calls as the official Neo4j drivers do.

This driver extends the uniformity across languages, which is a
stated goal of the Neo4j Driver API, to Perl. The downside is that
this driver doesn't offer fully-fledged object bindings like the
existing L<REST::Neo4p> module does. Nor does it offer any L<DBI>
integration. However, it avoids the legacy C<cypher> endpoint,
assuring compatibility with future Neo4j versions.

B<As of version 0.13, the interface of this software may be
considered stable.>

However, bugs may still exist. Also, experimental features may be
changed or deprecated at any time. If you find yourself reliant on
an experimental feature, please file a new issue requesting that it
be made stable.

There is an ongoing effort to clean up the experimental features.
For each of them, the goal is to eventually either declare it stable
or deprecate it. There is also ongoing work to further improve
general stability and reliability of this software. However, there
is no schedule for the completion of these efforts.

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
of the selected protocol.

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
include: Unicode is not supported in L<Neo4j::Bolt>,
C<libneo4j-client> error reporting is unreliable, summary
information reported by L<Neo4j::Bolt> is incomplete, and graph meta
data supplied by L<Neo4j::Bolt> is unreliable and has a different
format than when the HTTP transport is used.

Additionally, there are
incompatibilities with other "experimental" features of this driver,
and parts of the documentation still assume that HTTP is the only
option.

TLS encryption is disabled in early versions of L<Neo4j::Bolt>.
If you need remote access, consider using HTTPS instead of Bolt.

=head2 HTTPS support

 my $driver = Neo4j::Driver->new('https://localhost');
 $driver->config(ca_file => 'neo4j/certificates/neo4j.cert');

Using HTTPS will result in an encrypted connection. In order to rule
out a man-in-the-middle attack, the server's certificate must be
verified. By default, this driver may be expected to use operating
system default root certificates (not really tested yet). This
will fail unless your Neo4j installation uses a key pair that is
trusted and verifiable through the global CA infrastructure. For
self-signed certificates (such as those automatically provided by
some Neo4j versions), you need to specify the location of a local
copy of the server certificate. The driver config option C<ca_file>
may be used for this; it corresponds to C<SSL_ca_file> in
L<LWP::UserAgent> and L<IO::Socket::SSL>.

See also the
L<Neo4j Operations Manual|https://neo4j.com/docs/operations-manual/current/security/>
for details on Neo4j network security.

=head2 Close method

 $driver->close;  # no-op

All resources opened by this driver are closed automatically once
they are no longer required. Explicit calls to C<close()> are neither
required nor useful.

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

This software currently targets Neo4j versions 2.3, 3.x and 4.x.

This software requires at least Perl 5.10, though you should consider
using Perl 5.16 or newer if you can.

=head1 PERFORMANCE

Preliminary testing seems to indicate the two major bottlenecks are
the HTTP transport to and from the Neo4j server, and the JSON
parsing. Switching to the experimental Bolt protocol support may well
increase the speed tenfold. You are encouraged to run your own tests
for your specific application.

=head1 DIAGNOSTICS

Neo4j::Driver currently dies as soon as an error condition is
discovered. Use C<eval>, L<Try::Tiny> or similar to catch this.

Warnings are given when deprecated or ambiguous method calls are used.
These warnings may be disabled if desired.

 no warnings 'deprecated';
 no warnings 'ambiguous';

=head1 BUGS

See the F<TODO> document and Github for known issues and planned
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
L<Neo4j Drivers Manual|https://neo4j.com/docs/driver-manual/current/>,
L<Neo4j HTTP API Docs|https://neo4j.com/docs/http-api/current/>,
L<REST::Neo4p>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2019 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
