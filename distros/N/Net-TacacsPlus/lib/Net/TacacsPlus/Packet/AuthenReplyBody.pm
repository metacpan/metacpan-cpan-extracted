package Net::TacacsPlus::Packet::AuthenReplyBody;

=head1 NAME

Net::TacacsPlus::Packet::AuthenReplyBody - Tacacs+ authentication replay body

=head1 DESCRIPTION

7.  The authentication REPLY packet body

The TACACS+ daemon sends only one type of  authentication  packet  (a
REPLY packet) to the client. The REPLY packet body looks as follows:

	 1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8
	
	+----------------+----------------+----------------+----------------+
	|     status     |      flags     |        server_msg len           |
	+----------------+----------------+----------------+----------------+
	|           data len              |        server_msg ...
	+----------------+----------------+----------------+----------------+
	|           data ...
	+----------------+----------------+

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
	flags
	server_msg
	data
});

=head1 METHODS

=over 4

=item new( somekey => somevalue)

Construct tacacs+ authentication packet body object

Parameters:

	'raw_body': raw body

=cut

sub new {
	my $class = shift;
	my %params = @_;

	#let the class accessor contruct the object
	my $self = $class->SUPER::new(\%params);

	if ($params{'raw_body'}) {
		$self->decode($params{'raw_body'});
		delete $self->{'raw_body'};
		return $self;
	}
	
	# set default values
	$self->server_msg('') if not defined $self->server_msg; 
	$self->data('')       if not defined $self->data; 

	return $self;
}

=item decode($raw_data)

Extract $server_msg and data from raw packet.

=cut

sub decode {
	my ($self, $raw_data) = @_;
	
	my ($server_msg_len,$data_len,$payload);
	
	(
		$self->{'status'},
		$self->{'flags'},
		$server_msg_len,
		$data_len,
		$payload,
	) = unpack("CCnna*", $raw_data);

	$payload = '' if not defined $payload; #payload can be empty

	(
		$self->{'server_msg'},
		$self->{'data'}
	) = unpack("a".$server_msg_len."a".$data_len,$payload);
}


=item raw()

Return binary data of packet body.

=cut

sub raw {
	my $self = shift;

	my $body = pack("CCnna*a*",
		$self->{'status'},
		$self->{'flags'},
		length($self->{'server_msg'}),
		length($self->{'data'}),
		$self->{'server_msg'},
		$self->{'data'},
	);

	return $body;
}

1;

=back

=cut

