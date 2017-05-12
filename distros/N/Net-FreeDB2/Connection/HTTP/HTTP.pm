package Net::FreeDB2::Connection::HTTP;

# Copyright 2002, Vincenzo Zocca.

# See LICENSE section for usage and distribution rights.

require 5.005_62;
use strict;
use warnings;
use Error qw (:try);

require Exporter;
use AutoLoader qw(AUTOLOAD);

#our @ISA = qw(Net::FreeDB2::Connection Exporter);
use base qw (Net::FreeDB2::Connection Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::FreeDB2::Connection::HTTP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our ( $VERSION ) = '$Revision: 0.8.2.3 $ ' =~ /\$Revision:\s+([^\s]+)/;

sub new {
	# Call constructor of super class
	my $self = &Net::FreeDB2::Connection::new (@_);

	# Shift out this class specification
	shift;

	# Return object
	return ($self);
}

sub _initialize {
	my $self = shift;

	# Get options
	my $opt = shift || {};

	# Set freedb_cgi
	$self->setFreeDBCgi ($opt->{freedb_cgi} || '~cddb/cddb.cgi');

	# Initialize super class
	return ($self->SUPER::_initialize ($opt));
}

sub hello {
}

sub lscat {
	my $self = shift;

	# Send command and wait for reply
	my $content_ref = $self->waitCommandReply ('?cmd=cddb+lscat', {
		210 => 1,
	});

	# Parse the result
	my @content = split (/[\n\r]+/, ${$content_ref});
	my $head = shift (@content);
	my @cat = ();
	foreach my $cat (@content) {
		last if ($cat eq '.');
		push (@cat, $cat);
	}
	return (@cat);
}

sub query {
	my $self = shift;
	my $entity = shift;

	# Send command and wait for reply
	my $query = $entity->mkQuery ();
	$query =~ s/\s+/+/g;
	my $cmd = '?cmd=cddb+query+' . $query;
	my $content_ref = $self->waitCommandReply ($cmd, {
		200 => 1,
		211 => 1,
		202 => 1,
		403 => 1,
		409 => 1,
	});

	# Parse the result
	use Net::FreeDB2::Response::Query;
	return Net::FreeDB2::Response::Query->new ({
		content_ref => $content_ref,
	});
}

sub read {
	my $self = shift;
	my $match = shift;

	# Send command and wait for reply
	my $cmd = '?cmd=cddb+read+' . $match->getCateg () . '+' . $match->getDiscid ();
	my $content_ref = $self->waitCommandReply ($cmd, {
		200 => 1,
		211 => 1,
		202 => 1,
		403 => 1,
		409 => 1,
	});

	# Parse the result
	use Net::FreeDB2::Response::Read;
	return Net::FreeDB2::Response::Read->new ({
		content_ref => $content_ref,
	});
}

sub write {
	throw Error::Simple ("ERROR: Net::FreeDB2::Connection::HTTP::write, command not supported under HTTP.");
}

sub log {
	throw Error::Simple ("ERROR: Net::FreeDB2::HTTP::log, to be implemented.");
}

sub motd {
	my $self = shift;

	# Send command and wait for reply
	my $content_ref = $self->waitCommandReply ('?cmd=motd', {
		210 => 1,
		401 => 1,
	});

	# Parse the result
	my @content = split (/[\n\r]+/, ${$content_ref});
	my $head = shift (@content);
	my @motd = ();
	foreach my $motd (@content) {
		last if ($motd eq '.');
		push (@motd, $motd);
	}
	return (@motd);
}

sub discid {
	my $self = shift;
	my $entity = shift;

	# Send command and wait for reply
	my $discid = $entity->mkQuery ();
	$discid =~ s/^\s*\S+\s+//;
	$discid =~ s/\s+/+/g;
	my $cmd = '?cmd=discid+' . $discid;
	my $content_ref = $self->waitCommandReply ($cmd, {
		200 => 1,
		500 => 1,
	});

	# Parse the result
	my @content = split (/[\n\r]+/, ${$content_ref});
	my $head = shift (@content);
	my ($code) = $head =~ /^\s*(\d{3})\s+/;
	$code == 200 || $code == 500 || throw Error::Simple ("ERROR: Net::FreeDB2::Connection::HTTP::discid, unknown code '$code' returned.");
	$code == 500 && throw Error::Simple ("ERROR: Net::FreeDB2::Connection::HTTP::discid, Command Syntax error.");
	my @head = split (/\s+/, $head);
	return ($head[4]);
}

sub proto {
	throw Error::Simple ("ERROR: Net::FreeDB2::HTTP::proto, to be implemented.");
}

sub sites {
	my $self = shift;

	# Send command and wait for reply
	my $content_ref = $self->waitCommandReply ('?cmd=sites', {
		200 => 1,
		500 => 1,
	});

	# Parse the result
	use Net::FreeDB2::Response::Sites;
	return Net::FreeDB2::Response::Sites->new ({
		content_ref => $content_ref,
	});
}

sub stat {
	throw Error::Simple ("ERROR: Net::FreeDB2::HTTP::stat, to be implemented.");
}

sub ver {
	throw Error::Simple ("ERROR: Net::FreeDB2::HTTP::ver, to be implemented.");
}

sub update {
	throw Error::Simple ("ERROR: Net::FreeDB2::HTTP::update, to be implemented.");
}

sub whom {
	throw Error::Simple ("ERROR: Net::FreeDB2::HTTP::whom, to be implemented.");
}

sub connect {
	my $self = shift;

	# Make connection through user agent
	use LWP::UserAgent;
	my $connection = LWP::UserAgent->new ();
	defined ($connection) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::HTTP::connect, Failed to instanciate an \'LWP::UserAgent\' object.');
	$self->setConnection ($connection);

	# Set proxy if required
	defined ($self->getProxyHost ()) || return;
	my $url =  'http://' . $self->getProxyHost() . ':' . ($self->getProxyPort () || 8080);
	$connection->proxy ('http', $url);
}

sub waitCommandReply {
        my $self = shift;
        my $cmd = shift;
        my $rx = shift;

	# Check if connection is defined
	defined ($self->getConnection ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::HTTP::waitCommandReply, no connection available.');

	# Make url
	my $url = $self->mkUrlBase ();
	$url .= $cmd . $self->mkHello ();

	# Make request
	use HTTP::Request;
	my $request = HTTP::Request->new (GET => $url);
	defined ($request) || throw Error::Simple ("ERROR: Net::FreeDB2::Connection::HTTP::waitCommandReply, failed to make HTTP::Request object out of url '$url'.");

	# Set proxy authorization if required
	if ($self->getProxyHost () && $self->getProxyUser ()) {
		$request->proxy_authorization_basic ($self->getProxyUser (), $self->getProxyPasswd ());
	}

	# Execute the request through the connection
	my $response = $self->getConnection ()->simple_request ($request);
	$response->is_success() || throw Error::Simple ("ERROR: Net::FreeDB2::Connection::HTTP::waitCommandReply, failed to execute request for url '$url'.");


        # Return the content reference
        return ($response->content_ref ());
}

sub mkHello {
	my $self = shift;

	defined ($self->getClientName ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::HTTP::mkHello, \'client_name\' not set.');
	defined ($self->getClientVersion ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::HTTP::mkHello, \'client_version\' not set.');
	defined ($self->getClientHost ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::HTTP::mkHello, \'client_host\' not set.');
	defined ($self->getClientUser ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::HTTP::mkHello, \'client_user\' not set.');

	return ('&hello=' . join ('+',
		$self->getClientUser (),
		$self->getClientHost (),
		$self->getClientName (),
		$self->getClientVersion (),
		) .
		'&proto=1'
	);
}

sub mkUrlBase {
	my $self = shift;

	defined ($self->getFreeDBHost ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::HTTP::mkUrlBase, \'freedb_host\' not set.');
	defined ($self->getFreeDBCgi ()) || throw Error::Simple ('ERROR: Net::FreeDB2::Connection::HTTP::mkUrlBase, \'freedb_cgi\' not set.');
	my $url = 'http://' .  $self->getFreeDBHost ();
	$url .= ':' . $self->getFreeDBPort () if ($self->getFreeDBPort ());
	$url .= '/' . $self->getFreeDBCgi ();
}

sub setFreeDBCgi {
	my $self = shift;

	# Set freedb/cddb url
	$self->{Net_FreeDB2_Connection_HTTP}{freedb_cgi} = shift;
}

sub getFreeDBCgi {
	my $self = shift;

	# Return freedb/cddb url
	return ($self->{Net_FreeDB2_Connection_HTTP}{freedb_cgi});
}

1;
__END__

=head1 NAME

Net::FreeDB2::Connection::HTTP - FreeDB/CDDB concrete connection class using the HTTP protocol

=head1 SYNOPSIS
 
See L<Net::FreeDB2::Connection>.

=head1 DESCRIPTION

C<Net::FreeDB2::Connection::HTTP> is a concrete C<FreeDB/CDDB> connection class that uses the HTTP protocol to connect to C<FreeDB/CDDB> servers.

=head1 CONSTRUCTOR

=over

=item new (OPT_HASH_REF)

Creates a new C<Net::FreeDB2::Connection::HTTP> object. Throws a C<Error::Simple> exception if a mandatory option is missing.

See L<Net::FreeDB2::Connection> for allowed/mandatory options for C<OPT_HASH_REF>. Additionally the follwoing option is allowed:

=over

=item freedb_cgi

The FreeDB/CDDB cgi path. Defaults to C<~cddb/cddb.cgi>.

=back

=back

=head1 METHODS

=over 

=item hello ()

C<hello> is not supported under HTTP. This method does not do anything.

=item lscat ()

Issues an C<lscat> command on the FreeDB/CDDB database. Returns an C<ARRAY> with available categories. Throws an C<Error::Simple> exception if no connection is made, if the instanciation of an C<HTTP::Request> object fails or if the HTTP request fails. Also, exceptions from C<mkHello ()> or C<mkUrlBase ()> may be thrown if an exceptional situation occurs.

=item query (ENTRY)

Queries the FreeDB/CDDB database using C<ENTRY> which is a C<Net::FreeDB2::Entry> object. Returns a C<Net::FreeDB2::Response::Query> object. Throws an C<Error::Simple> exception if no connection is made, if the instanciation of an C<HTTP::Request> object fails or if the HTTP request fails. Also, exceptions from C<mkHello ()> or C<mkUrlBase ()> may be thrown if an exceptional situation occurs.

=item read (MATCH)

Reads an entry from the FreeDB/CDDB database using C<MATCH> which is a C<Net::FreeDB2::Match> object. Returns a C<Net::FreeDB2::Response::Read> object. Throws an C<Error::Simple> exception if no connection is made, if the instanciation of an C<HTTP::Request> object fails or if the HTTP request fails. Also, exceptions from C<mkHello ()> or C<mkUrlBase ()> may be thrown if an exceptional situation occurs.

=item write (ENTITY)

Quote from CDDBPROTO: 'All CDDBP commands are supported under HTTP, except for "cddb hello", "cddb write", "proto" and "quit".' Therefor this method only throws an C<Error::Simple> exception.

=item log ()

Issues an C<log> command on the FreeDB/CDDB database. TO BE IMPLEMENTED

=item motd ()

Issues an C<motd> command on the FreeDB/CDDB database. Returns an C<ARRAY> containing the motd lines. Throws an C<Error::Simple> exception if no connection is made, if the instanciation of an C<HTTP::Request> object fails or if the HTTP request fails. Also, exceptions from C<mkHello ()> or C<mkUrlBase ()> may be thrown if an exceptional situation occurs.

=item discid (ENTRY)

Issues an C<discid> command on the FreeDB/CDDB database using the C<Net::FreeDB2::Entry> object C<ENTRY>. Returns the discid as calculated by FreeDB/CDDB. Throws an C<Error::Simple> exception if no connection is made, if the instanciation of an C<HTTP::Request> object fails or if the HTTP request fails. Also, exceptions from C<mkHello ()> or C<mkUrlBase ()> may be thrown if an exceptional situation occurs.

=item proto ()

Issues an C<proto> command on the FreeDB/CDDB database. TO BE IMPLEMENTED

=item sites ()

Issues an C<sites> command on the FreeDB/CDDB database. Returns an C<ARRAY> with sites. Throws an C<Error::Simple> exception if no connection is made, if the instanciation of an C<HTTP::Request> object fails or if the HTTP request fails. Also, exceptions from C<mkHello ()> or C<mkUrlBase ()> may be thrown if an exceptional situation occurs.

=item stat ()

Issues an C<stat> command on the FreeDB/CDDB database. TO BE IMPLEMENTED

=item ver ()

Issues an C<ver> command on the FreeDB/CDDB database. TO BE IMPLEMENTED

=item update ()

Issues an C<update> command on the FreeDB/CDDB database. TO BE IMPLEMENTED

=item whom ()

Issues an C<whom> command on the FreeDB/CDDB database. TO BE IMPLEMENTED

=item connect ()

Connects to the FreeDB/CDDB database. Throws an C<Error::Simple> exception if the instanciation of the C<LWP::UserAgent> (which BTW forms the actiual connection) object fails.

=item mkHello ()

Makes a FreeDB/CDDB HTTP hello string for uasage by other FreeDB/CDDB command methods and returns it. Throws an C<Error::Simple> exception if client name, client version, client host or client user not set.

=item mkUrlBase ()

Makes a HTTP mase URL string for uasage by other FreeDB/CDDB command methods and returns it. Throws an C<Error::Simple> exception if FreeDB/CDDB host or FreeDB/CDDB cgi not set.

=item setFreeDBCgi (VALUE)

Set the FreeDB/CDDB cgi (e.g. C<~cddb/cddb.cgi>) attribute. C<VALUE> is the value.

=item getFreeDBCgi ()

Returns the FreeDB/CDDB cgi attribute.

=back

=head1 SEE ALSO

L<Net::FreeDB2::Entry>, L<Net::FreeDB2::Match>, L<Net::FreeDB2::Response>, L<Net::FreeDB2::Response::Query> and L<Net::FreeDB2::Response::Read>

=head1 BUGS

Not all FreeDB/CDDB commands are implemented (yet).

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

