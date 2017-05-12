package Net::TacacsPlus::Packet::AccountRequestBody;

=head1 NAME

Net::TacacsPlus::Packet::AccountRequestBody - Tacacs+ accounting request body

=head1 DESCRIPTION

The account REQUEST packet body


         1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8

        +----------------+----------------+----------------+----------------+
        |      flags     |  authen_method |    priv_lvl    |  authen_type   |
        +----------------+----------------+----------------+----------------+
        | authen_service |    user len    |    port len    |  rem_addr len  |
        +----------------+----------------+----------------+----------------+
        |    arg_cnt     |   arg 1 len    |   arg 2 len    |      ...       |
        +----------------+----------------+----------------+----------------+
        |   arg N len    |    user ...
        +----------------+----------------+----------------+----------------+
        |   port ...
        +----------------+----------------+----------------+----------------+
        |   rem_addr ...
        +----------------+----------------+----------------+----------------+
        |   arg 1 ...
        +----------------+----------------+----------------+----------------+
        |   arg 2 ...
        +----------------+----------------+----------------+----------------+
        |   ...
        +----------------+----------------+----------------+----------------+
        |   arg N ...
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
	acct_flags
	authen_method
	priv_lvl
	authen_type
	service
	user
	port
	rem_addr
	args
});

=head1 METHODS

=over 4

=item new( somekey => somevalue)

Construct tacacs+ accounting REQUEST packet body object

Parameters:

	acct_flags    : TAC_PLUS_ACCT_FLAG_*   - default TAC_PLUS_ACCT_FLAG_STOP
	authen_method : TAC_PLUS_AUTHEN_METH_* - default TAC_PLUS_AUTHEN_METH_TACACSPLUS
	priv_lvl      : TAC_PLUS_PRIV_LVL_*    - default TAC_PLUS_PRIV_LVL_MIN
	authen_type   : TAC_PLUS_AUTHEN_TYPE_* - default TAC_PLUS_AUTHEN_TYPE_ASCII
	service       : TAC_PLUS_AUTHEN_SVC_*  - default TAC_PLUS_AUTHEN_SVC_LOGIN
	user          : username
	port          : port                   - default 'Virtual00'
	rem_addr      : our ip address         - default '127.0.0.1'
	args          : args arrayref

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

	$self->acct_flags(TAC_PLUS_ACCT_FLAG_STOP)            if not defined $self->acct_flags;
	$self->authen_method(TAC_PLUS_AUTHEN_METH_TACACSPLUS) if not defined $self->authen_method;
	$self->priv_lvl(TAC_PLUS_PRIV_LVL_MIN)                if not defined $self->priv_lvl;
	$self->authen_type(TAC_PLUS_AUTHEN_TYPE_ASCII)        if not defined $self->authen_type;
	$self->service(TAC_PLUS_AUTHEN_SVC_LOGIN)             if not defined $self->service;
	$self->port('Virtual00')                              if not defined $self->port;
	$self->rem_addr('127.0.0.1')                          if not defined $self->rem_addr;

	croak 'pass array reference as args' if not ref $self->args eq 'ARRAY';

	return $self;
}

=item decode($raw_body)

Construct body object from raw data.

=cut

sub decode {
	my ($self, $raw_body) = @_;
	
	my $user_length;
	my $port_length;
	my $rem_addr_length;
	my $args_count;
	my $payload;
	
	(
		$self->{'acct_flags'},
		$self->{'authen_method'},
		$self->{'priv_lvl'},
		$self->{'authen_type'},
		$self->{'service'},
		$user_length,
		$port_length,
		$rem_addr_length,
		$args_count,
		$payload,
	) = unpack("C9a*", $raw_body);

	#build array of unpack strings per argument - ('a10', 'a12', ...)
	my @args_unpack_strings =
		map { 'a'.$_ }
		unpack('C'.$args_count , $payload)
	;

	#remove counts from raw body
	$payload = substr($payload, $args_count);

	(
		$self->{'user'},
		$self->{'port'},
		$self->{'rem_addr'},
		$payload,
	) = unpack('a'.$user_length.'a'.$port_length.'a'.$rem_addr_length.'a*', $payload);

	#fill args property
	$self->args([
		unpack(
			join('', @args_unpack_strings),
			$payload
		) 
	]);

}


=item raw()

Return binary data of packet body.

=cut

sub raw {
	my $self = shift;

	my $body = pack("C9",
		$self->{'acct_flags'},
		$self->{'authen_method'},
		$self->{'priv_lvl'},
		$self->{'authen_type'},
		$self->{'service'},
		length($self->{'user'}),
		length($self->{'port'}),
		length($self->{'rem_addr'}),
		scalar(@{$self->{'args'}}),
	);

	#add args lengths
	$body .= pack('C*', map { length($_) } @{$self->{'args'}});
	
	$body .= $self->{'user'}
				.$self->{'port'}
				.$self->{'rem_addr'}
				.join('', @{$self->{'args'}});

	return $body;
}

1;

=back

=cut
