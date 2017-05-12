#===============================================================================
#
#         FILE:  Message.pm
#
#  DESCRIPTION:  Common mobile message class
#
#        NOTES:  ---
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  21.08.2009 14:24:18 EEST
#===============================================================================

=head1 NAME

NetSDS::Message - common mobile message (SMS, MMS, IM)

=head1 SYNOPSIS

	use NetSDS::Message;

	...

	$msg = NetSDS::Message->new(
		src_addr => '1234@mtsgw',
		dst_addr => '380441234567@mtsgw',
		body => $content,
	);


=head1 DESCRIPTION

C<NetSDS::Message> is a superclass for other modules implementing API
to exact structure of some messaging data (i.e. CPA2, SMS, MMS, etc).

This module implemented to avoid duplication of code providing common
functionality for all message types like managing addresses, headers,
preparing reply message and so on.

=cut

package NetSDS::Message;

use 5.8.0;
use strict;
use warnings;

use NetSDS::Util::Misc;

use base qw(NetSDS::Class::Abstract);

use version; our $VERSION = '0.021';

#===============================================================================
#

=head1 CLASS API

=over

=item B<new([...])> - class constructor

    my $object = NetSDS::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $this = $class->SUPER::new(
		message_id  => undef,    # internal message id
		src_addr    => undef,    # source address (addr@system)
		dst_addr    => undef,    # destination address (addr@system)
		subject     => undef,    # subject if exists
		media       => undef,    # messaging media ('sms', 'mms', 'ussd', etc)
		headers     => {},       # optional headers
		body        => {},       # message body (depends on media)
		external_id => undef,    # message id on external system (SMSC, SDP, customer, etc)
		format      => undef,    # message format ('cpa2', 'mtssmtp', 'smpp')
		%params
	);

	# Generate message id if absent
	if ( !$this->{message_id} ) {
		$this->{message_id} = $this->_make_id();
	}

	return $this;

} ## end sub new

#***********************************************************************

=item B<message_id([$value])> - set/get message id

	$msg_id = $msg->message_id();

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors('message_id');

#***********************************************************************

=item B<src_addr()> - set/get source address

	$msg->src_addr('380121234567@operatorgw');

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('src_addr');

#***********************************************************************

=item B<src_addr_native()> - get native form of source address

	# Set address
	$msg->src_addr('380121234567@operatorgw');

	# Get native form of address
	$phone = $msg->src_addr_native(); # return '380121234567'

=cut 

#-----------------------------------------------------------------------

sub src_addr_native {

	my ($this) = @_;

	if ( $this->src_addr =~ /(.*)@.*/ ) {
		return $1;
	} else {
		return $this->src_addr();
	}
}

#***********************************************************************

=item B<dst_addr()> - set/get destination address

	$dst_addr = $msg->dst_addr();

=cut 

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors('dst_addr');

#***********************************************************************

=item B<dst_addr_native()> - get native form of destination address

	if ($mo_msg->dst_addr_native() eq '1234') {
		print "Received SMS to 1234";
	}

=cut 

#-----------------------------------------------------------------------

sub dst_addr_native {

	my ($this) = @_;

	if ( $this->dst_addr =~ /(.*)@.*/ ) {
		return $1;
	} else {
		return $this->dst_addr();
	}
}

#***********************************************************************

=item B<subject()> - set/get message subject

	$msg->subject('Hello there');

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('subject');

#***********************************************************************

=item B<media()> - set/get message media

Paramters: new media if set or none if get

Supported media types: 'sms', 'mms', 'ussd'. In fact media types processing
is not responsibility of this module and implemented in other modules.

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('media');

#***********************************************************************

=item B<header($name[, $value])> - set/get header

Paramters: header name, new header value

Returns: header value

Message headers implemented as hash reference and contains supplementary
information about message. All header name characters are lowercased
and all '-' replaced with '_'.

	# Set header
	$msg->header('X-Beer', 'Guinness');

	# Get this header
	$beer = $msg->header('x_beer');

=cut 

#-----------------------------------------------------------------------

sub header {

	my ( $this, $name, $value ) = @_;

	# Normalize name first
	# All
	$name =~ s/-/_/g;
	$name = lc($name);

	if (defined $value) {
		$this->{headers}->{$name} = $value;
	}

	return $this->{headers}->{$name};
}

#***********************************************************************

=item B<format()> - get/set message format

Paramters: new format name

Returns: format name

Message format provides is related to transport layer code and describe
data structure of message body.

Supported formats:

B<sms> - generic SMS data for ETSI GSM 03.40 compliant implementations.
See L<NetSDS::Message::SMS> for details.

B<cpa2> - CPA2 compatible structure.
See L<NetSDS::Message::CPA2> for details.

=cut 

#-----------------------------------------------------------------------

__PACKAGE__->mk_accessors('format');

#***********************************************************************

=item B<reply()> - make reply message

This message allows to make reply to current one.
Source and destination message are exchanged, media left the same.

=cut 

#-----------------------------------------------------------------------

sub reply {

	my ( $this, %params ) = @_;

	# Prepare message with exchanged src_addr and dst_addr
	my $reply = $this->new(
		src_addr => $this->dst_addr,
		dst_addr => $this->src_addr,
		media    => $this->media,
		format   => $this->format,
		%params,
	);

	$reply->_make_id();

	return $reply;

}

#***********************************************************************

=back

=head1 INTERNAL METHODS

=over 

=item B<_make_id($system_name)> - generate message id

This method implements automatic generation of message id using
make_uuid() routine. System name is set to 'netsds.generic' if
not given in arguments.

=cut 

#-----------------------------------------------------------------------

sub _make_id {

	my ( $this, $system_name ) = @_;

	# Generate default system name
	if ( !$system_name ) {
		$system_name = 'netsds.generic';
	}

	return make_uuid() . '@' . $system_name;

}
1;

__END__

=back

=head1 EXAMPLES

See C<samples> directory for examples.

=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008 Michael Bochkaryov

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


