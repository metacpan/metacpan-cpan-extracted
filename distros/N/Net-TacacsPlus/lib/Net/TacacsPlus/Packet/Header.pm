package Net::TacacsPlus::Packet::Header;

=head1 NAME

Net::TacacsPlus::Packet::Header - Tacacs+ packet header

=head1 DESCRIPTION

3.  The TACACS+ packet header

All TACACS+ packets always begin with the following 12  byte  header.
The  header  is  always  cleartext and describes the remainder of the
packet:


	 1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8
	
	+----------------+----------------+----------------+----------------+
	|major  | minor  |                |                |                |
	|version| version|      type      |     seq_no     |   flags        |
	+----------------+----------------+----------------+----------------+
	|                                                                   |
	|                            session_id                             |
	+----------------+----------------+----------------+----------------+
	|                                                                   |
	|                              length                               |
	+----------------+----------------+----------------+----------------+

=cut

our $VERSION = '1.10';

use strict;
use warnings;

use 5.006;
use Net::TacacsPlus::Constants 1.03;
use Carp::Clan;

use base qw{ Class::Accessor::Fast };

__PACKAGE__->mk_accessors(qw{
	version
	type
	seq_no
	flags
	session_id
	length
});

=head1 METHODS

=over 4

=item new( somekey => somevalue)

Construct tacacs+ packet header object

1. if constructing from parameters:

	'version': protocol version
	'type': TAC_PLUS_(AUTHEN|AUTHOR|ACCT) 
	'seq_no': sequencenumber - default 1
	'flags': TAC_PLUS_(UNENCRYPTED_FLAG|SINGLE_CONNECT_FLAG) - default none
	'session_id': session id

2. if constructing from raw packet

	'raw_header': raw packet

=cut

sub new {
	my $class = shift;
	my %params = @_;
	
	#let the class accessor contruct the object
	my $self = $class->SUPER::new(\%params);	

	#build header from binary data
	if ($params{'raw_header'}) {
		$self->decode($params{'raw_header'});
		delete $self->{'raw_header'};	
		return $self;
	}

	#parameters check and default values
	carp("session_id must be set!") if not defined $self->session_id;
	carp("version must be set!")    if not defined $self->version;
	carp("type must be set!")       if not defined $self->type;
	$self->seq_no(1) if not defined $self->seq_no();
	$self->flags(0)  if not defined $self->flags();

	return $self;
}

=item decode($raw_data)

Decode $raw_data to version, type, seq_no, flags, session_id, length

=cut

sub decode {
	my ($self, $raw_data) = @_;
	
	( $self->{'version'}, #i dont't use object calls ->xyz() to improve speed a little bit and he it is not really neccesary
	$self->{'type'},
	$self->{'seq_no'},
	$self->{'flags'},
	$self->{'session_id'},
	$self->{'length'} ) = unpack("CCCCNN", $raw_data);
	
}

=item raw()

returns raw binary representation of header.

B<NOTE> For complete binary header, length of body must be
added.

=cut

sub raw {
	my $self = shift;

	return pack("CCCCN", #i dont't use object calls ->xyz() to improve speed a little bit and he it is not really neccesary
			$self->{'version'},
			$self->{'type'},
			$self->{'seq_no'},
			$self->{'flags'},
			$self->{'session_id'},
			);
}

=back

=cut

1;
