package Net::TacacsPlus::Packet::AuthorResponseBody;

=head1 NAME

Net::TacacsPlus::Packet::AuthorResponseBody - Tacacs+ authorization response body 

=head1 DESCRIPTION

The authorization RESPONSE packet body



         1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8  1 2 3 4 5 6 7 8

        +----------------+----------------+----------------+----------------+
        |    status      |     arg_cnt    |         server_msg len          |
        +----------------+----------------+----------------+----------------+
        +            data len             |    arg 1 len   |    arg 2 len   |
        +----------------+----------------+----------------+----------------+
        |      ...       |   arg N len    |         server_msg ...
        +----------------+----------------+----------------+----------------+
        |   data ...
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
	status
	server_msg
	data
	args
});

=head1 METHODS

=over 4

=item new( somekey => somevalue)

Construct tacacs+ authorization response body object

Parameters:

	'raw_body': raw body

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

	return $self;
}

=item decode($raw_data)

Extract status, server_msg, data and arguments from raw packet.

=cut

sub decode {
	my ($self, $raw_data) = @_;
	
	my ($server_msg_len,$arg_cnt,@arg_lengths,$data_len,$offset,@args);
	
	(
		$self->{'status'},
		$arg_cnt,
		$server_msg_len,
		$data_len,
	) = unpack("CCnn", $raw_data);
	$offset = 6;
	
	@arg_lengths = unpack("x$offset" . ("C" x $arg_cnt), $raw_data);
	$offset += $arg_cnt;

	($self->{'server_msg'}, $self->{'data'}) =
		unpack("x$offset"."a".$server_msg_len."a".$data_len, $raw_data);
	$offset += $server_msg_len + $data_len;

	foreach my $arglen (@arg_lengths)
	{
		push(@args, unpack("x$offset"."a$arglen", $raw_data));
		$offset += $arglen;
	}
		
	$self->{'args'} = \@args;
}


=item raw()

Return binary data of packet body.

=cut

sub raw {
	my $self = shift;

	my $args_count = scalar(@{$self->{'args'}});
	my $body = pack('CCnnC'.$args_count.'a*a*a*',
		$self->{'status'},
		$args_count,
		length($self->{'server_msg'}),
		length($self->{'data'}),
		(map { length($_) } @{$self->{'args'}}),
		$self->{'server_msg'},
		$self->{'data'},
		join('', @{$self->{'args'}}),
	);

	return $body;
}

=back

=cut

1;
