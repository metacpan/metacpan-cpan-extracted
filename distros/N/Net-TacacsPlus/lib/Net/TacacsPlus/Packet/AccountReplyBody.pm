package Net::TacacsPlus::Packet::AccountReplyBody;

=head1 NAME

Net::TacacsPlus::Packet::AccountReplyBody - Tacacs+ accounting reply body

=head1 DESCRIPTION

The accounting REPLY packet body

   The response to an accounting message is used to  indicate  that  the
   accounting   function  on  the  daemon  has  completed  and  securely
   committed the record. This provides  the  client  the  best  possible
   guarantee that the data is indeed logged.



         1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8

        +----------------+----------------+----------------+----------------+
        |         server_msg len          |            data len             |
        +----------------+----------------+----------------+----------------+
        |     status     |         server_msg ...
        +----------------+----------------+----------------+----------------+
        |     data ...
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
	status
	server_msg
	data
});

=head1 METHODS

=over 4

=item new( somekey => somevalue)

Construct tacacs+ authorization response body object

Parameters:

	'raw_body' : raw body
	
	or
	
	status     : status of the reply
	server_msg : message from server
	data       : payload 

=cut

sub new()
{
	my $class = shift;
	my %params = @_;
	
	#let the class accessor contruct the object
	my $self = $class->SUPER::new(\%params);

	if ($params{'raw_body'}) {
		$self->decode($params{'raw_body'});
		delete $self->{'raw_body'};
		return $self;
	}

	return $self;
}

=item decode($raw_data)

Extract status, server_msg and data from raw packet.

=cut

sub decode {
	my ($self, $raw_data) = @_;
	
	my ($server_msg_len, $data_len, $payload);
	
	(
		$server_msg_len,
		$data_len,
		$self->{'status'},
		$payload,
	) = unpack("nnCa*", $raw_data);
	
	(
		$self->{'server_msg'},
		$self->{'data'}
	) = unpack("a".$server_msg_len."a".$data_len,$payload);
}

=item raw()

returns binary representation of Accounting Reply Body

=cut

sub raw {
	my $self = shift;
		
	return pack('nnCa*a*',
		length($self->{'server_msg'}),
		length($self->{'data'}),
		$self->{'status'},
		$self->{'server_msg'},
		$self->{'data'},
	);
}


=back

=cut

1;
