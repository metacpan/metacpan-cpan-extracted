use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver;
# ABSTRACT: Neo4j community graph database driver for Bolt and HTTP
$Neo4j::Driver::VERSION = '0.45';

use Carp qw(croak);

use URI 1.25;
use Neo4j::Driver::Events;
use Neo4j::Driver::Session;

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

my %OPTIONS = (
	auth => 'auth',
	ca_file => 'tls_ca',
	cypher_filter => 'cypher_filter',
	cypher_params => 'cypher_params_v2',
	cypher_types => 'cypher_types',
	encrypted => 'tls',
	jolt => 'jolt',
	concurrent_tx => 'concurrent_tx',
	max_transaction_retry_time => 'max_transaction_retry_time',
	net_module => 'net_module',
	timeout => 'timeout',
	tls => 'tls',
	tls_ca => 'tls_ca',
	trust_ca => 'tls_ca',
	uri => 'uri',
);

my %DEFAULTS = (
	cypher_types => {
		node => 'Neo4j::Driver::Type::Node',
		relationship => 'Neo4j::Driver::Type::Relationship',
		path => 'Neo4j::Driver::Type::Path',
		point => 'Neo4j::Driver::Type::Point',
		temporal => 'Neo4j::Driver::Type::Temporal',
	},
);


sub new {
	my ($class, $config, @extra) = @_;
	
	my $self = bless { config => { %DEFAULTS }, die_on_error => 1 }, $class;
	$self->{plugins} = Neo4j::Driver::Events->new;
	
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
		
		if ( ! $uri->scheme ) {
			croak sprintf "Failed to parse URI '%s'", $uri;
		}
		if ( $uri->scheme !~ m/^https?$|^bolt$|^neo4j$/ ) {
			croak sprintf "URI scheme '%s' unsupported; use 'bolt', 'http', or 'neo4j'", $uri->scheme // "";
		}
		
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
	
	my $uri = $self->{config}->{uri};
	$uri->scheme( exists $INC{'Neo4j/Bolt.pm'} ? 'bolt' : $self->{config}->{tls} ? 'https' : 'http' );
	$uri->port( $NEO4J_DEFAULT_PORT{ $uri->scheme } ) if ! $uri->_port;
}


sub basic_auth {
	my ($self, $username, $password) = @_;
	
	warnings::warnif deprecated => "Deprecated sequence: call basic_auth() before session()" if $self->{server_info};
	
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
		croak "Unsupported config option: $key" unless grep m/^$key$/, keys %OPTIONS;
		return $self->{$OPTIONS{$key}} // $self->{config}->{$OPTIONS{$key}};
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
	
	if (! $self->{server_info}) {
		warnings::warnif deprecated => sprintf "Internal API %s->{%s} may be unavailable in Neo4j::Driver 1.00", __PACKAGE__, $_ for grep { $self->{$_} } @OPTIONS{ sort keys %OPTIONS };
	}
	
	$self->{plugins}->{die_on_error} = $self->{die_on_error};
	warnings::warnif deprecated => __PACKAGE__ . "->{die_on_error} is deprecated" unless $self->{die_on_error};
	warnings::warnif deprecated => __PACKAGE__ . "->{http_timeout} is deprecated; use config()" if defined $self->{http_timeout};
	$self->{config}->{timeout} //= $self->{http_timeout};
	
	@options = %{$options[0]} if @options == 1 && ref $options[0] eq 'HASH';
	my %options = $self->_parse_options('session', ['database'], @options);
	
	$self->_fix_neo4j_uri if $self->{config}->{uri}->scheme eq 'neo4j';
	
	my $session = Neo4j::Driver::Session->new($self);
	return $session->_connect($options{database});
}


sub _parse_options {
	my (undef, $context, $supported, @options) = @_;
	
	croak "Odd number of elements in $context options hash" if @options & 1;
	my %options = @options;
	
	warnings::warnif deprecated => "Config option ca_file is deprecated; use trust_ca" if $options{ca_file};
	warnings::warnif deprecated => "Config option cypher_types is deprecated" if $options{cypher_types};
	if ($options{cypher_params}) {
		croak "Unimplemented cypher params filter '$options{cypher_params}'" if $options{cypher_params} ne v2;
	}
	elsif ($options{cypher_filter}) {
		warnings::warnif deprecated => "Config option cypher_filter is deprecated; use cypher_params";
		croak "Unimplemented cypher filter '$options{cypher_filter}'" if $options{cypher_filter} ne 'params';
		$options{cypher_params} = v2;
	}
	warnings::warnif deprecated => "Config option jolt is deprecated: Jolt is now enabled by default" if defined $options{jolt};
	warnings::warnif deprecated => "Config option net_module is deprecated; use plug-in interface" if defined $options{net_module};
	
	my @unsupported = ();
	foreach my $key (keys %options) {
		push @unsupported, $key unless grep m/^$key$/, @$supported;
	}
	croak "Unsupported $context option: " . join ", ", sort @unsupported if @unsupported;
	
	return %options;
}


sub plugin {
	# uncoverable pod (experimental feature)
	my ($self, $package, @extra) = @_;
	
	croak "plugin() with more than one argument is unsupported" if @extra;
	$self->{plugins}->_register_plugin($package);
	return $self;
}


sub close {
	# uncoverable pod (see Deprecations.pod)
	warnings::warnif deprecated => __PACKAGE__ . "->close() is deprecated";
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

version 0.45

=head1 SYNOPSIS

 use Neo4j::Driver;
 $uri = 'bolt://localhost';  # requires Neo4j::Bolt
 $uri = 'http://localhost';
 $driver = Neo4j::Driver->new($uri)->basic_auth('neo4j', 'password');
 
 sub say_friends_of ($person) {
   $query = 'MATCH (a:Person)-[:KNOWS]->(f) '
             . 'WHERE a.name = $name RETURN f.name';
   @records = $driver->session->execute_read( sub ($tx) {
     $tx->run($query, { name => $person })->list;
   });
   foreach $record ( @records ) {
     say $record->get('f.name');
   }
 }
 
 say_friends_of 'Alice';

=head1 DESCRIPTION

This software is a community driver for the
L<Neo4j|https://neo4j.com/> graph database server.
It is designed to follow the Neo4j Driver API, allowing
clients to interact with a Neo4j server using the same
classes and method calls as the official Neo4j drivers do.
This extends the uniformity across languages, which is a
stated goal of the Neo4j Driver API, to Perl.

This driver targets the Neo4j community edition,
version 2.x, 3.x, 4.x, and 5.x. The Neo4j enterprise edition
and AuraDB are only supported as far as practical,
but patches will be accepted.

Two different network protocols exist for connecting to Neo4j.
By default, Neo4j servers offer both, but this can be changed
in F<neo4j.conf> for each server; see
L<"Configure connectors" in the Neo4j Operations Manual|https://neo4j.com/docs/operations-manual/current/configuration/connectors/>.

=over

=item Bolt

Bolt is a Neo4j proprietary, binary protocol, available with
S<Neo4j 3.0> and newer. Bolt communication may be encrypted or
unencrypted. Because Bolt is faster than HTTP, it is generally
the recommended protocol. However, Perl support for it may be
lagging after major updates to Neo4j.

This driver supports Bolt, but doesn't bundle the necessary XS
packages. You will need to install L<Neo4j::Bolt> separately
to enable Bolt for this driver.

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
install L<LWP::Protocol::https> separately to enable HTTPS.

=back

The protocol is automatically chosen based on the URI scheme.
See L<Neo4j::Driver::Config/"uri"> for details.

This driver will soon
move to S<version 1.00,> removing L<deprecated
functionality|Neo4j::Driver::Deprecations>.

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

 $driver = Neo4j::Driver->new('http://localhost');

If C<new()> is called with no arguments, a default configuration
will be used for the driver.

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

=head1 EXPERIMENTAL FEATURES

L<Neo4j::Driver> implements the following experimental features.
These are subject to unannounced modification or removal in future
versions. Expect your code to break if you depend upon these
features.

=head2 Plug-in modules

 $driver->plugin(  Local::MyPlugin->new );

The driver offers a simple plug-in interface. Plug-ins are modules
providing handlers for events that may be triggered by the driver.
Plug-ins are loaded by calling the C<plugin()> method with the
the blessed instance of a plug-in as parameter.

Details on the implementation of plug-ins including descriptions of
individual events are provided in L<Neo4j::Driver::Plugin>.

This feature is experimental because some parts of the plug-in
API are still evolving.

=head1 ENVIRONMENT

This software requires at least Perl 5.10, though you should consider
using Perl 5.26 or newer if you can.

=head1 DIAGNOSTICS

Neo4j::Driver triggers an "error" event as soon as an error
condition is discovered. If unhandled, this event will cause
the driver to die with an error string.
See L<Neo4j::Driver::Transaction/"ERROR HANDLING"> for
further information.

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

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver::B<Session>>

=item * L<Neo4j::Driver::Types>

=item * Official API documentation:
L<Neo4j Driver API Specification|https://github.com/neo4j/docs-bolt/blob/main/modules/ROOT/pages/driver-api/index.adoc>,
L<Neo4j Drivers Manual|https://neo4j.com/docs/java-manual/5/>,
L<Neo4j HTTP API Docs|https://neo4j.com/docs/http-api/5/>

=item * Other modules for working with Neo4j:
L<DBD::Neo4p>,
L<Neo4j::Bolt>,
L<Neo4j::Cypher::Abstract>,
L<REST::Cypher>,
L<REST::Neo4p>

=back

=head1 ACKNOWLEDGEMENT

Special thanks go to Mark A. Jensen (MAJENSEN). Without the
inspiration of his L<REST::Neo4p>, this driver project I<probably>
would never have been even gotten started. And without Mark's
tremendous work on L<Neo4j::Bolt> and libneo4j-client, this
driver I<certainly> would be in much worse shape than it is today.

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
