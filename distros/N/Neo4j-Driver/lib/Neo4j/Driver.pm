use v5.12;
use warnings;

package Neo4j::Driver 1.02;
# ABSTRACT: Neo4j community graph database driver for Bolt and HTTP


use Carp qw(croak);
use List::Util 1.33 qw(none);

use URI 1.25;
use Neo4j::Driver::Events;
use Neo4j::Driver::Session;


my %NEO4J_DEFAULT_PORT = (
	bolt => 7687,
	http => 7474,
	https => 7473,
);

my %OPTIONS = (
	auth => 'auth',
	cypher_params => 'cypher_params_v2',
	concurrent_tx => 'concurrent_tx',
	encrypted => 'encrypted',
	max_transaction_retry_time => 'max_transaction_retry_time',
	timeout => 'timeout',
	tls => 'encrypted',
	tls_ca => 'trust_ca',
	trust_ca => 'trust_ca',
	uri => 'uri',
);


sub new {
	my ($class, $config, @extra) = @_;
	
	my $self = bless {}, $class;
	$self->{events} = Neo4j::Driver::Events->new;
	
	croak __PACKAGE__ . "->new() with multiple arguments unsupported" if @extra;
	$config = { uri => $config } if ref $config ne 'HASH';
	$config->{uri} //= '';  # force config() to call _check_uri()
	return $self->config($config);
}


sub _check_uri {
	my ($self) = @_;
	
	my $uri = $self->{config}->{uri};
	
	if ($uri) {
		$uri = "[$uri]" if $uri =~ m{^[0-9a-f:]*::|^(?:[0-9a-f]+:){6}}i;
		$uri =~ s|^|neo4j://| if $uri !~ m{:|/} || $uri =~ m{^\[.+\]$};
		$uri =~ s|^|neo4j:| if $uri =~ m{^//};
		$uri = URI->new($uri);
		
		$uri->scheme or croak
			sprintf "Failed to parse URI '%s'", $uri;
		$uri->scheme =~ m/^(?:https?|bolt|neo4j)$/i or croak
			sprintf "URI scheme '%s' unsupported; use 'bolt', 'http', or 'neo4j'", $uri->scheme;
		
		if (my $userinfo = $uri->userinfo(undef)) {
			my @userinfo = $userinfo =~ m/^([^:]*):?(.*)/;
			@userinfo = map { URI::Escape::uri_unescape $_ } @userinfo;
			utf8::decode $_ for @userinfo;
			$self->basic_auth(@userinfo);
		}
		$uri->host('127.0.0.1') unless $uri->host;
		$uri->path('') if $uri->path_query eq '/';
		$uri->fragment(undef);
	}
	else {
		$uri = URI->new("neo4j://127.0.0.1");
	}
	$uri->port( $NEO4J_DEFAULT_PORT{ $uri->scheme } ) if ! $uri->_port;
	
	$self->{config}->{uri} = $uri;
}


sub _fix_neo4j_uri {
	my ($self) = @_;
	
	croak "The concurrent_tx config option may only be used with http:/https: URIs" if $self->{config}->{concurrent_tx};
	
	my $uri = $self->{config}->{uri};
	$uri->scheme( exists $INC{'Neo4j/Bolt.pm'} ? 'bolt' : $self->{config}->{encrypted} ? 'https' : 'http' );
	$uri->port( $NEO4J_DEFAULT_PORT{ $uri->scheme } ) if ! $uri->_port;
}


sub basic_auth {
	my ($self, $username, $password) = @_;
	
	croak "Unsupported sequence: call basic_auth() before session()" if $self->{server_info};
	
	$self->{config}->{auth} = {
		scheme => 'basic',
		principal => $username,
		credentials => $password,
	};
	
	return $self;
}


sub config {
	my ($self, @options) = @_;
	
	@options = %{$options[0]} if @options == 1 && ref $options[0] eq 'HASH';
	croak "config() without options unsupported" unless @options;
	
	if (@options < 2) {
		# get config option
		my $key = $options[0];
		croak sprintf "Unsupported config option: %s", $key if none {$_ eq $key} keys %OPTIONS;
		return $self->{config}->{$OPTIONS{$key}};
	}
	
	croak "Unsupported sequence: call config() before session()" if $self->{server_info};
	my %options = $self->_parse_options('config', [keys %OPTIONS], @options);
	
	# set config option
	my @keys = reverse sort keys %options;  # auth should take precedence over uri
	foreach my $key (@keys) {
		$self->{config}->{$OPTIONS{$key}} = $options{$key};
		$self->_check_uri if $OPTIONS{$key} eq 'uri';
	}
	return $self;
}


sub session {
	my ($self, @options) = @_;
	
	@options = %{$options[0]} if @options == 1 && ref $options[0] eq 'HASH';
	my %options = $self->_parse_options('session', ['database'], @options);
	
	$self->_fix_neo4j_uri if $self->{config}->{uri}->scheme eq 'neo4j';
	
	my $session = Neo4j::Driver::Session->new($self);
	return $session->_connect($options{database});
}


sub _parse_options {
	my (undef, $context, $supported, @options) = @_;
	
	croak sprintf "Odd number of elements in %s options hash", $context if @options & 1;
	my %options = @options;
	
	warnings::warnif deprecated => "Config option tls is deprecated; use encrypted" if $options{tls};
	warnings::warnif deprecated => "Config option tls_ca is deprecated; use trust_ca" if $options{tls_ca};
	
	if ($options{cypher_params}) {
		$options{cypher_params} =~ m<^(?:\x02|v2)$> or croak
			sprintf "Unimplemented cypher params filter '%s'", $options{cypher_params};
	}
	
	my @unsupported = grep { my $key = $_; none {$_ eq $key} @$supported } keys %options;
	@unsupported and croak
		sprintf "Unsupported %s option: %s", $context, join ", ", sort @unsupported;
	
	return %options;
}


sub plugin {
	my ($self, $plugin, @extra) = @_;
	
	croak "plugin() with more than one argument is unsupported" if @extra;
	croak "Unsupported sequence: call plugin() before session()" if $self->{server_info};
	$self->{events}->_register_plugin($plugin);
	return $self;
}




package # private
        URI::bolt;

use parent 'URI::_server';

# The server methods need to be available for bolt: URI instances
# even when the Neo4j-Bolt distribution is not installed.


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver - Neo4j community graph database driver for Bolt and HTTP

=head1 VERSION

version 1.02

=head1 SYNOPSIS

 $uri = 'bolt://localhost';  # requires Neo4j::Bolt
 $uri = 'http://localhost';
 
 $driver = Neo4j::Driver->new({ uri => $uri, ... });
 $driver->basic_auth( $user, $password );
 $session = $driver->session;
 
 $query = <<~END;
   MATCH (someone :Person)-[:KNOWS]->(friend)
   WHERE someone.name = \$name
   RETURN friend.name
   END
 @records = $session->execute_read( sub ($tx) {
   $tx->run($query, { name => 'Alice' })->list;
 });
 foreach my $record ( @records ) {
   say $record->get('friend.name');
 }

=head1 DESCRIPTION

This software is a community driver for the
L<Neo4j|https://neo4j.com/> graph database server.
It is designed to follow the Neo4j Driver API, allowing
clients to interact with a Neo4j server using the same
classes and method calls as the official Neo4j drivers do.
This extends the uniformity across languages, which is a
stated goal of the Neo4j Driver API, to Perl.

This driver targets the Neo4j community edition,
version 2.x, 3.x, 4.x, and 5.x. Other Neo4j editions are
only supported as far as practical, but patches targeting
them are welcome.

Two different network protocols exist for connecting to Neo4j.
By default, Neo4j servers offer both, but this can be changed
in F<neo4j.conf> for each server; see
L<"Configure connectors" in the Neo4j Operations Manual|https://neo4j.com/docs/operations-manual/current/configuration/connectors/>.

=over

=item Bolt

Bolt is a Neo4j proprietary, binary protocol, available with
S<Neo4j 3.5> and newer. Bolt communication may be encrypted or
unencrypted. Because Bolt is faster than HTTP, it is generally
the recommended protocol. However, Perl support for it tends
to lag behind after major updates to Neo4j.

This driver supports Bolt, but doesn't bundle the necessary XS
packages. You will need to install S<L<Neo4j::Bolt> 0.4201> or
later separately to enable Bolt for this driver.

=item HTTP / HTTPS

Support for HTTP is built into this driver, so it is always
available. HTTP is still fast enough for many use cases and
works even in a "Pure Perl" environment. It may also be
quicker than Bolt to add support for future changes in Neo4j.

HTTP connections will use B<Jolt> (JSON Bolt) when offered by the server.
For older Neo4j servers (before S<version 4.2>), the driver
will automatically fall back to slower REST-style JSON.

The driver also supports encrypted communication using HTTPS,
but doesn't bundle the necessary packages. You will need to
install L<IO::Socket::SSL> separately to enable HTTPS.

=back

The protocol is automatically chosen based on the URI scheme.
See L<Neo4j::Driver::Config/"uri"> for details.

Version 1 of Neo4j::Driver is targeting Perl v5.20 and later.
Patches will be accepted to address issues with Perl versions
as old as v5.16.3 for as long as practical.

=head1 METHODS

L<Neo4j::Driver> implements the following methods.

=head2 basic_auth

 $driver->basic_auth('neo4j', 'password');

Set basic auth credentials with a given user and password. This
method returns the modified L<Neo4j::Driver> object, so that method
chaining is possible.

 $session = $driver->basic_auth('neo4j', 'password')->session;

=head2 config

 $driver->config({ option1 => 'foo', option2 => 'bar' });

Sets the specified configuration options on a L<Neo4j::Driver>
object. The options may be given as a hash or as a hash reference.
This method returns the modified object, so that method chaining
is possible.

 $session = $driver->config(timeout => 60)->session;

See L<Neo4j::Driver::Config> for a list of supported options.
Setting configuration options on a driver is only allowed before
creating the driver's first session.

Calling this method with just a single string parameter will return
the current value of the config option named by the parameter.

 $timeout = $driver->config('timeout');

=head2 new

 $driver = Neo4j::Driver->new({ uri => 'http://localhost' });

Construct a new L<Neo4j::Driver> object. This object holds the
details required to establish connections with a Neo4j database,
including server URIs, credentials and other configuration.

The C<new()> method accepts one or more configuration options given
as a hash reference. See L<Neo4j::Driver::Config> for a
list of supported options. Alternatively, instead of the hash
reference, the Neo4j server URI may be given as a scalar string.

 $driver = Neo4j::Driver->new('bolt://localhost');

If C<new()> is called with no arguments, a default configuration
will be used for the driver.

=head2 plugin

 $driver->plugin( $plugin );

Load the given plug-in object into the driver. This method returns
the modified driver, so that method chaining is possible.

Details on the implementation of plug-ins including descriptions of
individual event handlers are provided in L<Neo4j::Driver::Plugin>.
Note that the plug-in API is experimental because some of its parts
are still evolving.

=head2 session

 $session = $driver->session;

Creates and returns a new L<Session|Neo4j::Driver::Session>,
initiating a network connection with the Neo4j server.

Each session connects to a single database, which may be specified
using the C<database> option in a hash or hash reference passed
to this method. If no defined value is given for this
option, the driver will select the default database configured
in F<neo4j.conf>.

 $session = $driver->session( database => 'system' );

The C<database> option is silently ignored when used with Neo4j
S<versions 2> S<and 3>, which only support a single database.

=head1 SEE ALSO

Interacting with a Neo4j database:

=over

=item * L<Neo4j::Driver::B<Session>>

=item * L<Neo4j::Driver::Types>

=back

Other Perl modules for working with Neo4j:

=over

=item * L<DBD::Neo4p> E<ndash> a L<DBI>-compliant wrapper for REST::Neo4p

=item * L<Neo4j::Bolt> E<ndash> XS bindings for libneo4j-omni, a S<C library> for Bolt

=item * L<Neo4j::Cypher::Abstract> E<ndash> generate Cypher query statements

=item * L<Neo4j::Types::Generic> E<ndash> create values for Bolt query parameters

=item * L<REST::Cypher> E<ndash> access the REST interface in old Neo4j versions

=item * L<REST::Neo4p> E<ndash> object mappings for Neo4j nodes and relationships

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 CONTRIBUTORS

=for stopwords Mark A. Jensen Mohammad S Anwar

=over 4

=item *

Mark A. Jensen <majensen@cpan.org>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
