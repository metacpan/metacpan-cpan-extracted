use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::ServerInfo;
# ABSTRACT: Provides Neo4j server address and version
$Neo4j::Driver::ServerInfo::VERSION = '0.48';

use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver::Session);
use URI 1.25;


sub new {
	# uncoverable pod (private method)
	my ($class, $server_info) = @_;
	
	# don't store the full URI here - it may contain auth credentials
	$server_info->{uri} = URI->new( $server_info->{uri} )->host_port;
	
	return bless $server_info, $class;
}


sub address  { shift->{uri} }
sub agent    { shift->{version} }
sub version  { shift->{version} }


sub protocol_version {
	shift->{protocol}
}


sub protocol {
	# uncoverable pod (see Deprecations.pod)
	my ($self) = @_;
	warnings::warnif deprecated => __PACKAGE__ . "->protocol() is deprecated; use protocol_version() instead";
	my $bolt_version = $self->{protocol};
	return "Bolt/$bolt_version" if $bolt_version;
	return defined $bolt_version ? "Bolt" : "HTTP";
}


# discover default database on Neo4j >= 4 using the given driver config
sub _default_database {
	my ($self, $driver) = @_;
	
	my $database = $self->{default_database};
	return $database if defined $database;
	
	return if $self->{version} =~ m{^Neo4j/[123]\.};
	eval {
		my $sys = $driver->session(database => 'system');
		$database = $sys->run('SHOW DEFAULT DATABASE')->single->get('name');
	};
	croak $@ . "Session creation failed because the default "
	         . "database of $self->{version} at $self->{uri} "
	         . "could not be determined" unless defined $database;
	return $self->{default_database} = $database;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::ServerInfo - Provides Neo4j server address and version

=head1 VERSION

version 0.48

=head1 SYNOPSIS

 use Neo4j::Driver;
 $session = Neo4j::Driver->new->basic_auth(...)->session;
 
 $host_port = $session->server->address;
 $version_string = $session->server->version;
 say "Contacting $version_string at $host_port.";

=head1 DESCRIPTION

Provides some basic information of the server where the result
is obtained from.

To obtain server info, call L<Neo4j::Driver::Session/"server">.

=head1 METHODS

L<Neo4j::Driver::ServerInfo> implements the following methods.

=head2 address

 $host_port = $session->server->address;

Returns the host name and port number of the server. Takes the form
of an URL authority string (for example: C<localhost:7474>).

=head2 agent

 $agent_string = $session->server->agent;

Returns the product name and version number. Takes the form of
a server agent string (for example: C<Neo4j/3.5.17>).

=head2 protocol_version

 $bolt_version = $session->server->protocol_version;

Returns the Bolt protocol version with which the remote server
communicates. Takes the form of a string C<"$major.$minor">
where the major and minor version numbers both are integers.

When the HTTP protocol is used instead of Bolt, this method
returns an undefined value.

If the Bolt protocol is used, but the version number is unknown,
an empty string is returned. This situation shouldn't occur unless
you use L<Neo4j::Bolt> S<version 0.20> or older.

=head2 version

 $agent_string = $session->server->version;

Alias for L<C<agent()>|/"agent">.

Use of C<version()> is discouraged since version 0.26.
This method may be deprecated and removed in future.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Driver::B<Session>>,
L<Neo4j::Driver::B<ResultSummary>>

=item * Equivalent documentation for the official Neo4j drivers:
L<ServerInfo (Java)|https://neo4j.com/docs/api/java-driver/5.2/org.neo4j.driver/org/neo4j/driver/summary/ServerInfo.html>,
L<IServerInfo (.NET)|https://neo4j.com/docs/api/dotnet-driver/5.2/html/24780fbc-1b81-92a8-97f6-a484475e18dc.htm>,
L<ServerInfo (Python)|https://neo4j.com/docs/api/python-driver/5.2/api.html#serverinfo>

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
