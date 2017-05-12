#===============================================================================
#
#       MODULE:  NetSDS::Kannel
#
#  DESCRIPTION:  This module provides API to Kannel message structure.
#
#        NOTES:  This is NetSDS specific API implementation.
#                It's expected that kannel configuration is standard for NetSDS.
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#
#===============================================================================

=head1 NAME

NetSDS::Kannel - Kannel SMS gateway API

=head1 SYNOPSIS

	#!/usr/bin/env perl
	
	use 5.8.0;
	use warnings;
	use strict;

	use NetSDS::Kannel;

	my $kannel = NetSDS::Kannel->new(
		sendsms_url    => 'http://localhost:1234/sendsms',
		sendsms_user   => 'sender',
		sendsms_passwd => 'secret',
		default_smsc   => 'esme-megafon',
	);

	$res = $kannel->send(
		from     => '1234',
		to       => '380672222111',
		text     => 'Hallo there!',
		smsc     => 'emse-mts',
		priority => 3,
	);

	1;

=head1 DESCRIPTION

C<NetSDS::Kannel> module provides API to Kannel SMS gateway.

To decrease innecessary problems we use a lot of predefined parameters
while sending and receiving messages via Kannel HTTP API. It's not so flexible
as direct HTTP processing but less expensive in development time ;-)

This modules uses LWP to send messages and CGI.pm to process messages from Kannel.

=cut

package NetSDS::Kannel;

use 5.8.0;
use strict;
use warnings;

use NetSDS::Util::Convert;
use NetSDS::Util::String;
use NetSDS::Util::Types;
use LWP::UserAgent;
use URI::Escape;
use XML::LibXML;

use base qw(
  NetSDS::Class::Abstract
  Exporter
);

use version; our $VERSION = "1.300";

use constant USER_AGENT => 'NetSDS Kannel API';

our @EXPORT = qw(
  STATE_DELIVERED
  STATE_UNDELIVERABLE
  STATE_ENROUTE
  STATE_ACCEPTED
  STATE_REJECTED
  ESME_RINVMSGLEN
  ESME_RINVCMDID
  ESME_RINVBNDSTS
  ESME_RSYSERR
  ESME_RINVDSTADR
  ESME_RMSGQFUL
  ESME_RTHROTTLED
  ESME_RUNKNOWNERR
  ESME_RTIMEOUT
  ESME_LICENSE
  ESME_CHARGING
);

# SMS delivery states
use constant STATE_DELIVERED     => 1;     # Delivered to MS
use constant STATE_UNDELIVERABLE => 2;     # Undeliverable
use constant STATE_ENROUTE       => 4;     # Queued on SMSC
use constant STATE_ACCEPTED      => 8;     # Received by SMSC
use constant STATE_REJECTED      => 16;    # Rejected by SMSC

# Reject codes from SMSC

use constant ESME_RINVMSGLEN  => 1;        # Wrong length
use constant ESME_RINVCMDID   => 3;        # Wrong SMPP command
use constant ESME_RINVBNDSTS  => 4;
use constant ESME_RSYSERR     => 8;
use constant ESME_RINVDSTADR  => 11;       # Invalid destination address
use constant ESME_RMSGQFUL    => 20;
use constant ESME_RTHROTTLED  => 88;
use constant ESME_RUNKNOWNERR => 255;
use constant ESME_RTIMEOUT    => 1057;
use constant ESME_LICENSE     => 1058;     # License restriction (vendor specific)
use constant ESME_CHARGING    => 1059;     # Low billing balance (vendor specific)
use constant ESME_CHARGING_PP => 1111;     # Low billing balance on prepaid (vendor specific)

#===============================================================================

=head1 CLASS API

=over

=item B<new(%params)> - class constructor

Constructor creates Kannel API handler and set it's configuration.
Most of these parameters may be overriden while object method calls.

B<Admin API parameters:>

* admin_url - Kannel admin API URL

* admin_passwd - password to admin API

B<Sending SMS API parameters:>

* sendsms_url - URL of Kannel sendsms HTTP API

* sendsms_user - user name for sending SMS

* sendsms_passwd - password for sending SMS

* dlr_url - base URL for DLR retrieving

* default_smsc - default SMSC identifier for sending SMS

* default_timeout - default sending TCP timeout

=back

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(
		admin_url       => 'http://127.0.0.1:13000/',
		admin_passwd    => '',
		sendsms_url     => 'http://127.0.0.1:13013/cgi-bin/sendsms',
		sendsms_user    => 'netsds',
		sendsms_passwd  => '',
		dlr_url         => 'http://127.0.0.1/smsc/kannel_receiver.fcgi',
		default_smsc    => undef,
		default_timeout => 30,                                             # 30 seconds enough for sending timeout
		%params,
	);

	# Initialize LWP user agent
	$self->{_ua} = LWP::UserAgent->new();
	$self->{_ua}->agent( USER_AGENT . "/$VERSION" );

	# Initialize XML parser
	$self->{_xml} = XML::LibXML->new();
	$self->{_xml}->validation(0);
	$self->{_xml}->recover(1);

	return $self;

} ## end sub new

__PACKAGE__->mk_accessors('admin_url');
__PACKAGE__->mk_accessors('admin_passwd');
__PACKAGE__->mk_accessors('sendsms_url');
__PACKAGE__->mk_accessors('sendsms_user');
__PACKAGE__->mk_accessors('sendsms_passwd');
__PACKAGE__->mk_accessors('dlr_url');
__PACKAGE__->mk_accessors('default_smsc');
__PACKAGE__->mk_accessors('default_timeout');

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<send(%parameters)> - send MT SM message to Kannel

This method allows to send SMS message via Kannel SMS gateway.

Parameters (mostly the same as in Kannel sendsms API):

* from - source address (overrides message)

* to - destination address (overrides message)

* text - message text (byte string)

* udh - user data header (byte string)

* charset - charset of text

* coding - 0 for GSM 03.38, 1 for binary, 2 for UCS2

* smsc - target SMSC (overrides default one)

* mclass - message class if necessary (0 for flash sms)

* validity - TTL for MO SM in minutes

* deferred - timeout for delayed delivery

Example:

	$kannel->send_sms(
		from => '1234',
		to => '380672206770',
		text => 'Wake up!!!',
		smsc => 'nokia_modem',
	);

=cut

#-----------------------------------------------------------------------

sub send {

	my ( $self, %params ) = @_;

	my %send = (
		'username' => $self->sendsms_user,
		'password' => $self->sendsms_passwd,
		'charset'  => 'UTF-8',                 # Local text representation
		'coding'   => 0,                       # 7 bit GSM 03.38
	);

	# Then we override message parameters

	# Set sendsms URL
	my $send_url = $self->sendsms_url;
	if ( $params{sendsms_url} ) {
		$send_url = $params{sendsms_url};
	}

	# Set sendsms username
	if ( $params{sendsms_user} ) {
		$send{username} = $params{sendsms_user};
	}

	# Set sendsms password
	if ( $params{sendsms_passwd} ) {
		$send{password} = $params{sendsms_passwd};
	}

	# Set source address
	if ( $params{from} ) {
		$send{from} = uri_escape( $params{from} );
	}

	# Set destination address
	if ( $params{to} ) {
		$send{to} = uri_escape( $params{to} );
	}

	# Set message text
	if ( $params{text} ) {
		$send{text} = uri_escape( $params{text} );
	}

	# Set message UDH
	if ( $params{udh} ) {
		$send{udh} = uri_escape( $params{udh} );
	}

	# Set message charset
	if ( $params{charset} ) {
		$send{charset} = $params{charset};
	}

	# Set message mclass
	if ( defined $params{mclass} ) {
		$send{mclass} = $params{mclass};
	}

	# Set data coding
	if ( $params{coding} ) {
		$send{coding} = $params{coding};
	}

	# Set message TTL in minutes
	if ( $params{validity} and ( is_int( $params{validity} ) ) ) {
		$send{validity} = $params{validity};
	}

	# Set deferred delivery in minutes
	if ( $params{deferred} and ( is_int( $params{deferred} ) ) ) {
		$send{deferred} = $params{deferred};
	}

	# Set message priority (0 to 3)
	if ( defined $params{priority} and ( is_int( $params{priority} ) and ( $params{priority} <= 3 ) and ( $params{priority} >= 0 ) ) ) {
		$send{priority} = $params{priority};
	}

	# Set SMSC id
	if ( $params{smsc} ) {
		$send{smsc} = $params{smsc};
	}

	# Set DLR fetching mask (see kannel documentation)
	if ( $params{dlr_id} ) {
		$send{'dlr-url'} = $self->make_dlr_url( msgid => $params{dlr_id} );

		# Set DLR fetching mask (see kannel documentation)
		if ( $params{dlr_mask} ) {
			$send{'dlr-mask'} = $params{dlr_mask};
		} else {
			$send{'dlr-mask'} = 3;    # default mask (delivered and undeliverable)
		}
	}

	# Set meta data
	if ( $params{meta} ) {
		$send{'meta-data'} = $self->make_meta( %{ $params{meta} } );
	}

	# Set HTTP request timeout
	my $timeout = $self->default_timeout;
	if ( $params{timeout} ) {
		$timeout = $params{timeout};
	}
	$self->{_ua}->timeout($timeout);

	# Prepare HTTP request
	my @pairs = map $_ . '=' . $send{$_}, keys %send;
	my $req = HTTP::Request->new( GET => $send_url . "?" . join '&', @pairs );

	# Send request
	my $res = $self->{_ua}->request($req);

	# Analyze response
	if ( $res->is_success ) {
		return $res->content;
	} else {
		return $self->error( $res->status_line );
	}

} ## end sub send

#***********************************************************************

=item B<receive($cgi)> - receive MO or DLR from CGI object

This method provides import message structure from CGI request .
This method is just wrapper around C<receive_mo()> and C<receive_dlr()> methods.

Message type (MO or DLR) recognized by C<type> CGI parameter that may be C<mo> or C<dlr>.

	my $cgi = CGI::Fast->new();
	my %ret = $kannel->receive($cgi);


=cut

#-----------------------------------------------------------------------

sub receive {

	my ( $self, $cgi ) = @_;

	my %ret = ();

	# Set message type (MO or DLR)
	if ( $cgi->param('type') ) {
		if ( $cgi->param('type') eq 'mo' ) {
			%ret = $self->receive_mo($cgi);
		} elsif ( $cgi->param('type') eq 'dlr' ) {
			%ret = $self->receive_dlr($cgi);
		}

		return %ret;

	} else {
		return $self->error("Unknown message type received");
	}

} ## end sub receive

#***********************************************************************

=item B<receive_mo($cgi)> - import MO message from CGI object

This method provides import message structure from CGI request .

Imported MO message parameters returned as hash with the following keys:

* smsc - Kannel's SMSC Id

* smsid - SMSC message ID

* from - subscriber's MSISDN

* to - service address (short code)

* time - SMS receive time

* unixtime SMS receive time as UNIX timestamp

* text - MO SM text

* bin - MO SM as binary string

* udh - SMS UDH (User Data Headers)

* coding - SMS encoding (0 - 7 bit GSM 03.38; 2 - UCS2-BE)

* charset - charset of MO SM text while receiving from Kannel

* binfo - SMPP C<service_type> parameter for billing puroses

=cut

#-----------------------------------------------------------------------

sub receive_mo {

	my ( $self, $cgi ) = @_;

	my %ret = (
		type => 'mo',
	);

	# Set SMSC Id (smsc=%i)
	if ( $cgi->param('smsc') ) {
		$ret{smsc} = $cgi->param('smsc');
	} else {
		$ret{smsc} = undef;
	}

	# Set SMSC message Id (smsid=%I)
	if ( $cgi->param('smsid') ) {
		$ret{smsid} = $cgi->param('smsid');
	} else {
		$ret{smsid} = undef;
	}

	# Set source (subscriber) address (from=%p)
	if ( $cgi->param('from') ) {
		$ret{from} = $cgi->param('from');
	}

	# Set destination (service) address (to=%P)
	if ( $cgi->param('to') ) {
		$ret{to} = $cgi->param('to');
	}

	# Set timestamp information (time=%t)
	if ( $cgi->param('time') ) {
		$ret{time} = $cgi->param('time');
	}

	# Set UNIX timestamp information (unixtime=%T)
	if ( $cgi->param('unixtime') ) {
		$ret{unixtime} = $cgi->param('unixtime');
	}

	# Set message text (text=%a)
	if ( $cgi->param('text') ) {
		$ret{text} = $cgi->param('text');
	}

	# Set binary message (bin=%b)
	if ( $cgi->param('bin') ) {
		$ret{bin} = $cgi->param('bin');
	}

	# Set UDH (udh=%u)
	if ( $cgi->param('udh') ) {
		$ret{udh} = $cgi->param('udh');
	}

	# Set coding (coding=%c)
	if ( defined $cgi->param('coding') ) {
		$ret{coding} = $cgi->param('coding') + 0;
	}

	# Set charset (charset=%C)
	if ( $cgi->param('charset') ) {
		$ret{charset} = $cgi->param('charset');
	}

	# Set message class (mclass=%m)
	if ( $cgi->param('mclass') ) {
		$ret{mclass} = $cgi->param('mclass');
	}

	# Set billing information (binfo=%B)
	if ( $cgi->param('binfo') ) {
		$ret{binfo} = $cgi->param('binfo');
	}

	# Convert message text to UTF-8
	if ( 1 != $ret{coding} ) {
		# It's text message
		$ret{text} = str_recode( $ret{text}, $ret{charset} );
		$ret{text} = str_encode( $ret{text} );
	}

	# Process optional SMPP TLV (meta=%D)
	if ( $cgi->param('meta') ) {
		my $meta_str = $cgi->param('meta');
		$ret{meta} = {};
		if ( $meta_str =~ /^\?smpp\?(.*)$/ ) {
			foreach my $tlv_par ( split /\&/, $1 ) {
				my ( $tag, $val ) = split /\=/, $tlv_par;
				$ret{meta}->{$tag} = $val;
			}
		}
	}

	return %ret;

} ## end sub receive_mo

#***********************************************************************

=item B<receive_dlr($cgi)> - import message from CGI object

This method provides import message structure from CGI request .

C<receive_dlr> method returns hash with the following keys:

* smsc - kannel SMSC id

* msgid - original MT SM message id for DLR identification

* smsid - SMSC message ID

* from - subscriber's MSISDN (phone number)

* to - service address (short code)

* time - delivery time

* unixtime - delivery time as UNIX timestamp

* dlr - DLR state

* dlrmsg - DLR message from SMSC

Example:

	my $cgi = CGI->new();

	my %dlr = $kannel->receive_dlr($cgi);

	print "DLR received for MSISDN: " . $dlr{from};

=cut

#-----------------------------------------------------------------------

sub receive_dlr {

	my ( $self, $cgi ) = @_;

	my %ret = (
		type => 'dlr',
	);

	# Set SMSC Id (smsc=%i)
	if ( $cgi->param('smsc') ) {
		$ret{smsc} = $cgi->param('smsc');
	} else {
		$ret{smsc} = undef;
	}

	# Set VASP message Id (msgid=our_id)
	if ( $cgi->param('msgid') ) {
		$ret{msgid} = $cgi->param('msgid');
	} else {
		$ret{msgid} = undef;
	}

	# Set SMSC message Id (smsid=%I)
	if ( $cgi->param('smsid') ) {
		$ret{smsid} = $cgi->param('smsid');
	} else {
		$ret{smsid} = undef;
	}

	# Set source (subscriber) address (from=%p)
	if ( $cgi->param('from') ) {
		$ret{from} = $cgi->param('from');
	}

	# Set destination (service) address (to=%P)
	if ( $cgi->param('to') ) {
		$ret{to} = $cgi->param('to');
	}

	# Set timestamp information (time=%t)
	if ( $cgi->param('time') ) {
		$ret{time} = $cgi->param('time');
	}

	# Set UNIX timestamp information (unixtime=%T)
	if ( $cgi->param('unixtime') ) {
		$ret{unixtime} = $cgi->param('unixtime');
	}

	# Set DLR state (dlr=%d)
	$ret{dlr_state} = $cgi->param('dlr');

	# Set DLR message (dlrmsg=%A)
	$ret{dlr_msg} = $cgi->param('dlrmsg');

	# Process return code if not success
	if ( $ret{dlr_msg} =~ /^NACK\/(\d+)\// ) {
		$self->{reject_code} = $1;
	}

	return %ret;

} ## end sub receive_dlr

#***********************************************************************

=item B<make_dlr_url(%params)> - prepare DLR URL

This method creates URI escaped string with URL template for DLR notification.

Paramters: hash (dlr_url, msgid)

Returns: URI escaped DLR URL

=cut 

#-----------------------------------------------------------------------

sub make_dlr_url {

	my ( $self, %params ) = @_;

	# Set reference to MT message Id for identification
	my $msgid = $params{msgid};

	# Set DLR base URL from object property or method parameter
	my $dlr_url = $self->{dlr_url};
	if ( $params{dlr_url} ) { $dlr_url = $params{dlr_url}; }

	$dlr_url .= "?type=dlr&msgid=$msgid&smsid=%I&from=%p&to=%P&time=%t&unixtime=%T&dlr=%d&dlrmsg=%A";

	return conv_str_uri($dlr_url);

}

#***********************************************************************

=item B<make_meta(%params)> - prepare SMPP optional TLV

This method creates URI escaped string with optional SMPP tag-lenght-value (TLV)
parameters to send them in C<meta-data> CGI paramter of Kannel's C<sendsms> HTTP API.

Format of C<meta-data> parameter value:

	?smpp?tag1=value1&tag2=value2&...tagN=valueN

Paramters: hash of TLV pairs

Returns: URI escaped string

Example:

	my $meta = $self->make_meta(
		charging_id => '0',
	);

This will return: %3Fsmpp%3Fcharging_id%3D0

=cut 

#-----------------------------------------------------------------------

sub make_meta {

	my ( $self, %params ) = @_;

	my $meta_str = '?smpp?';    # FIXME: only 'smpp' group allowed

	my @pairs = map $_ . '=' . $params{$_}, keys %params;
	$meta_str .= join '&', @pairs;

	return conv_str_uri($meta_str);

}

#***********************************************************************

=item B<status()> - retrieve Kannel status

=cut

#-----------------------------------------------------------------------

sub status {

	my ($self) = @_;

	my $res = $self->{_ua}->get( $self->admin_url . "status.xml" );
	if ( $res->is_success ) {

		# Parse XML and retrieve DOM structure
		#
		# NOTE: we use eval{} because of XML::LibXML calls die() on parser errors
		my $doc = undef;
		eval { $doc = $self->{_xml}->parse_string( $res->content )->documentElement(); };

		# Catch exceptions
		if ($@) {
			return $self->error("Can't parse XML from Kannel API");
		}

		# ==========================
		# Preparing result structure

		# Version string
		my $result = {
			version => $doc->findvalue('/gateway/version'),
		};

		# Total Kannel status and uptime
		#
		# Sample XML part from status.xml API
		# <status>suspended, uptime 32d 7h 26m 43s</status>
		if ( $doc->findvalue('/gateway/status') =~ /^(\S+),\s+uptime\s+(.+)$/ ) {
			$result->{status} = $1;
			$result->{uptime} = $2;
		}

		# Common SMS information
		$result->{sms} = {
			received_total  => $doc->findvalue('/gateway/sms/received/total'),
			received_queued => $doc->findvalue('/gateway/sms/received/queued'),
			sent_total      => $doc->findvalue('/gateway/sms/sent/total'),
			sent_queued     => $doc->findvalue('/gateway/sms/sent/queued'),
			storesize       => $doc->findvalue('/gateway/sms/storesize'),
			inbound         => $doc->findvalue('/gateway/sms/inbound'),
			outbound        => $doc->findvalue('/gateway/sms/outbound'),
		};

		# Common DLR information
		$result->{dlr} = {
			queued  => $doc->findvalue('/gateway/dlr/queued'),
			storage => $doc->findvalue('/gateway/dlr/storage'),
		};

		# SMSC connections information
		$result->{'smsc'} = [];

		foreach ( $doc->findnodes('/gateway/smscs/smsc') ) {
			my $smsc = {
				name     => $_->findvalue('name'),
				id       => $_->findvalue('id'),
				status   => $_->findvalue('status'),
				received => $_->findvalue('received'),
				sent     => $_->findvalue('sent'),
				failed   => $_->findvalue('failed'),
				queued   => $_->findvalue('queued'),
			};
			if ( $smsc->{status} =~ /online\s+(.+)/ ) {
				$smsc->{status} = 'online';
				$smsc->{uptime} = $1;
			}

			push @{ $result->{'smsc'} }, $smsc;
		}

		return $result;

	} ## end if ( $res->is_success )

	else {
		return $self->error( "Can't retrieve Kannel status: " . $res->status_line );
	}

} ## end sub status

#***********************************************************************

=item B<store_status()> - retrieve message queue status

Not implemented yet.

=cut

#-----------------------------------------------------------------------

sub store_status {

	my ($self) = @_;

}

#***********************************************************************

=item B<shutdown()> - bring down Kannel

=cut

#-----------------------------------------------------------------------

sub shutdown {

	my ($self) = @_;

	return $self->_send_cmd('shutdown');

}

#***********************************************************************

=item B<suspend()> - switch Kannel to 'suspended' state

=cut

#-----------------------------------------------------------------------

sub suspend {

	my ($self) = @_;

	return $self->_send_cmd('suspend');

}

#***********************************************************************

=item B<isolate()> - switch Kannel to 'isolated' state

=cut

#-----------------------------------------------------------------------

sub isolate {

	my ($self) = @_;

	return $self->_send_cmd('isolate');

}

#***********************************************************************

=item B<resume()> - resume Kannel to 'online' state

=cut

#-----------------------------------------------------------------------

sub resume {

	my ($self) = @_;

	return $self->_send_cmd('resume');

}

#***********************************************************************

=item B<restart()> - whole bearerbox restart

=cut

#-----------------------------------------------------------------------

sub restart {

	my ($self) = @_;

	return $self->_send_cmd('restart');

}

#***********************************************************************

=item B<flush_dlr()> - flush queued DLR if Kannel in 'suspended' state

=cut

#-----------------------------------------------------------------------

sub flush_dlr {

	my ($self) = @_;

	return $self->_send_cmd('flush-dlr');

}

#***********************************************************************

=item B<reload_lists()> - reload black/white lists

=cut

#-----------------------------------------------------------------------

sub reload_lists {

	my ($self) = @_;

	return $self->_send_cmd('reload-lists');

}

#***********************************************************************

=item B<log_level($level)> - change Kannel log-level

=cut

#-----------------------------------------------------------------------

sub log_level {

	my ( $self, $level ) = @_;

	return $self->_send_cmd( 'log-level', level => $level );

}

#***********************************************************************

=item B<start_smsc($smsc)> - switch on SMSC connection

=cut

#-----------------------------------------------------------------------

sub start_smsc {

	my ( $self, $smsc ) = @_;

	return $self->_send_cmd( 'start-smsc', smsc => $smsc );

}

#***********************************************************************

=item B<stop_smsc($smsc)> - switch off SMSC connection

=cut

#-----------------------------------------------------------------------

sub stop_smsc {

	my ( $self, $smsc ) = @_;

	return $self->_send_cmd( 'stop-smsc', smsc => $smsc );

}

#***********************************************************************

=item B<add_smsc($smsc)> - add new SMSC connection

=cut

#-----------------------------------------------------------------------

sub add_smsc {

	my ( $self, $smsc ) = @_;

	return $self->_send_cmd( 'add-smsc', smsc => $smsc );

}

#***********************************************************************

=item B<remove_smsc($smsc)> - remove SMSC connection

=cut

#-----------------------------------------------------------------------

sub remove_smsc {

	my ( $self, $smsc ) = @_;

	return $self->_send_cmd( 'remove-smsc', smsc => $smsc );

}

sub _send_cmd {

	my ( $self, $cmd, %params ) = @_;

	# Prepare base URL with administrative URL and password
	my $url = $self->admin_url . "$cmd?password=" . $self->admin_passwd;

	# Add optional parameters
	foreach ( keys %params ) {
		$url .= "&" . $_ . "=" . $params{$_};
	}

	# Prepare and send HTTP request to Kannel admin API
	my $req = HTTP::Request->new( GET => $url );
	my $res = $self->{_ua}->request($req);

	# Analyze HTTP response
	if ( $res->is_success ) {
		# OK - send result data "as is"
		return $res->content;
	} else {
		# Error - send error string
		return $self->error( $res->status_line );
	}

} ## end sub _send_cmd

1;

__END__

=back

=head1 EXAMPLES

See Nibelite kannel API

=head1 SEE ALSO

=over
 
=item * L<NetSDS::Class::Abstract> - base NetSDS class

=item * L<http://www.kannel.org/download/1.4.3/userguide-1.4.3/userguide.html> - Kannel User Guide

=back

=head1 TODO

1. Add PPG support.

2. Add OTA support.

=head1 AUTHOR

Michael Bochkaryov <misha@rattler.kiev.ua>

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

