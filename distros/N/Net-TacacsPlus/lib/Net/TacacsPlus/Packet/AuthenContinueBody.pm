package Net::TacacsPlus::Packet::AuthenContinueBody;

=head1 NAME

Net::TacacsPlus::Packet::AuthenContinueBody - Tacacs+ authentication continue body

=head1 DESCRIPTION

	8.  The authentication CONTINUE packet body
	
	This packet is sent from the NAS to the daemon following the  receipt
	of a REPLY packet.
	
	
	      1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8
	
	     +----------------+----------------+----------------+----------------+
	     |          user_msg len           |            data len             |
	     +----------------+----------------+----------------+----------------+
	     |     flags      |  user_msg ...
	     +----------------+----------------+----------------+----------------+
	     |    data ...
	     +----------------+

=cut


our $VERSION = '1.10';

use strict;
use warnings;

use 5.006;
use Net::TacacsPlus::Constants 1.03;
use Carp::Clan;

use base qw{ Class::Accessor::Fast };

__PACKAGE__->mk_accessors(qw{
	continue_flags
	user_msg
	data
});

=head1 METHODS

=over 4

=item new( somekey => somevalue)

Construct tacacs+ authentication CONTINUE packet body object

Parameters:

	'continue_flags' : TAC_PLUS_CONTINUE_FLAG_ABORT - default none
	'user_msg'       : user message requested by server
	'data'           : data requested by server

=cut

sub new() {
	my $class = shift;
	my %params = @_;

	#let the class accessor contruct the object
	my $self = $class->SUPER::new(\%params);

	if ($params{'raw_body'}) {
		$self->decode($params{'raw_body'});
		delete $self->{'raw_body'};
		return $self;
	}

	$self->continue_flags(0) if not defined $self->continue_flags;

	return $self;
}


=item decode($raw_body)

Construct body object from raw data.

=cut

sub decode {
	my ($self, $raw_body) = @_;

	my $user_msg_length;
	my $data_length;
	my $payload;
	
	(
		$user_msg_length,
		$data_length,
		$self->{'continue_flags'},
		$payload,
	) = unpack('nnCa*', $raw_body);

	(
		$self->{'user_msg'},
		$self->{'data'},
	) = unpack('a'.$user_msg_length.'a'.$data_length, $payload);
}


=item raw()

Return binary data of packet body.

=cut

sub raw {
	my $self = shift;

	my $body = pack("nnC",
		length($self->{'user_msg'}),
		length($self->{'data'}),
		$self->{'continue_flags'},
	).$self->{'user_msg'}.$self->{'data'};

	return $body;
}

1;

=back

=cut
