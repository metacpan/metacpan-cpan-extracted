#===============================================================================
#
#       MODULE:  NetSDS::Session
#
#  DESCRIPTION:  Memcached based session data storage
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#
#===============================================================================

=head1 NAME

B<NetSDS::Session> - memcached based session storage API

=head1 SYNOPSIS

	use NetSDS::Session;

	# Connecting to Memcached server
	my $sess = NetSDS::Session->new(
		host => '12.34.56.78',
		port => '12345',
	);

	...

	# Retrieve session key somehow
	$session_key = $cgi->param('sess_key');

	$sess->open($session_key);

	my $filter = $sess->get('filter');
	...
	$sess->set('filter', $new_filter);
	...
	$sess->close();

	1;

=head1 DESCRIPTION

C<NetSDS::Session> module provides API to session data storage based on Memcached server.

Each session represented as hash reference structure identified by UUID string.
Most reasonable usage of this module is a temporary data storing for web based GUI
between HTTP requests. However it's possible to find some other tasks.

Internally session structure is transformed to/from JSON string when interacting with Memcached.

=cut

package NetSDS::Session;

use 5.8.0;
use strict;
use warnings;

use version; our $VERSION = '1.301';

use Cache::Memcached::Fast;
use JSON;

use base 'NetSDS::Class::Abstract';

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

Constructor establish connection to memcached server and set default session parameters.

Parameters:

	* host - memcached server hostname or IP address (default: 127.0.0.1)
	* port - memcached server TCP port (default: 11211)

Example:

	my $sess_hdl = NetSDS::Session->new(
		host => '12.34.56.78',
		port => '99999',
	);

=cut

sub new {

	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(
		session_id   => undef,    # session id (UUID string)
		session_data => {},       # session data as hash reference
		%params
	);

	# Prepare server address string (host:port)
	my $mc_host = $params{'host'} || '127.0.0.1';
	my $mc_port = $params{'port'} || '11211';

	# Initialize memcached handler
	$self->{memcached} = Cache::Memcached::Fast->new(
		{
			servers           => [                      { address => $mc_host . ':' . $mc_port } ],
			serialize_methods => [ \&JSON::encode_json, \&JSON::decode_json ],
		}
	);

	if ( $self->{memcached} ) {
		return $self;
	} else {
		return $class->error("Can't create memcached connection handler");
	}

} ## end sub new

=item B<open($sess_id)> - open session

Retrieve session data from server by session key (UUID string)

If no session exists then empty hashref is returned.

=cut

sub open {

	my ( $self, $sess_id ) = @_;

	# Initialize session key and retrieve data
	$self->{_id}   = $sess_id;
	$self->{_data} = $self->{memcached}->get($sess_id);

	# If no such session stored then create empty hashref
	$self->{_data} ||= {};

	return $self;
}

=item B<id()> - get session id

Returns current session id.

Example:

	my $sess_id = $sess->id();

=cut

sub id {
	my $self = shift;
	return $self->{_id};
}

=item B<set($key, $value)> - set session parameter

Set new session parameter value identified by it's key.

Example:

	$sess->set('order', 'id desc');

=cut

sub set {
	my ( $self, $key, $value ) = @_;
	$self->{_data}->{$key} = $value;
	return 1;
}

=item B<get($key)> - get session parameter

Return session parameter value by it's key.

Example:

	my $order = $sess->get('order');

=cut

sub get {
	my ( $self, $key ) = @_;
	return $self->{_data}->{$key};
}

=item B<delete($key)> - delete session parameter by key

Delete session parameter by it's key.

Returns updated session data as hash reference.

Example:

	$sess->delete('order');

=cut

sub delete {
	my ( $self, $key ) = @_;

	delete $self->{_data}->{$key};
	return $self->{_data};
}

=item B<clear()> - clear session data

This method clears all session data.

Example:

	$sess->clear();

=cut

sub clear {
	my $self = shift;
	$self->{_data} = {};
}

=item B<sync()> - save session

Synchronize session data on Memcached server.

Example:

	$sess->sync();

=cut

sub sync {

	my $self = shift;

	return $self->id ? $self->{memcached}->set( $self->id, $self->{_data} ) : undef;

}

=item B<close()> - save and close session

This method save all data to server and clear current session id and data from object.

Example:

	$session->close();

=cut

sub close {

	my $self = shift;

	# Nothing to store for non existent session key
	unless ( $self->id ) {
		return undef;
	}

	# Store session data to memcached server
	# or clear it from server if it's empty
	if ( $self->{_data} == {} ) {
		$self->{memcached}->delete( $self->id );
	} else {
		$self->{memcached}->set( $self->id, $self->{_data} );
	}

	# Clear session id and data
	$self->{_id}   = undef;
	$self->{_data} = undef;

	return;
} ## end sub close

1;

__END__

=back

=head1 SEE ALSO

=over

=item * L<Cache::Memcached::Fast> - XS implementation of Memcached API

=item * L<JSON> - JSON encoding/decoding API

=back

=head1 AUTHORS

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 THANKS

Yana Kornienko - for initial module implementation

=head1 LICENSE

Copyright (C) 2008-2009 Net Style Ltd.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

