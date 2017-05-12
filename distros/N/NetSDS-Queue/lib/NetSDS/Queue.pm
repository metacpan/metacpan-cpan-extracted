#===============================================================================
#
#         FILE:  Queue.pm
#
#  DESCRIPTION:  NetSDS Queue API
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  12.07.2009 11:41:24 UTC
#===============================================================================

=head1 NAME

NetSDS::Queue - simple API to MemcacheQ powered queue

=head1 SYNOPSIS

	use NetSDS::Queue;
	use Data::Dumper;

	my $q = NetSDS::Queue->new( server => '10.0.0.5:18181' );

	# Push messages to queue
	$q->push('myq', { id => 1, text => 'one'});
	$q->push('myq', { id => 2, text => 'two'});
	$q->push('myq', { id => 3, text => 'three'});

	# Fetch messages from queue
	while ( my $data = $q->pull('myq') ) {
		print Dumper($data);
	}

=head1 DESCRIPTION

C<NetSDS::Queue> module provides simple API to NetSDS queue.

Low level messaging is based on fast and reliable MemcacheQ server.
It use BerkeleyDB for persistance and Memchache protocol over TCP
or Unix sockets.

Every message is converted to JSON and then stored as Base64 string.

=cut

package NetSDS::Queue;

use 5.8.0;
use strict;
use warnings;

use Cache::Memcached::Fast;
use NetSDS::Util::Convert;
use JSON;

use base qw(NetSDS::Class::Abstract);

use version; our $VERSION = "0.032";

#===============================================================================
#

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

The following parameters accepted:

* server - address to MemcacheQ queue server (host:port)

* max_size - maximum size of message allowed (default is 4096 bytes)

	my $queue = NetSDS::Queue->new(server => '192.168.0.1:12345');

Default server address is 127.0.0.1:22201

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new();

	# Set server (default is 127.0.0.1:22201)
	my $server = '127.0.0.1:22201';
	if ( $params{'server'} ) {
		$server = $params{'server'};
	}

	# Set message size limitation
	$this->{max_size} = 4096;
	if ( $params{'max_size'} ) {
		$this->{max_size} = $params{'max_size'};
	}
	$this->mk_accessors('max_size');

	# Initialize memcacheq handler
	$this->{handler} = Cache::Memcached::Fast->new(
		{
			servers         => [$server],
			connect_timeout => 5,
		}
	);

	# Create accessors
	$this->mk_accessors('handler');

	if ( $this->handler ) {
		return $this;
	} else {
		return undef;
	}

} ## end sub new

#***********************************************************************

=item B<push($queue, $data)> - push message to queue

	$queue->push('msgq', $my_data);

=cut

#-----------------------------------------------------------------------

sub push {

	my ( $this, $queue, $data ) = @_;

	my $push_data = _encode($data);

	# Check if data for push is not more than max_size
	if ( bytes::length($push_data) > $this->max_size() ) {
		return $this->error( "Cant insert message bigger than max_size (" . $this->max_size . ")" );
	}
	return $this->handler->set( $queue, $push_data );

}

#***********************************************************************

=item B<pull($queue)> - fetch message from queue

	my $data = $queue->pull('msgq');

=cut

#-----------------------------------------------------------------------

sub pull {

	my ( $this, $queue ) = @_;

	return _decode( $this->handler->get($queue) );

}

sub _encode {

	my ($struct) = @_;
	return conv_str_base64( encode_json($struct) );
}

sub _decode {

	my ($string) = @_;

	if ($string) {
		return decode_json( conv_base64_str($string) );
	} else {
		return undef;
	}
}

1;

__END__

=back

=head1 EXAMPLES

See files in C<samples> catalog.

=head1 BUGS

Unknown yet

=head1 SEE ALSO

http://memcachedb.org/memcacheq/ - MemcacheQ server

http://openhack.ru/Cache-Memcached-Fast - Perl XS API to Memcached servers

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Michael Bochkaryov

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


