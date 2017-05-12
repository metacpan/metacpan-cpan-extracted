#  -*- mode: cperl; cperl-indent-level:8; tab-width:8; indent-tabs-mode:t; -*-

#  File: Stem/Inject.pm

#  This file is part of Stem.
#  Copyright (C) 1999, 2000, 2001 Stem Systems, Inc.

#  Stem is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.

#  Stem is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with Stem; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#  For a license to use the Stem under conditions other than those
#  described here, to purchase support for this software, or to purchase a
#  commercial warranty contract, please contact Stem Systems at:

#       Stem Systems, Inc.		781-643-7504
#  	79 Everett St.			info@stemsystems.com
#  	Arlington, MA 02474
#  	USA

#######################################################

package Stem::Inject ;

use strict ;

use IO::Socket ;

use Stem::Msg ;
use Stem::Packet ;

my $attr_spec = [

	{
		'name'		=> 'host',
		'required'	=> 1,
		'help'		=> <<HELP,
The hostname to use when connecting to the portal.
HELP
	},

	{
		'name'		=> 'port',
		'required'	=> 1,
		'help'		=> <<HELP,
The port to use when connecting to the portal.
HELP
	},

	{
		'name'		=> 'to',
		'required'	=> 1,
		'help'		=> <<HELP,
The cell to which the message is addressed.
HELP
	},

	{
		'name'		=> 'type',
		'required'	=> 1,
		'help'		=> <<HELP,
This is the type of the message. It is used to select the delivery method in
the addressed Cell.
HELP
	},

	{
		'name'		=> 'cmd',
		'help'		=> <<HELP,
This is used for the delivery method if the message type is 'cmd'.
HELP
	},

	{
		'name'		=> 'codec',
		'help'		=> <<HELP,
The Stem::Codec module to use when creating packets.
HELP
	},

	{
		'name'		=> 'data',
		'help'		=> <<HELP,
This is the data the message is carrying. It should (almost) always be
a reference.
HELP
	},

	{
		'name'		=> 'timeout',
		'default'	=> 60,
		'help'		=> <<HELP,
The timeout before giving up on getting a reply from the portal, in
seconds.  Defaults to 60.
HELP
	},

	{
		'name'		=> 'wait_for_reply',
		'default'	=> 1,
		'help'		=> <<HELP,
Indicates whether or not a reply is expected.  Defaults to true.
HELP
	},

] ;

sub inject {

	my $class = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	$self->{'from'} = "Stem::Inject:inject$$";

	$self->{'packet'} =
	    Stem::Packet->new( codec => $self->{'codec'} ) ;

	local $SIG{'ALRM'} = sub { die 'Read or write to socket timed out' };

	my $result;

	eval {

		my $address = "$self->{'host'}:$self->{'port'}";
		$self->{'sock'} = IO::Socket::INET->new($address) ;
		$self->{'sock'} or die "can't connect to $address\n" ;

		alarm $self->{'timeout'} if $self->{'timeout'} ;

		$self->_register() ;

		$result = $self->_inject_msg() ;
	} ;

	alarm 0 ;

	return $@ if $@ ;

	return unless $self->{'wait_for_reply'};

	return $result ;
}

sub _register {

	my( $self, $data ) = @_ ;

	my $reg_msg =
	    Stem::Msg->new( from => $self->{'from'},
			    type => 'register',
			  ) ;

	die $reg_msg unless ref $reg_msg ;

	my $reg = $self->{'packet'}->to_packet($reg_msg) ;

	my $written = syswrite( $self->{'sock'}, $$reg ) ;
	defined $written or die "can't write to socket\n" ;

	my $read_buf ;
	while (1) {

		my $bytes_read = sysread( $self->{'sock'}, $read_buf, 8192 ) ;

		defined $bytes_read or die "can't read from socket" ;
		last if $bytes_read == 0 ;

		my $data = $self->{'packet'}->to_data( $read_buf ) ;

		last;
	}
}

sub _inject_msg {

	my( $self ) = @_;

	my %msg_p =
	    ( 'to'   => $self->{'to'},
	      'from' => $self->{'from'},
	      'type' => $self->{'type'},
	    ) ;

	$msg_p{'cmd'}  = $self->{'cmd'} if $self->{'type'} eq 'cmd';
	$msg_p{'data'} = $self->{'data'},

	my $data_msg = Stem::Msg->new(%msg_p) ;

	die $data_msg unless ref $data_msg ;

	my $data = $self->{'packet'}->to_packet($data_msg) ;

	my $written = syswrite( $self->{'sock'}, $$data ) ;
	defined $written or die "can't write to socket\n" ;

	return unless $self->{'wait_for_reply'};

	my $read_buf ;
	while (1) {

		my $bytes_read = sysread( $self->{'sock'}, $read_buf, 8192 ) ;

		defined $bytes_read or die "can't read from socket" ;
		last if $bytes_read == 0 ;

		my $reply = $self->{'packet'}->to_data( $read_buf ) ;

		return $reply->data ;
	}
}

1 ;

__END__

=pod

=head1 NAME

Stem::Inject - Inject a message into a portal via a socket connection

=head1 SYNOPSIS

  my $return =
      Stem::Inject->inject( to   => 'some_cell',
                            type => 'do_something',
                            port => 10200,
                            host => 'localhost',
                            data => { foo => 1 },
                          );

  # do something with data returned

=head1 USAGE

This class contains just one method, C<inject>, which can be used to
inject a single message into a Stem hub, via a known server portal.

This is very useful if you have a synchronous system which needs to
communicate with a Stem system via messages.

=head1 METHODS

=over 4

=item * inject

This method is the sole interface provided by this class.  It accepts
the following parameters:

=over 8

=item * host (required)

This parameter specifies the host with which to connect.

=item * port (required)

The port with which to connect on the specified host.

=item * to (required)

The address of the cell to which the message should be delivered.

=item * type (required)

The type of the message to be delivered.

=item * cmd

The cmd being given.  This is only needed if the message's type is
"cmd".

=item * data

The data that the message will carry, if any.

=item * codec

The codec to be used when communicating with the port.  This defaults
to "Data::Dumper", but be careful to set this to whatever value the
receiving port is using.

=item * timeout (defaults to 60)

The amount of time, in seconds, before giving up on message delivery
or reply.  This is the I<total> amount of time allowed for message
delivery and receiving a reply.

=item * wait_for_reply (defaults to true)

If this is true then the C<inject> method will expect a reply to the
message it delivers.  If it doesn't receive one this will be
considered an error.

=back

If there is an error in trying to inject a message, either with the
parameters given, or with the socket connection, then this method will
return an error string.

If no reply was expected, this method simply returns false.
Otherwise, it returns the reply message's data, which will always be a
reference.

=back

=head1 AUTHOR

Dave Rolsky <david@stemsystems.com>

=cut
