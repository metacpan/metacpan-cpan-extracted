package Net::TacacsPlus::Packet;

=head1 NAME

Net::TacacsPlus::Packet - Tacacs+ packet object

=head1 SYNOPSIS
	
	# construct authentication START packet
	
	$pkt = Net::TacacsPlus::Packet->new(
		#header
		'type' => TAC_PLUS_AUTHEN,
		'seq_no' => 1,
		'flags' => 0,
		'session_id' => $session_id,
		#start
		'action' => TAC_PLUS_AUTHEN_LOGIN,
		'authen_type' => TAC_PLUS_AUTHEN_TYPE_(ASCII|PAP),
		'key' => $secret,
		);
	
	
	# construct authentication CONTINUE packet
	
	$pkt = Net::TacacsPlus::Packet->new(
		#header
		'type' => TAC_PLUS_AUTHEN,
		'seq_no' => 3,
		'session_id' => $session_id,
		#continue
		'user_msg' => $username,
		'data' => '',
		'key' => $secret,
		);
	
	# construct authentication REPLY packet from received raw packet
	
	$reply = Net::TacacsPlus::Packet->new(
			'type' => TAC_PLUS_AUTHEN,
			'raw' => $raw_reply,
			'key' => $secret,
			);

	# construct authorization REQUEST packet

	$pkt = Net::TacacsPlus::Packet->new(
		#header
		'type' => TAC_PLUS_AUTHOR,
		'seq_no' => 1,
		'session_id' => $session_id,
		#request
		'user' => $username,
		'args' => $args, # arrayref
		'key' => $secret,
		);

	# construct authorization RESPONSE packet from received raw packet

	$response = Net::TacacsPlus::Packet->new(
			'type' => TAC_PLUS_AUTHOR,
			'raw' => $raw_reply,
			'key' => $secret,
			);

	# construct accounting REQUEST packet

	$pkt = Net::TacacsPlus::Packet->new(
		#header
		'type' => TAC_PLUS_ACCT,
		'seq_no' => 1,
		'session_id' => $session_id,
		#request
		'acct_flags' => TAC_PLUS_ACCT_FLAG_*,
		'user' => $username,
		'args' => $args, # arrayref
		'key' => $secret,
		);

	# construct accounting REPLY packet from received raw packet

	$reply = Net::TacacsPlus::Packet->new(
			'type' => TAC_PLUS_ACCT,
			'raw' => $raw_reply,
			'key' => $secret,
			);

=head1 DESCRIPTION

Library to create and manipulate Tacacs+ packets. Object can be build
from parameters or from raw received packet.

=head1 AUTHOR

Jozef Kutej E<lt>jkutej@cpan.orgE<gt>

Authorization and Accounting contributed by Rubio Vaughan E<lt>rubio@passim.netE<gt>

=head1 VERSION

1.06

=head1 SEE ALSO

tac-rfc.1.78.txt, Net::TacacsPlus::Client

=cut


our $VERSION = '1.10';

use strict;
use warnings;

use 5.006;

use Net::TacacsPlus::Constants 1.03;
use Net::TacacsPlus::Packet::Header;
use Net::TacacsPlus::Packet::AccountReplyBody;
use Net::TacacsPlus::Packet::AccountRequestBody;
use Net::TacacsPlus::Packet::AuthenContinueBody;
use Net::TacacsPlus::Packet::AuthenReplyBody;
use Net::TacacsPlus::Packet::AuthenStartBody;
use Net::TacacsPlus::Packet::AuthorRequestBody;
use Net::TacacsPlus::Packet::AuthorResponseBody;

use Carp::Clan;
use Digest::MD5 ('md5');

use base qw{ Class::Accessor::Fast };

__PACKAGE__->mk_accessors(qw{
	header
	body
	key
	action	
});

=head1 METHODS

=over 4

=item new( somekey => somevalue )

1. if constructing from parameters need this parameters:

for header:

	'type'      : TAC_PLUS_(AUTHEN|AUTHOR|ACCT) 
	'seq_no'    : sequencenumber
	'flags'     : TAC_PLUS_(UNENCRYPTED_FLAG|SINGLE_CONNECT_FLAG)
	'session_id': session id

for authentication START body:

	'action'     : TAC_PLUS_AUTHEN_(LOGIN|CHPASS|SENDPASS|SENDAUTH)
	'authen_type': TAC_PLUS_AUTHEN_TYPE_(ASCII|PAP)
	'key'        : encryption key

for authentication CONTINUE body:	
	'user_msg': msg required by server
	'data'    : data required by server
	'key'     : encryption key

for authorization REQUEST body:
	'user': username
	'args': authorization arguments
	'key' : encryption key

for accounting REQUEST body:
	'acct_flags': TAC_PLUS_ACCT_FLAG_(MORE|START|STOP|WATCHDOG)
	'user'      : username
	'args'      : authorization arguments
	'key'       : encryption key

2. if constructing from received raw packet

for AUTHEN reply, AUTHOR response and ACCT reply:

	'type': TAC_PLUS_(AUTHEN|AUTHOR|ACCT)
	'raw' : raw packet
	'key' : encryption key

=cut

sub new {
	my $class = shift;
	my %params = @_;

	#let the class accessor contruct the object
	my $self = $class->SUPER::new(\%params);

	#create object from raw packet
	if ($params{'raw'}) {
		$self->decode_raw($params{'raw'});
		delete $self->{'raw'};
		return $self;	
	}

	#compute version byte if needed
	if (not exists $params{'version'}) {
		$params{'major_version'} = $params{'major_version'} ? $params{'major_version'} : TAC_PLUS_MAJOR_VER;
		$params{'minor_version'} = $params{'minor_version'} ? $params{'minor_version'} : TAC_PLUS_MINOR_VER_DEFAULT;
		$params{'version'}       = $params{'major_version'}*0x10+$params{'minor_version'};
	}
	
	#construct the packet header
	$self->header(Net::TacacsPlus::Packet::Header->new(%params));

	my $type = $self->type;
	croak "TacacsPlus packet type is required parameter."
		if (not defined $type);
	

	if ($type == TAC_PLUS_AUTHEN)
	{
		if ($params{'action'})				#if action is set it is the first START packet
		{
			$self->body(Net::TacacsPlus::Packet::AuthenStartBody->new(%params));
		} elsif ($params{'user_msg'})		#else it is CONTINUE
		{
			$self->body(Net::TacacsPlus::Packet::AuthenContinueBody->new(%params));
		} elsif ($params{'status'})		    #else it is REPLY
		{
			$self->body(Net::TacacsPlus::Packet::AuthenReplyBody->new(%params));
		} else { die("unknown request for body creation"); }
	} elsif ($type == TAC_PLUS_AUTHOR)
	{
		$self->body(Net::TacacsPlus::Packet::AuthorRequestBody->new(%params));
	} elsif ($type == TAC_PLUS_ACCT)
	{
		$self->body(Net::TacacsPlus::Packet::AccountRequestBody->new(%params));
	} else
	{
		croak('TacacsPlus packet type '.$self->type.' unsupported.');
	}

	return $self;
}

=item check_reply($snd, $rcv)

compare send and reply packet for errors

$snd - packet object that was send
$rcv - packet object that was received afterwards	

checks sequence number, session id, version and flags

=cut

sub check_reply {
	my ($self, $snd, $rcv) = @_;
	
	if (($snd->seq_no() + 1) != ($rcv->seq_no())) { croak("seq_no mismash"); }
	if (($snd->session_id()) != ($rcv->session_id())) { croak("session_id mismash"); }
	if (($snd->version()) != ($rcv->version())) { croak("version mismash"); }	
	if (($snd->flags()) != ($rcv->flags())) { croak("flags mismash"); }	
}

=item decode_raw($raw_pkt)

From raw packet received create reply object:
Net::TacacsPlus::Packet::AuthenReplyBody or
Net::TacacsPlus::Packet::AuthorResponseBody or
Net::TacacsPlus::Packet::AccountReplyBody

=cut

sub decode_raw {
	my ($self, $raw_pkt) = @_;
	
	my ($raw_header,$raw_body) = unpack("a".TAC_PLUS_HEADER_SIZE."a*",$raw_pkt);
	
	$self->header(Net::TacacsPlus::Packet::Header->new('raw_header' => $raw_header));

	$raw_body = $self->raw_xor_body($raw_body);
	
	# even sequence numbers are received by the client
	if ($self->seq_no % 2 == 0) {
		if ($self->type == TAC_PLUS_AUTHEN)
		{
			$self->body(Net::TacacsPlus::Packet::AuthenReplyBody->new('raw_body' => $raw_body));	
		} elsif ($self->type == TAC_PLUS_AUTHOR)
		{
			$self->body(Net::TacacsPlus::Packet::AuthorResponseBody->new('raw_body' => $raw_body));
		} elsif ($self->type == TAC_PLUS_ACCT)
		{
			$self->body(Net::TacacsPlus::Packet::AccountReplyBody->new('raw_body' => $raw_body));
		} else
		{
			die('TacacsPlus packet type '.$self->type.' unsupported.');
		}
	}
	# odd sequence numbers are received by the server
	else {
		if ($self->type == TAC_PLUS_AUTHEN)
		{
			$self->body(Net::TacacsPlus::Packet::AuthenStartBody->new('raw_body' => $raw_body));	
		} elsif ($self->type == TAC_PLUS_AUTHOR)
		{
			$self->body(Net::TacacsPlus::Packet::AuthorRequestBody->new('raw_body' => $raw_body));
		} elsif ($self->type == TAC_PLUS_ACCT)
		{
			$self->body(Net::TacacsPlus::Packet::AccountRequestBody->new('raw_body' => $raw_body));
		} else
		{
			die('TacacsPlus packet type '.$self->type.' unsupported.');
		}
	}
}

=item raw( )

return binary representation of whole packet.

=cut

sub raw {
	my $self = shift;
	my $key = shift;
	
	my $header=$self->header->raw();
	my $body=$self->raw_xor_body($self->body->raw());
	$header=$header.pack("N",length($body));

	return $header.$body;
}

=item raw_xor_body($data)

XOR $data by pseudo pas.

=cut

sub raw_xor_body {
	my ($self,$data) = @_;

	return $data if not $self->key;

	my $pseudo_pad=compute_pseudo_pad(
					$self->session_id(),
					$self->key,
					$self->version(),
					$self->seq_no(),
					length($data),
					);
	
	$data=$data ^ $pseudo_pad;

	return $data;
}

=item compute_pseudo_pad( $sess_id,$key,$version,$seq_no,$length )

compute md5 hash from parameters truncated to $length

	pseudo_pad = {MD5_1 [,MD5_2 [ ... ,MD5_n]]} truncated to len(data)

The first MD5 hash is generated by concatenating the session_id, the
secret key, the version number and the sequence number and then running
MD5 over that stream. All of those input values are available in the
packet header, except for the secret key which is a shared secret
between the TACACS+ client and daemon.

=cut

sub compute_pseudo_pad {
	my ( $sess_id,$key,$version,$seq_no,$length ) = @_;

	my ( $data,$md5hash, $hash, $md5len );

	$data = pack("Na*CC",$sess_id,$key,$version,$seq_no);
	
	$md5len = 0;
	$hash = '';
	$md5hash = '';

	while ( $md5len < $length ) {
		$md5hash = md5($data.$md5hash);
		$hash .= $md5hash;
		$md5len+=16;
	}

	return substr ( $hash, 0, $length );

}

=item server_msg( )

returns last server msg

=cut

sub server_msg() {
	my $self = shift;
	
	return $self->body->server_msg(@_);
}

=item seq_no()

Return packet sequence number.

=cut

sub seq_no() {
	my $self = shift;
	
	return $self->header->seq_no(@_);
}

=item session_id()

Return packet session id.

=cut

sub session_id() {
	my $self = shift;
	
	return $self->header->session_id(@_);
}

=item version()

Return version from packet header

=cut

sub version() {
	my $self = shift;
	
	return $self->header->version(@_);
}

=item flags()

Return flags from packet header.

=cut

sub flags() {
	my $self = shift;
	
	return $self->header->flags(@_);
}

=item args()

Return arguments returned by server in authorization response packet.

=cut

sub args() {
	my $self = shift;
	
	if($self->type == TAC_PLUS_AUTHOR)
	{
		return $self->body->args(@_);
	} else
	{
		die("Arguments only available for authorization response packets")
	}
}

=item status( )

returns status of packet. it is used in REPLY packets received from
server.

status is one of:

	TAC_PLUS_AUTHEN_STATUS_PASS        => 0x01,
	TAC_PLUS_AUTHEN_STATUS_FAIL        => 0x02,
	TAC_PLUS_AUTHEN_STATUS_GETDATA     => 0x03,
	TAC_PLUS_AUTHEN_STATUS_GETUSER     => 0x04,
	TAC_PLUS_AUTHEN_STATUS_GETPASS     => 0x05,
	TAC_PLUS_AUTHEN_STATUS_RESTART     => 0x06,
	TAC_PLUS_AUTHEN_STATUS_ERROR       => 0x07,
	TAC_PLUS_AUTHEN_STATUS_FOLLOW      => 0x21,
	TAC_PLUS_AUTHOR_STATUS_PASS_ADD    => 0x01,
	TAC_PLUS_AUTHOR_STATUS_PASS_REPL   => 0x02,
	TAC_PLUS_AUTHOR_STATUS_FAIL        => 0x10,
	TAC_PLUS_AUTHOR_STATUS_ERROR       => 0x11,
	TAC_PLUS_AUTHOR_STATUS_FOLLOW      => 0x21,
	TAC_PLUS_ACCT_STATUS_SUCCESS       => 0x01,
	TAC_PLUS_ACCT_STATUS_ERROR         => 0x02,
	TAC_PLUS_ACCT_STATUS_FOLLOW        => 0x21,

=cut

sub status() {
	my $self = shift;
	
	return $self->body->status(@_);
}

=item send()

Send out packet.

=cut

sub send() {
	my ($self, $remote) = @_;

	my $raw_pkt = $self->raw();
	
	my $bytes = $remote->send($raw_pkt);
	croak("error sending packet!") if ($bytes != length($raw_pkt));
	
	return $bytes;
}

=item type()

Returns packet type taken from packet header eg. $self->header->type;

=cut

sub type {
	my $self = shift;
	
	return $self->header->type(@_);
}

1;

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jozef Kutej

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
