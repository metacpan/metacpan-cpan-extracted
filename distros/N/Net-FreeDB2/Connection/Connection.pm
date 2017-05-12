package Net::FreeDB2::Connection;

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

require 5.005_62;
use strict;
use warnings;
use Error qw (:try);

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::FreeDB2::Connection ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our ( $VERSION ) = '$Revision: 0.8.2.4 $ ' =~ /\$Revision:\s+([^\s]+)/;

sub new {

	my $class = shift;

	my $self = {};
	bless ($self, (ref($class) || $class));
	return ($self->_initialize (@_));
}

sub _initialize {
	my $self = shift;
	my $opt = shift || {};

	# Set client_name and client_version
	defined ($opt->{client_name}) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::_initialize, mandatory option \'client_name\' missing.');
	$self->setClientName ($opt->{client_name});
	defined ($opt->{client_version}) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::_initialize, mandatory option \'client_version\' missing.');
	$self->setClientVersion ($opt->{client_version});

	# Set client_host
	if ($opt->{client_host}) {
		$self->setClientHost ($opt->{client_host});
	} else {
		use Sys::Hostname;
		$self->setClientHost (&Sys::Hostname::hostname ());
	}

	# Set client_user
	if ($opt->{client_user}) {
		$self->setClientUser ($opt->{client_user});
	} else {
		$self->setClientUser (scalar (getpwuid ($>)));
	}

	# Set freedb_host
	if ($opt->{freedb_host}) {
		$self->setFreeDBHost ($opt->{freedb_host});
	} else {
		$self->setFreeDBHost ('freedb.freedb.org');
	}

	# Set freedb_port
	$self->setFreeDBPort ($opt->{freedb_port});

	# Set proxy_host
	$self->setProxyHost ($opt->{proxy_host});

	# Set proxy_port
	$self->setProxyPort ($opt->{proxy_port});

	# Set proxy_user
	$self->setProxyUser ($opt->{proxy_user});

	# Set proxy_passwd
	$self->setProxyPasswd ($opt->{proxy_passwd});

	# Connect
	exists ($opt->{no_connect}) || $self->connect ();

	# Return instance
	return ($self);
}

sub connect {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::connect, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub lscat {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::lscat, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub query {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::query, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub read {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::read, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub write {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::write, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub help {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::help, oh come on, RTFM!!!");
}

sub log {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::log, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub motd {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::motd, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub discid {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::discid, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub proto {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::proto, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub sites {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::sites, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub stat {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::stat, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub ver {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::ver, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub update {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::update, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub whom {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::whom, call this method either in package Net::FreeDB2::CDDBP or in package Net::FreeDB2::HTTP.");
}

sub setClientName {
	my $self = shift;

	# Set client name
	$self->{Net_FreeDB2_Connection}{client_name} = shift;
}

sub getClientName {
	my $self = shift;

	# Return client version
	return ($self->{Net_FreeDB2_Connection}{client_name});
}

sub setClientVersion {
	my $self = shift;

	# Set client version
	$self->{Net_FreeDB2_Connection}{client_version} = shift;
}

sub getClientVersion {
	my $self = shift;

	# Return client name
	return ($self->{Net_FreeDB2_Connection}{client_version});
}

sub setClientHost {
	my $self = shift;

	# Set client host
	$self->{Net_FreeDB2_Connection}{client_host} = shift;
}

sub getClientHost {
	my $self = shift;

	# Return client host
	return ($self->{Net_FreeDB2_Connection}{client_host});
}

sub setClientUser {
	my $self = shift;

	# Set client user
	$self->{Net_FreeDB2_Connection}{client_user} = shift;
}

sub getClientUser {
	my $self = shift;

	# Return client user
	return ($self->{Net_FreeDB2_Connection}{client_user});
}

sub setFreeDBHost {
	my $self = shift;

	# Set freedb/cddb host
	$self->{Net_FreeDB2_Connection}{freedb_host} = shift;
}

sub getFreeDBHost {
	my $self = shift;

	# Return freedb/cddb host
	return ($self->{Net_FreeDB2_Connection}{freedb_host});
}

sub setFreeDBPort {
	my $self = shift;

	# Set freedb/cddb port
	$self->{Net_FreeDB2_Connection}{freedb_port} = shift;
}

sub getFreeDBPort {
	my $self = shift;

	# Return freedb/cddb port
	return ($self->{Net_FreeDB2_Connection}{freedb_port});
}

sub setProxyHost {
	my $self = shift;

	# Set proxy host
	$self->{Net_FreeDB2_Connection}{proxy_host} = shift;
}

sub getProxyHost {
	my $self = shift;

	# Return proxy host
	return ($self->{Net_FreeDB2_Connection}{proxy_host});
}

sub setProxyPort {
	my $self = shift;

	# Set proxy port
	$self->{Net_FreeDB2_Connection}{proxy_port} = shift;
}

sub getProxyPort {
	my $self = shift;

	# Return proxy port
	return ($self->{Net_FreeDB2_Connection}{proxy_port});
}

sub setProxyUser {
	my $self = shift;

	# Set proxy user
	$self->{Net_FreeDB2_Connection}{proxy_user} = shift;
}

sub getProxyUser {
	my $self = shift;

	# Return proxy user
	return ($self->{Net_FreeDB2_Connection}{proxy_user});
}

sub setProxyPasswd {
	my $self = shift;

	# Set proxy passwd
	$self->{Net_FreeDB2_Connection}{proxy_passwd} = shift;
}

sub getProxyPasswd {
	my $self = shift;

	# Return proxy passwd
	return ($self->{Net_FreeDB2_Connection}{proxy_passwd});
}

sub setConnection {
	my $self = shift;

	# Set connection
	$self->{Net_FreeDB2_Connection}{connection} = shift;
}

sub getConnection {
	my $self = shift;

	# Return connection
	return ($self->{Net_FreeDB2_Connection}{connection});
}

1;
__END__

=head1 NAME

Net::FreeDB2::Connection - FreeDB/CDDB abstract connection class

=head1 SYNOPSIS

See L<Net::FreeDB2>.

=head1 DESCRIPTION

C<Net::FreeDB2::Connection> is an abstract class to represent connections to FreeDB/CDDB servers. After a successfull connection, FreeDB/CDDB queries, reads etc can be made to obtain/provide information from/to FreeDB/CDDB databases.

=head1 CONSTRUCTOR

=over

=item new (OPT_HASH_REF)

Creates a new C<Net::FreeDB2::Connection> object. By default C<connect ()> is called to initiate the connection but see option C<no_connect>. See the implementation for complements/restrictions.

Options for C<OPT_HASH_REF> may include:

=over

=item client_name

Mandatory option to name the connecting client software.

=item client_version

Mandatory option with the client software version string.

=item client_host

The hostname of the client. Defaults to C<&Sys::Hostname::hostname ()>.

=item client_user

The user of the client. Defaults to C<scalar (getpwuid ($E<gt>))>;

=item freedb_host

The FreeDB/CDDB host. Defaults to C<freedb.freedb.org>.

=item freedb_port

The port on the FreeDB/CDDB host.

=item proxy_host

Proxy host.

=item proxy_port

Port on the proxy host. Defaults to C<8080>.

=item proxy_user

Proxy user name to use.

=item proxy_passwd

Proxy password to use.

=item no_connect

Do not call C<connect ()> during instanciation.

=back

=back

=head1 METHODS

=over 

=item connect ()

Set up a connection to the FreeDB/CDDB server after which the methods C<lscat ()>, C<query ()>, C<read ()>, C<write ()>, C<log ()>, C<motd ()>, C<discid ()>, C<proto ()>, C<sites ()>, C<stat ()>, C<ver ()>, C<update ()> and C<whom ()> may be called.

=item lscat ()

Issues an C<lscat> command on the FreeDB/CDDB database. Returns an C<ARRAY> with available categories.

=item query (ENTRY)

Queries the FreeDB/CDDB database using C<ENTRY> which is a C<Net::FreeDB2::Entry> object. Returns a C<Net::FreeDB2::Response::Query> object.

=item read (MATCH)

Reads an entry from the FreeDB/CDDB database using C<MATCH> which is a C<Net::FreeDB2::Match> object. Returns a C<Net::FreeDB2::Response::Read> object.

=item write (ENTITY)

Writes the specified C<Net::FreeDB2::Entry> object to the FreeDB/CDDB database. TO BE SPECIFIED

=item log ()

Issues an C<log> command on the FreeDB/CDDB database. TO BE SPECIFIED

=item motd ()

Issues an C<motd> command on the FreeDB/CDDB database. Returns an C<ARRAY> containing the motd lines.

=item discid (ENTRY)

Issues an C<discid> command on the FreeDB/CDDB database using the C<Net::FreeDB2::Entry> object C<ENTRY>. Returns the discid as calculated by FreeDB/CDDB.

=item proto ()

Issues an C<proto> command on the FreeDB/CDDB database. TO BE SPECIFIED

=item sites ()

Issues an C<sites> command on the FreeDB/CDDB database. Returns a C<Net::FreeDB2::Response::Sites> object.

=item stat ()

Issues an C<stat> command on the FreeDB/CDDB database. TO BE SPECIFIED

=item ver ()

Issues a C<ver> command on the FreeDB/CDDB database. TO BE SPECIFIED

=item update ()

Issues an C<update> command on the FreeDB/CDDB database. TO BE SPECIFIED

=item whom ()

Issues a C<whom> command on the FreeDB/CDDB database. TO BE SPECIFIED

=item setClientHost (VALUE)

Set the client host attribute. C<VALUE> is the value.

=item getClientHost ()

Returns the client host attribute.

=item setClientUser (VALUE)

Set the client user attribute. C<VALUE> is the value.

=item getClientUser ()

Returns the client user attribute.

=item setClientName (VALUE)

Set the client name attribute. C<VALUE> is the value.

=item getClientName ()

Returns the client name attribute.

=item setClientVersion (VALUE)

Set the client version attribute. C<VALUE> is the value.

=item getClientVersion ()

Returns the client version attribute.

=item getClientUser ()

Returns the client user attribute.

=item setFreeDBHost (VALUE)

Set the FreeDB/CDDB host attribute. C<VALUE> is the value.

=item getFreeDBHost ()

Returns the FreeDB/CDDB host attribute.

=item setFreeDBPort (VALUE)

Set the FreeDB/CDDB port attribute. C<VALUE> is the value.

=item getFreeDBPort ()

Returns the FreeDB/CDDB port attribute.

=item setProxyHost (VALUE)

Set the proxy host attribute. C<VALUE> is the value.

=item getProxyHost ()

Returns the proxy host attribute.

=item setProxyPort (VALUE)

Set the proxy port attribute. C<VALUE> is the value.

=item getProxyPort ()

Returns the proxy port attribute.

=item setProxyUser (VALUE)

Set the proxy user attribute. C<VALUE> is the value.

=item getProxyUser ()

Returns the proxy user attribute.

=item setProxyPasswd (VALUE)

Set the proxy password attribute. C<VALUE> is the value.

=item getProxyPasswd ()

Returns the proxy password attribute.

=item setConnection (VALUE)

Set the connection attribute. C<VALUE> is the value.

=item getConnection ()

Returns the connection attribute.

=back

=head1 EXCEPTIONS

Generally, in exceptional situations, C<Error::Simple> exceptions are thrown. See the implementations of this abstract class for details.

=head1 SEE ALSO

L<Net::FreeDB2::Entry>, L<Net::FreeDB2::Match>, L<Net::FreeDB2::Response>, L<Net::FreeDB2::Response::Query> and L<Net::FreeDB2::Response::Read>

=head1 BUGS

None known (yet).

=head1 HISTORY

First development: September 2002

=head1 AUTHOR

Vincenzo Zocca E<lt>Vincenzo@Zocca.comE<gt>

=head1 COPYRIGHT

Copyright 2002, Vincenzo Zocca.

=head1 LICENSE

This file is part of the C<Net::FreeDB2> module hierarchy for Perl by
Vincenzo Zocca.

The Net::FreeDB2 module hierarchy is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

The Net::FreeDB2 module hierarchy is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the Net::FreeDB2 module hierarchy; if not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

=cut

